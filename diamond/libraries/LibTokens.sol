// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

library LibTokens {
	bytes32 constant STORAGE_POSITION = keccak256("diamond.tokens.storage");

	struct Storage {
		mapping(address => address) creatorMap;
	}

	function store() internal pure returns (Storage storage s) {
		bytes32 position = STORAGE_POSITION;
		assembly {
			s.slot := position
		}
	}
}
