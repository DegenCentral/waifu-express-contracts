// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibDiamond } from "./libraries/LibDiamond.sol";

contract Diamondable {
	error Unauthorized(address account);

	modifier onlyDiamond() {
		LibDiamond.enforceDiamondItself();
		_;
	}

	function diamond() internal view returns (address diamond_) {
		diamond_ = LibDiamond.diamondStorage().diamondAddress;
	}
}
