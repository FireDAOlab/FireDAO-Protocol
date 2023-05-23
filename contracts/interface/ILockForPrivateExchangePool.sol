//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILockForPrivateExchangePool {
	function withDraw(address _user, uint256 _amount) external;
}
