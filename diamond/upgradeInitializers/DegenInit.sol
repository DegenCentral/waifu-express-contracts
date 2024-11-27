// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

import { DiamondInit } from "./DiamondInit.sol";
import { LibDegen } from "../libraries/LibDegen.sol";

contract DegenInit is DiamondInit {
	function init() public override {
		super.init();

		LibDegen.Storage storage s = LibDegen.store();

		s.creationPrice = 1; // usd

		s.txFee = 10;
		s.launchFee = 20;

		s.tokenSupply = 1_000_000_000 ether;

		// FAKE POOL
		s.fakePoolMCapThreshold = 75_000; // usd
		s.fakePoolBaseEther = 1.56 ether;
	}
}
