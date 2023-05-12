//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITreasuryDistributionContract {
  function AllocationFund() external;
  function setSourceOfIncome(uint num,address user,uint256 amount) external;
}