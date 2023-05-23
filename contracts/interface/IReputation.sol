//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReputation{
  function checkReputation(address _user) external view returns(uint256); 

}