// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

library LibUtils {

	function calculatePercentage(uint16 fee, uint256 amount) internal pure returns (uint256) {
		return amount * fee / 1000;
	}

}
