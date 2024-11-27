// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

import { LibDegen } from "../../libraries/LibDegen.sol";
import { LibUtils } from "../../libraries/LibUtils.sol";
import { LibUsd } from "../../libraries/LibUsd.sol";
import { LibFakePools } from "../../libraries/LibFakePools.sol";
import { LibTokens } from "../../libraries/LibTokens.sol";
import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { LibClone } from "solady/src/utils/LibClone.sol";
import { Ownable } from "../../Ownable.sol";
import { Token } from "../../../Token.sol";
import { FakePools } from "./FakePools.sol";
import { Launcher } from "./Launcher.sol";
import { Locker } from "./Locker.sol";

enum TokenType {
	FakePool
}

contract DegenTokens is Ownable {
	event TokenCreated(address creator, address token, TokenType t, uint256 supply, string name, string symbol, string imageCid, string description, string[] links, uint256 price);
	event TokenLaunched(address creator, address token, address pair, address vault);

	function create(TokenType t, string calldata name, string calldata symbol, string calldata imageCid, string calldata description, string[] calldata links, bytes calldata data, uint256 initialBuy) external payable {
		require(
			bytes(name).length <= 18 &&
			bytes(symbol).length <= 18 &&
			bytes(description).length <= 512, 
			"Invalid params"
		);

		require(links.length < 5, "4 links max");
		for (uint8 i = 0; i < links.length; i++) {
			require(bytes(links[i]).length <= 128, "link too long");
		}

		LibDegen.Storage storage d = LibDegen.store();
		uint256 supply = d.tokenSupply;

		Token token = new Token(name, symbol, supply, address(this));
		address tokenAddress = address(token);

		uint256 price;
		if (t == TokenType.FakePool) {
			price = FakePools(address(this))._create_FakePool(tokenAddress, supply, data);
		} else {
			revert("invalid token type");
		}

		LibTokens.Storage storage ts = LibTokens.store();

		ts.creatorMap[tokenAddress] = msg.sender;
		 
		emit TokenCreated(msg.sender, tokenAddress, t, d.tokenSupply, name, symbol, imageCid, description, links, price);

		uint256 eth = msg.value;

		uint256 usdEthPrice = LibUsd.getOraclePrice(d.usdOracle);
		uint256 creationEth = LibUsd.usdToEth(usdEthPrice, d.creationPrice);
		require(eth >= creationEth, "Usd price changed");

		eth -= creationEth;
		LibDegen.gatherProceeds(creationEth);

		if (initialBuy > 0) {
			eth -= initialBuy;

			(uint256 tokensOut, uint256 newPrice) = (0, 0);
			if (t == TokenType.FakePool) {
				(tokensOut, newPrice) = FakePools(address(this))._buy_FakePool{ value: initialBuy }(tokenAddress); 
			}
			
			Token(token).transfer(msg.sender, tokensOut); // Transfer tokens to buyer
			emit Bought(msg.sender, tokenAddress, initialBuy, tokensOut, newPrice);
		}

		if (eth > 0) {
			(bool sent,) = msg.sender.call{ value: eth }(""); // refund dust
			require(sent);
		}
	}

	function quote(address token, TokenType t, uint256 amount, bool ethOut) public view returns(uint256) {
		if (t == TokenType.FakePool) {
			return FakePools(address(this))._quote_FakePool(token, amount, ethOut);
		} else {
			revert("invalid token type");
		}
	}

	event Bought(address buyer, address token, uint256 ethIn, uint256 tokensOut, uint256 newPrice);
	event Sold(address seller, address token, uint256 ethOut, uint256 tokensIn, uint256 newPrice);
	event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to); // UNIV2 event for tracking

	function buy(address token, TokenType t, uint256 min) external payable {
		(uint256 tokensOut, uint256 newPrice) = (0, 0);

		if (t == TokenType.FakePool) {
			(tokensOut, newPrice) = FakePools(address(this))._buy_FakePool{ value: msg.value }(token);
		} else {
			revert("invalid token type");
		}

		if (min != 0) require(tokensOut >= min, "amount out lower than min");

		Token(token).transfer(msg.sender, tokensOut); // Transfer tokens to buyer
		emit Bought(msg.sender, token, msg.value, tokensOut, newPrice);
		emit Swap(address(this), msg.value, 0, 0, tokensOut, msg.sender);
	}

	function sell(address token, TokenType t, uint256 amount, uint256 min) external {
		(uint256 ethOut, uint256 newPrice) = (0, 0);

		if (t == TokenType.FakePool) {
			(ethOut, newPrice) = FakePools(address(this))._sell_FakePool(token, amount);
		} else {
			revert("invalid token type");
		}

		if (min != 0) require(ethOut >= min, "amount out lower than min");

		Token(token).transferFrom(msg.sender, address(this), amount); // Transfer tokens from seller
		(bool sent,) = msg.sender.call{ value: ethOut }(""); require(sent); // Transfer eth to seller
		emit Sold(msg.sender, token, ethOut, amount, newPrice);
		emit Swap(msg.sender, 0, amount, ethOut, 0, address(this));
	}

	function launch(address token, TokenType t) external onlyOwner payable {
		(uint256 eth, uint256 tokens) = (0, 0);

		if (t == TokenType.FakePool) {
			(eth, tokens) = FakePools(address(this))._launchstats_FakePool(token);
		} else {
			revert("invalid token type");
		}

		LibDegen.Storage storage degen = LibDegen.store();

		address creator = LibTokens.store().creatorMap[token];

		uint256 launchFee = LibUtils.calculatePercentage(degen.launchFee, eth);
		LibDegen.gatherProceeds(launchFee);
		eth -= launchFee;

		Token(token).launch();

		(address pair, uint256 nfp) = Launcher(address(this)).launch{ value: eth + msg.value }(token, tokens, eth);
		address vault = Locker(address(this)).lock(creator, token, nfp);

		LibFakePools.FakePool storage pool = LibFakePools.store().poolMap[token];
		pool.locked = true;
		pool.pair = pair;

		emit TokenLaunched(creator, token, pair, vault);
	}

}
