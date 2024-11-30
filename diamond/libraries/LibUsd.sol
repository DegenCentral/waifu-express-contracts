// SPDX-License-Identifier: UNKNOWN
pragma solidity 0.8.18;

import { IAggregatorV3 } from "../interfaces/IAggregatorV3.sol";
import { ChainlinkOracle } from "../structs/ChainlinkOracle.sol";

library LibUsd {

	function ethToUsd(uint256 usdEthPrice, uint256 ethAmount) internal pure returns (uint256) {
		return (ethAmount * usdEthPrice) / (10 ** 18);
	}

	function usdToEth(uint256 usdEthPrice, uint256 usdAmount) internal pure returns (uint256) {
		return (usdAmount * (10 ** 18)) / usdEthPrice;
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
