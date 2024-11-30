// SPDX-License-Identifier: UNKNOWN
pragma solidity 0.8.18;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {

	address internal diamond;
	bool internal launched = false;

	constructor(string memory name, string memory symbol, uint256 supply, address _diamond) ERC20(name, symbol) {
		diamond = _diamond;
		_mint(msg.sender, supply);
	}

	function launch() external {
		require(msg.sender == diamond && launched == false);
		launched = true;
	}

	function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
		if (!launched) {
			require(from == diamond || to == diamond, "transfer not allowed before launch");
		}
	}

}