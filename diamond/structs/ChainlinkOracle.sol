// SPDX-License-Identifier: UNKNOWN
pragma solidity 0.8.18;

struct ChainlinkOracle {
	address priceFeed;
	uint256 heartBeat;
}