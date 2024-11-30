// SPDX-License-Identifier: UNKNOWN
pragma solidity 0.8.18;

import { LibDegen } from "../../libraries/LibDegen.sol";
import { ChainlinkOracle } from "../../structs/ChainlinkOracle.sol";
import { Ownable } from "../../Ownable.sol";


contract DegenAdmin is Ownable {

	// VIEWS

	function proceeds() external view returns (uint256) {
		return LibDegen.store().proceeds;
	}

	function state() external pure returns (LibDegen.Storage memory) {
		return LibDegen.store();
	}

	// FUNCTIONS

	function reap() external onlyOwner {
		uint256 eth = LibDegen.store().proceeds;
		LibDegen.store().proceeds = 0;
		(bool sent,) = payable(msg.sender).call{ value: eth }("");
		require(sent);
	}

	// SETTERS

	function setCreationPrice(uint32 price) external onlyOwner {
		LibDegen.store().creationPrice = price;
	}

	function setTxFee(uint16 fee) external onlyOwner {
		LibDegen.store().txFee = fee;
	}

	function setLaunchFee(uint16 fee) external onlyOwner {
		LibDegen.store().launchFee = fee;
	}

	function setUsdcOracle(ChainlinkOracle calldata oracle) external onlyOwner {
		LibDegen.store().usdOracle = oracle;
	}

	// FAKE POOL SETTERS

	function setFakePoolMCapThreshold(uint32 threshold) external onlyOwner {
		LibDegen.store().fakePoolMCapThreshold = threshold;
	}

	function setFakePoolBaseEther(uint256 baseEther) external onlyOwner {
		LibDegen.store().fakePoolBaseEther = baseEther;
	}
}
