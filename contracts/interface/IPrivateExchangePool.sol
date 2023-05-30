//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPrivateExchangePool {
	function getUserBuyLength(address _user) external view returns(uint256);
	function getUserLockEndTime(address _user, uint256 lockId) external view returns(uint256);
}