// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { LibDegen } from "../../libraries/LibDegen.sol";
import { LibFakePools } from "../../libraries/LibFakePools.sol";
import { LibUtils } from "../../libraries/LibUtils.sol";
import { Diamondable } from "../../Diamondable.sol";
import { IwETH} from "../../interfaces/IwETH.sol";
import { Token } from "../../../Token.sol";
import { INonfungiblePositionManager } from "../../interfaces/INonfungiblePositionManager.sol";

import "@openzeppelin/contracts/utils/math/Math.sol";

interface IUniswapV3Pool {
	function initialize(uint160 sqrtPriceX96) external;

	function swap(
		address recipient,
		bool zeroForOne,
		int256 amountSpecified,
		uint160 sqrtPriceLimitX96,
		bytes calldata data
	) external returns (int256 amount0, int256 amount1);
}

interface IUniswapV3Factory {
	function getPool(address tokenA, address tokenB, uint24 fee) external view returns (IUniswapV3Pool pool);
	function createPool(address tokenA, address tokenB, uint24 fee) external returns (IUniswapV3Pool pool);
}

contract Launcher is Diamondable {

	IUniswapV3Factory internal constant factory = IUniswapV3Factory(0x8A2578d23d4C532cC9A98FaD91C0523f5efDE652);
	address internal constant nfpManager = 0xEE5FF5Bc5F852764b5584d92A4d592A53DC527da;
	uint24 internal constant fee = 3000;
	int24 internal constant spacing = 60;

	IUniswapV3Pool internal pool;

	function launch(
		address token,
		uint256 amountToken,
		uint256 amountWeth
	) external onlyDiamond payable returns (address, uint256) {
		address weth = INonfungiblePositionManager(nfpManager).WETH9();
		(address token0, address token1) = weth < token
			? (weth, token)
			: (token, weth);
		(uint256 amount0, uint256 amount1) = weth < token
			? (amountWeth, amountToken)
			: (amountToken, amountWeth);

		uint160 sqrtPrice = calculateSqrtPriceX96(amount0, amount1);

		pool = factory.getPool(token0, token1, fee);
		if (address(pool) == address(0)) {
			pool = factory.createPool(token0, token1, fee);
			pool.initialize(sqrtPrice);
		}

		// wrap
		IwETH(weth).deposit{value: amountWeth}();
		// Approve token transfers to the position manager
		Token(token0).approve(nfpManager, amount0);
		Token(token1).approve(nfpManager, amount1);

		// Mint the position (add liquidity)
		INonfungiblePositionManager.MintParams
			memory params = INonfungiblePositionManager.MintParams({
				token0: token0,
				token1: token1,
				fee: fee,
				tickLower: (-887272 / spacing) * spacing,
				tickUpper: (887272 / spacing) * spacing,
				amount0Desired: amount0,
				amount1Desired: amount1,
				amount0Min: 0,
				amount1Min: 0,
				recipient: msg.sender,
				deadline: block.timestamp
			});

		(uint256 nfp, , , ) = INonfungiblePositionManager(nfpManager).mint(
			params
		);

		pool.swap(
			msg.sender,
			token0 == weth,
			int256(msg.value - amountWeth),
			token0 == weth ? 4295128740 : 1461446703485210103287273052203988822378723970341,
			""
		);

		return (address(pool), nfp);
	}

	function uniswapV3SwapCallback(
		int256 amount0Delta,
		int256 amount1Delta,
		bytes calldata data
	) public {
		require(msg.sender == address(pool), "LAUNCHER: FORBIDDEN");

		uint256 amount = uint256(amount0Delta > 0 ? amount0Delta : amount1Delta);

		address weth = INonfungiblePositionManager(nfpManager).WETH9();
		IwETH(weth).deposit{value: amount}();
		Token(weth).transfer(address(pool), amount);
	}

	uint256 internal constant Q96 = 0x1000000000000000000000000;

	function calculateSqrtPriceX96(uint256 amount0, uint256 amount1) internal pure returns (uint160) {
		return uint160(Math.mulDiv(Math.sqrt(amount1), Q96, Math.sqrt(amount0)));
	}

}