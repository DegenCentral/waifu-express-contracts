// SPDX-License-Identifier: UNKNOWN
pragma solidity 0.8.18;

library LibFakePools {
	bytes32 constant STORAGE_POSITION = keccak256("diamond.fakepools.storage");

	struct FakePool {
		uint256 fakeEth;
		uint256 ethReserve;
		uint256 tokenReserve;
		
		address token;
		address pair;

		uint16 sellPenalty;
		bool locked;
	}

	struct Storage {
		mapping(address => FakePool) poolMap;
	}

	function store() internal pure returns (Storage storage s) {
		bytes32 position = STORAGE_POSITION;
		assembly {
			s.slot := position
		}
	}
}
