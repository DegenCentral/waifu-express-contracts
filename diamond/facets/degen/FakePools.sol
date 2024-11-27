// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { LibDegen } from "../../libraries/LibDegen.sol";
import { LibFakePools } from "../../libraries/LibFakePools.sol";
import { LibUtils } from "../../libraries/LibUtils.sol";
import { LibUsd } from "../../libraries/LibUsd.sol";
import { Diamondable } from "../../Diamondable.sol";
import { Token } from "../../../Token.sol";


contract FakePools is Diamondable {
	event FakePoolCreated(address token, uint16 sellPenalty, uint256 ethReserve, uint256 tokenReserve);
	event FakePoolReserveChanged(address token, uint256 ethReserve, uint256 tokenReserve);
	event FakePoolMCapReached(address token);

	function swapExactTokensForETH(LibFakePools.FakePool storage pool, uint256 tokens) internal returns (uint256) {
		uint256 out = getAmountOut(tokens, pool.tokenReserve, pool.ethReserve);
		pool.tokenReserve += tokens;
		pool.ethReserve -= out;
		emit FakePoolReserveChanged(pool.token, pool.ethReserve, pool.tokenReserve);
		return out;
	}

	function swapExactETHForTokens(LibFakePools.FakePool storage pool, uint256 eth) internal returns (uint256) {
		uint256 out = getAmountOut(eth, pool.ethReserve, pool.tokenReserve);
		pool.tokenReserve -= out;
		pool.ethReserve += eth;
		emit FakePoolReserveChanged(pool.token, pool.ethReserve, pool.tokenReserve);
		return out;
	}

	function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256) {
		uint256 numerator = amountIn * reserveOut;
		uint256 denominator = reserveIn + amountIn;
		return numerator / denominator;
	}

	function price(LibFakePools.FakePool storage pool, uint256 amount, bool ethOut) internal view returns (uint256) {
		if (ethOut) {
			return (amount * pool.ethReserve) / pool.tokenReserve;
		} else {
			return (amount * pool.tokenReserve) / pool.ethReserve;
		}
	}

	function checkMarketCapThreshold(LibFakePools.FakePool storage pool) internal {
		LibDegen.Storage storage d = LibDegen.store();

	 	uint256 p = price(pool, 1 ether, true);
		uint256 ethMcap = d.tokenSupply * p;

		uint256 usdEthPrice = LibUsd.getOraclePrice(d.usdOracle);
		uint256 amountUsd = LibUsd.ethToUsd(usdEthPrice, ethMcap);

		if (amountUsd >= d.fakePoolMCapThreshold) {
			pool.locked = true;
			emit FakePoolMCapReached(pool.token);
		}
	}

	function calculateSellPenalty(LibFakePools.FakePool storage pool, uint256 eth) internal view returns (uint256) {
		if (pool.sellPenalty == 0) return 0;
		return LibUtils.calculatePercentage(pool.sellPenalty, eth);
	}

	function deductSellPenalty(LibFakePools.FakePool storage pool, uint256 eth) internal returns (uint256) {
		uint256 fee = calculateSellPenalty(pool, eth);
		if (fee == 0) {
			return eth;
		} else {
			pool.ethReserve += fee; // redistribute the penaltyFee back into the ether reserve
			return eth - fee;
		}
	}


	// PUBLIC

	function _quote_FakePool(address token, uint256 amount, bool ethOut) external view returns (uint256) {
		LibFakePools.FakePool storage pool = LibFakePools.store().poolMap[token];
		if (ethOut) { // sell
			uint256 eth = getAmountOut(amount, pool.tokenReserve, pool.ethReserve);
			eth -= LibDegen.calculateTxFee(eth);
			eth -= calculateSellPenalty(pool, eth);
			return eth;
		} else { // buy
			uint256 txFee = LibDegen.calculateTxFee(amount);
			return getAmountOut(amount - txFee, pool.ethReserve, pool.tokenReserve);
		}
	}

	function _create_FakePool(address tokenAddress, uint256 supply, bytes calldata data) external onlyDiamond returns (uint256) {
		LibDegen.Storage storage d = LibDegen.store();
		LibFakePools.Storage storage t =	LibFakePools.store();

		(uint16 sellPenalty) = abi.decode(data, (uint16));

		require(sellPenalty <= 700);

		LibFakePools.FakePool storage pool = t.poolMap[tokenAddress];
		pool.token = tokenAddress;
		pool.fakeEth = d.fakePoolBaseEther;
		pool.ethReserve = d.fakePoolBaseEther;
		pool.tokenReserve = supply;
		pool.sellPenalty = sellPenalty;

		emit FakePoolCreated(tokenAddress, sellPenalty, pool.ethReserve, pool.tokenReserve);

		return price(pool, 1 ether, true);
	}

	function _launchstats_FakePool(address token) external view returns (uint256, uint256) {
		LibFakePools.FakePool storage pool = LibFakePools.store().poolMap[token];
		require(pool.token != address(0));
		return (pool.ethReserve - pool.fakeEth, pool.tokenReserve);
	}

	function _buy_FakePool(address token) external onlyDiamond payable returns (uint256, uint256) {
		LibFakePools.FakePool storage pool = LibFakePools.store().poolMap[token];
		require(pool.token != address(0) && !pool.locked);

		uint256 ethIn = LibDegen.deductTxFee(msg.value);
		uint256 tokensOut = swapExactETHForTokens(pool, ethIn);

		checkMarketCapThreshold(pool);

		return (tokensOut, price(pool, 1 ether, true));
	}

	function _sell_FakePool(address token, uint256 amount) external onlyDiamond returns (uint256, uint256) {
		LibFakePools.FakePool storage pool = LibFakePools.store().poolMap[token];
		require(pool.token != address(0) && !pool.locked);

		uint256 ethOut = swapExactTokensForETH(pool, amount);
		ethOut = LibDegen.deductTxFee(ethOut);
		ethOut = deductSellPenalty(pool, ethOut);

		require(pool.ethReserve >= pool.fakeEth, "no eth left in pool");
		checkMarketCapThreshold(pool);

		return (ethOut, price(pool, 1 ether, true));
	}

}
