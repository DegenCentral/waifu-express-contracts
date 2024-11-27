// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.0;

interface IAggregatorV3 {
  function latestRoundData()
    external
    returns (uint256 price, uint64 timestamp);
}