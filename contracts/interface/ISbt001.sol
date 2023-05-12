//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISbt001{
	function mint(address Account, uint256 Amount) external;
	function burn(address Account, uint256 Amount) external;
}