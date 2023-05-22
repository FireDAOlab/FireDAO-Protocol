// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface ICityNode{
  function getIsCityNode(address _account , uint256 _fee) external payable;
  function cityNodeIncome(address _user, uint256 _income) external;
  function isNotCityNodeUsers(address _user) external view returns(bool);
  function isNotCityNodeLight(address _user) external view returns(bool);
}