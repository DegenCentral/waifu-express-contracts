// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

interface IRouter {
	function WETH() external view returns (address);

	function quote(address input, address output, uint256 amount) external returns (uint256);

  function swapEthForTokens(address token, uint256 amountOutMin) external payable;
	function swapTokensForEth(address token, uint256 amountIn, uint256 amountOutMin) external;
}