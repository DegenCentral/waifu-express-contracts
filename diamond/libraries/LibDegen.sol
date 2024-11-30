// SPDX-License-Identifier: UNKNOWN
pragma solidity 0.8.18;

import { LibUtils } from "./LibUtils.sol";
import { LibDiamond } from "./LibDiamond.sol";
import { ChainlinkOracle } from "../structs/ChainlinkOracle.sol";

library LibDegen {
	bytes32 constant STORAGE_POSITION = keccak256("diamond.degen.storage");

	struct Storage {
		uint256 proceeds;

		uint256 creationPrice;

		uint16 txFee;
		uint16 launchFee;

		uint256 tokenSupply;

		ChainlinkOracle usdOracle;

		uint256 fakePoolBaseEther;
		uint256 fakePoolMCapThreshold;
	}

	function store() internal pure returns (Storage storage s) {
		bytes32 position = STORAGE_POSITION;
		assembly {
			s.slot := position
		}
	}

	function gatherProceeds(uint256 amount) internal {
		LibDegen.store().proceeds += amount;
	}

	function calculateTxFee(uint256 eth) internal view returns (uint256) {
		return LibUtils.calculatePercentage(store().txFee, eth);
	}

	function deductTxFee(uint256 eth) internal returns (uint256) {
		uint256 fee = calculateTxFee(eth);
		gatherProceeds(fee);
		return eth - fee;
	}
}
