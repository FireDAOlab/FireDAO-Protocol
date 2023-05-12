// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interface/ISbt001.sol";
import "./interface/ISbt002.sol";

contract FlameFdtExchange is Ownable{
    address public Flame;
    ERC20 fdt;
    uint256 public lockEnd = 63158400;
    bool public contractStatus;
    address public control;
    address public sbt001;
    address public sbt002;
    mapping(address => uint256) public userAmount;
    mapping(address => uint256) public lockStart;
    constructor() {
    }
    function setFlameAndFdtAddress(address _Flame, ERC20 _Fdt) public onlyOwner {
        Flame = _Flame;
        fdt = _Fdt;
    }
    function setControlAddress(address _controlAddress) public onlyOwner{
        control = _controlAddress;
    }
    function setSBT001Address(address _sbt001) public onlyOwner{
        sbt001 = _sbt001;
    }
    function setSBT002Address(address _sbt002) public onlyOwner{
        sbt002 = _sbt002;
    }
    function setStatus() external  {
        require(msg.sender == control, "address is error");
        contractStatus = !contractStatus;
    }
    
    function ExchangeAndLock(uint256 amount) public {
        require(!contractStatus , "status is error");
        require(amount > 10000 *10**18, "amount is not enough");
        ISbt001(sbt001).mint(msg.sender, amount);
        ISbt002(sbt002).mint(msg.sender, amount/10);
        userAmount[msg.sender] = amount;
        lockStart[msg.sender] = block.timestamp;
    }
    function withdraw() public {
        require(!contractStatus , "status is error");
        require(block.timestamp > lockStart[msg.sender]);
        fdt.transfer(msg.sender, userAmount[msg.sender] * (block.timestamp - lockStart[msg.sender])/lockEnd);
        ISbt001(sbt001).burn(msg.sender,userAmount[msg.sender] * (block.timestamp - lockStart[msg.sender])/lockEnd);
    }
    function AvailableQuota() public view returns(uint256){
        return userAmount[msg.sender] * (block.timestamp - lockStart[msg.sender])/lockEnd;
    }

}