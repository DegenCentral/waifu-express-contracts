// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { LibDegen } from "../../libraries/LibDegen.sol";
import { LibFakePools } from "../../libraries/LibFakePools.sol";
import { LibUtils } from "../../libraries/LibUtils.sol";
import { Diamondable } from "../../Diamondable.sol";
import { Token } from "../../../Token.sol";
import { UniV3Vault } from "../../../UniV3Vault.sol";
import { INonfungiblePositionManager } from "../../interfaces/INonfungiblePositionManager.sol";


contract Locker is Diamondable {
	address internal constant nfpm = 0xEE5FF5Bc5F852764b5584d92A4d592A53DC527da;
	
	function lock(address creator, address token, uint256 nfp) external onlyDiamond returns (address) {
		address vault = address(new UniV3Vault(0xB8E8553E7a7DD8aF4aE7349E93c5ED07c22d3cCf, creator, token, nfpm));
		INonfungiblePositionManager(nfpm).safeTransferFrom(address(this), vault, nfp);

		return vault;
	}

}