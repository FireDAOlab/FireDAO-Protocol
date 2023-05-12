// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FdtFlameLock is Ownable{
    address public FdtAddress;
    address public falmeAddress;
    uint256 public TotallockTime = 662256000 ;
    mapping(address => uint256) public FDTtransferTime;
    mapping(address => uint256) public FDTlocked;
    mapping(address => uint256) public FDTUserAmount;
    mapping(address => uint256) public FLAMEtransferTime;
    mapping(address => uint256) public FLAMElocked;
    mapping(address => uint256) public FLAMEUserAmount;
    constructor() {
    }
    function setTokenAddress(address _FdtAddress, address _falmeAddress) public onlyOwner {
        FdtAddress = _FdtAddress;
        falmeAddress = _falmeAddress;
    }
    function withdraw(address tokenAddress ,uint256 amount) public onlyOwner {
        if(tokenAddress == FdtAddress){
            IERC20(tokenAddress).transfer(msg.sender,amount);
        }else if(tokenAddress == falmeAddress){
            IERC20(tokenAddress).transfer(msg.sender,amount);
        }
    }

    function Fdtlocked(uint256 amount) public {
        require(IERC20(FdtAddress).balanceOf(msg.sender) != 0, "You not have balance");
        require(IERC20(FdtAddress).balanceOf(msg.sender) <= amount , "you not have enough balance");
        IERC20(FdtAddress).transfer(address(this), amount);
        FDTtransferTime[msg.sender] = block.timestamp;
        FDTlocked[msg.sender] = TotallockTime;
        FDTUserAmount[msg.sender] = amount;
    }
    function FlameLocked(uint256 amount) public {
        require(IERC20(falmeAddress).balanceOf(msg.sender) != 0,"you have not balance");
        require(IERC20(falmeAddress).balanceOf(msg.sender) <= amount, "you not have enough balance");
        IERC20(falmeAddress).transfer(address(this), amount);
        FLAMEtransferTime[msg.sender] = block.timestamp;
        FLAMElocked[msg.sender] = TotallockTime;
        FLAMEUserAmount[msg.sender] = amount;

    }
    function claim(address tokenAddress , uint256 amount) public {
        require(FDTUserAmount[msg.sender] > amount || FLAMEUserAmount[msg.sender] > amount, "you amount error");
        require(block.timestamp > FLAMElocked[msg.sender] || block.timestamp > FDTlocked[msg.sender],"you lock time not end");
        if(tokenAddress == FdtAddress && FDTUserAmount[msg.sender] * (block.timestamp - FDTtransferTime[msg.sender])/TotallockTime > amount){
        IERC20(tokenAddress).transfer(msg.sender, amount);
        }else if(tokenAddress == falmeAddress &&  FLAMEUserAmount[msg.sender] * (block.timestamp - FLAMEtransferTime[msg.sender])/TotallockTime > amount){
        IERC20(tokenAddress).transfer(msg.sender, amount);
        }
    }
}