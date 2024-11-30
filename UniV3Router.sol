// SPDX-License-Identifier: UNKNOWN
pragma solidity 0.8.18;

import { IRouter } from "./diamond/interfaces/IRouter.sol";
import { IwETH } from "./diamond/interfaces/IwETH.sol";

import { Token } from "./Token.sol";

interface IUniV3Router {
	function WETH9() external view returns (address);

	struct ExactInputSingleParams {
		address tokenIn;
		address tokenOut;
		uint24 fee;
		address recipient;
		uint256 deadline;
		uint256 amountIn;
		uint256 amountOutMinimum;
		uint160 sqrtPriceLimitX96;
	}

  function exactInputSingle(ExactInputSingleParams calldata params) external returns (uint256 amountOut);
}

interface IUniV3Quoter {
	struct QuoteExactInputSingleParams {
		address tokenIn;
		address tokenOut;
		uint256 amountIn;
		uint24 fee;
		uint160 sqrtPriceLimitX96;
	}

	function quoteExactInputSingle(QuoteExactInputSingleParams memory params)
		external
		returns (
			uint256 amountOut,
			uint160 sqrtPriceX96After,
			uint32 initializedTicksCrossed,
			uint256 gasEstimate
		);

	
}

contract UniV3Router is IRouter {
	IUniV3Router private router;
	IUniV3Quoter private quoter;
	uint24 private fee;

	constructor(address _router, address _quoter, uint24 _fee) {
		router = IUniV3Router(_router);
		quoter = IUniV3Quoter(_quoter);
		fee = _fee;
	}

	function WETH() external view override returns (address) {
		return router.WETH9();
	}

	function quote(address input, address output, uint256 amountIn) external override returns (uint256) {
		(uint256 amountOut,,,) = quoter.quoteExactInputSingle(IUniV3Quoter.QuoteExactInputSingleParams({
			fee: fee,
			tokenIn: input,
			tokenOut: output,
			amountIn: amountIn,
			sqrtPriceLimitX96: 0
		}));
		return amountOut;
	}

	function swapEthForTokens(address token, uint256 amountOutMin) external payable override {
		address wETH = router.WETH9();

		IwETH(wETH).deposit{ value: msg.value }();
		Token(wETH).approve(address(router), msg.value);

		router.exactInputSingle(IUniV3Router.ExactInputSingleParams({
			fee: fee,
			tokenIn: wETH,
			tokenOut: token,
			recipient: msg.sender,
			deadline: block.timestamp + 2 minutes,
			amountIn: msg.value,
			amountOutMinimum: amountOutMin,
			sqrtPriceLimitX96: 0
		}));
	}

	function swapTokensForEth(address token, uint256 amountIn, uint256 amountOutMin) external override {
		Token(token).transferFrom(msg.sender, address(this), amountIn);
		Token(token).approve(address(router), amountIn);

		router.exactInputSingle(IUniV3Router.ExactInputSingleParams({
			fee: fee,
			tokenIn: token,
			tokenOut: router.WETH9(),
			recipient: msg.sender,
			deadline: block.timestamp + 2 minutes, 
			amountIn: amountIn,
			amountOutMinimum: amountOutMin,
			sqrtPriceLimitX96: 0
		}));
	}
}