//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFireSoul {
	function checkFID(address user) external view returns(bool);
    function getSoulAccount(address _user) external view returns(address);
    function checkFIDA(address _user) external view returns(uint256);
}