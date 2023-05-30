//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interface/IPrivateExchangePool.sol";

contract LockForPrivateExchangePool is Ownable {
	ERC20 fdt;
	address public exchangePool;
	constructor (address _exchangePool) {exchangePool = _exchangePool;}
	function setFdt(ERC20 _fdt) public onlyOwner {
		fdt = _fdt;
	}
	function setExchangePool(address _exchangePool) public onlyOwner {
		exchangePool = _exchangePool;
	}
	function withDraw(address _user, uint256 _amount) external {
		require(msg.sender == exchangePool, "error");
		require(IPrivateExchangePool(exchangePool).getUserBuyLength(_user) >= 0, "you haven't lock amount");
		fdt.transfer(msg.sender, _amount);
	}

}
