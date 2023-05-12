// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IFireSeed.sol";
import "./interface/IFireSoul.sol";
import "./interface/ISbt001.sol";

contract FDTConsensusMining is Ownable {
    address public USDT;
    address public FDT;
    uint256 public price = 1;
    uint256 public eachRound;

    address public FireSeedAddress;
    address public FireSoulAddress;
    address public FDSBT001Address;
    address public controlAddress;
    address public TreasuryDistributionContract;
    bool public Status;
    mapping(address => uint256) public award;
    
    constructor() {
    }
    //onlyOwner
    function setUSDTAddress(address _USDT) public  onlyOwner{
        USDT = _USDT;
    }
    function setFDTAddress(address _FDT) public onlyOwner{
        FDT = _FDT;
    }
    function setFireSeedAddress(address _FireSeedAddress) public  onlyOwner {
        FireSeedAddress = _FireSeedAddress;
    }
    function setFireSoulAddress(address _FireSoulAddress) public onlyOwner {
        FireSoulAddress = _FireSoulAddress;
    }
    function setFDSBT001Address(address _FDSBT001Address ) public onlyOwner{
        FDSBT001Address = _FDSBT001Address;
    }
    function setControlAddress(address _controlAddress) public onlyOwner{
        controlAddress = _controlAddress;
    }
    function setTreasuryDistributionContract(address _TreasuryDistributionContract) public onlyOwner{
        TreasuryDistributionContract = _TreasuryDistributionContract;
    }
    //main
    function setStatus() external {
        Status = !Status;
    }
    function ConsensusMining(uint256 amount) public {
        require(!Status ,"Contract Status is error");
        uint choose;
        uint256 amountRemaining;
        uint256 netxRounds;
        if(eachRound + amount > 500000*10**18){
         amountRemaining = 500000*10**18 - eachRound;
         netxRounds = amount - amountRemaining;
        IERC20(USDT).transfer(address(this), amountRemaining*price/100000);
        IERC20(USDT).transfer(address(this), netxRounds*(price+1)/100000);
        IERC20(FDT).transfer(msg.sender, amountRemaining);
        IERC20(FDT).transfer(msg.sender, netxRounds);
        eachRound = netxRounds;
        price++;
        choose = 1;
        }else if(eachRound + amount == 500000*10**18){
        IERC20(USDT).transfer(address(this), amount*price/100000);
        IERC20(FDT).transfer(msg.sender, amount);
        eachRound =0;
        price++;
        choose = 2;
        }else{
        IERC20(USDT).transfer(address(this), amount*price/100000);
        IERC20(FDT).transfer(msg.sender, amount);
        eachRound = eachRound + amount;
        choose = 2;
        }
        if( IFireSoul(FireSoulAddress).checkFID(msg.sender) && choose == 1 && IFireSeed(FireSeedAddress).upclass(msg.sender) != address(0) && IFireSeed(FireSeedAddress).upclass(IFireSeed(FireSeedAddress).upclass(msg.sender)) != address(0)){
        IERC20(USDT).transfer(msg.sender,(amountRemaining*price + netxRounds*(price+1))*35/100000000);
        IERC20(USDT).transfer(IFireSeed(FireSeedAddress).upclass(msg.sender), (amountRemaining*price + netxRounds*(price+1))/10000000);
        IERC20(USDT).transfer(IFireSeed(FireSeedAddress).upclass(IFireSeed(FireSeedAddress).upclass(msg.sender)), (amountRemaining*price + netxRounds*(price+1))*5/100000000);
        award[msg.sender] = (amountRemaining*price + netxRounds*(price+1))*35/100000000 + award[msg.sender];
        award[IFireSeed(FireSeedAddress).upclass(msg.sender)] =  (amountRemaining*price + netxRounds*(price+1))/10000000 +award[IFireSeed(FireSeedAddress).upclass(msg.sender)]  ;
        award[IFireSeed(FireSeedAddress).upclass(IFireSeed(FireSeedAddress).upclass(msg.sender))] =(amountRemaining*price + netxRounds*(price+1))*5/100000000 + award[IFireSeed(FireSeedAddress).upclass(IFireSeed(FireSeedAddress).upclass(msg.sender))];
        }else {
            IERC20(USDT).transfer(TreasuryDistributionContract, (amountRemaining*price/100000 +netxRounds*(price+1)/100000)*5/100 );
        }
        if(IFireSoul(FireSoulAddress).checkFID(msg.sender) &&  choose == 2 && IFireSeed(FireSeedAddress).upclass(msg.sender) != address(0) && IFireSeed(FireSeedAddress).upclass(IFireSeed(FireSeedAddress).upclass(msg.sender)) != address(0) ){
        IERC20(USDT).transfer(msg.sender,amount*price*35/100000000);
        IERC20(USDT).transfer(IFireSeed(FireSeedAddress).upclass(msg.sender), amount*price/10000000);
        IERC20(USDT).transfer(IFireSeed(FireSeedAddress).upclass(IFireSeed(FireSeedAddress).upclass(msg.sender)), amount*price*5/100000000);
        award[msg.sender] = (amount*price)*35/100000000 + award[msg.sender];
        award[IFireSeed(FireSeedAddress).upclass(msg.sender)] = (amount*price)/10000000 + award[IFireSeed(FireSeedAddress).upclass(msg.sender)];
        award[IFireSeed(FireSeedAddress).upclass(IFireSeed(FireSeedAddress).upclass(msg.sender))] =(amount*price)*5/100000000 + award[IFireSeed(FireSeedAddress).upclass(IFireSeed(FireSeedAddress).upclass(msg.sender))];
        }else{
            IERC20(USDT).transfer(TreasuryDistributionContract, amount*price*5/10000000);
        }
        ISbt001(FDSBT001Address).mint(msg.sender, amount);
    }
}