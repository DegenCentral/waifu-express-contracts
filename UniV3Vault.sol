// SPDX-License-Identifier: UNKNOWN
pragma solidity 0.8.18;

import { INonfungiblePositionManager } from "./diamond/interfaces/INonfungiblePositionManager.sol";
import { Token } from "./Token.sol";

interface IERC721Receiver {
	function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

contract UniV3Vault is IERC721Receiver {

	INonfungiblePositionManager public nfpm;
	address public protocol;
	address public creator;
	uint256 public nfp;

	Token internal weth;
	Token internal token;

	constructor(address _protocol, address _creator, address _token, address _nfpm) {
		protocol = _protocol;
		creator = _creator;
		token = Token(_token);
		nfpm = INonfungiblePositionManager(_nfpm);
		weth = Token(nfpm.WETH9());
	}

	event FeesCollected(address receiver, uint256 amountWeth, uint256 amountToken);
	function collectFees() external {
		nfpm.collect(
			INonfungiblePositionManager.CollectParams({
				tokenId: nfp,
				recipient: address(this),
				amount0Max: type(uint128).max,
				amount1Max: type(uint128).max
			})
		);

		uint256 amountWethSplit = weth.balanceOf(address(this)) / 2;
		uint256 amountTokenSplit = token.balanceOf(address(this)) / 2;

		weth.transfer(creator, amountWethSplit);
		weth.transfer(protocol, amountWethSplit);
		token.transfer(creator, amountTokenSplit);
		token.transfer(protocol, amountTokenSplit);

		emit FeesCollected(creator, amountWethSplit, amountTokenSplit);
		emit FeesCollected(protocol, amountWethSplit, amountTokenSplit);
	}

	function onERC721Received(
		address operator,
		address from,
		uint256 id,
		bytes calldata data
	) external override returns (bytes4) {
		require(nfp == 0, "Vault: LOCKED");

		nfp = id;

		return IERC721Receiver.onERC721Received.selector;
	}
	
}