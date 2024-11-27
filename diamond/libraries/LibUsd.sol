// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

import { IAggregatorV3 } from "../interfaces/IAggregatorV3.sol";
import { ChainlinkOracle } from "../structs/ChainlinkOracle.sol";

library LibUsd {

	function ethToUsd(uint256 usdcEthPrice, uint256 amountEth) internal pure returns (uint256) {
		uint256 ethAmount = amountEth;
		return ((ethAmount * usdcEthPrice) / (10**(8+18)) / (10**18));
	}

	function usdToEth(uint256 usdcEthPrice, uint256 usdAmount) internal pure returns (uint256) {
		return ((10**18 * (10**8)) / usdcEthPrice) * usdAmount;
	}

	function getOraclePrice(ChainlinkOracle storage oracle) internal returns (uint256) {
		(
			uint256 price,
			uint64 timeStamp
		) = IAggregatorV3(oracle.priceFeed).latestRoundData();

		// check for Chainlink oracle deviancies, force a revert if any are present. Helps prevent a LUNA like issue
		require(timeStamp >= block.timestamp - oracle.heartBeat, "Stale pricefeed");

		return price;
	}

}
