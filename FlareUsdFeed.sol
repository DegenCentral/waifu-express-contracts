// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

import { IAggregatorV3 } from "./diamond/interfaces/IAggregatorV3.sol";

import {ContractRegistry} from "@flarenetwork/flare-periphery-contracts/coston2/ContractRegistry.sol";
import {FtsoV2Interface} from "@flarenetwork/flare-periphery-contracts/coston2/FtsoV2Interface.sol";

contract FlareUsdFeed is IAggregatorV3 {
	FtsoV2Interface internal ftsoV2;

	constructor() {}

	function latestRoundData()
		external
		override
		returns (uint256 price, uint64 timestamp)
	{
		(uint256 _feedValue, , uint64 _timestamp) = ContractRegistry.getFtsoV2().getFeedById(
			0x01464c522f55534400000000000000000000000000 // usd
		);
		// convert from 7 to 8 decimals
		return (_feedValue * 10, _timestamp);
	}
}