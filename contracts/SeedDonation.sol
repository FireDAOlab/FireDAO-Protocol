// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
contract SeedDonation is Ownable,Pausable{
    using SafeMath for uint256;
    struct lockDetail{
        uint startBlock;
        uint amount;
    }
    AggregatorV3Interface internal priceFeed; //matic test 0x0715A7794a1dc8e42615F059dD6e406A6594651A
    IERC20 public FDT;
    uint public round = 1;
    uint public currentPrice = 10000;
    uint public currentRemaining = 5000000e18;
    uint public roundAmount = 5000000e18;
    uint public intervalBlock = 3; //arb 3 s
    mapping (address => lockDetail) public userLock;
    event Donation(address indexed _user,uint[] _amounts,uint[] _prices);
    event Claim(address indexed _user,uint _amount);
    constructor(IERC20 _FDT,address _priceFeed){
        FDT = _FDT;
        priceFeed = AggregatorV3Interface(
            _priceFeed
        );
    }
    function withdraw(address _to,uint _amount) external onlyOwner {
        FDT.transfer(_to,_amount);
    }
    function donation() payable external  whenNotPaused{
        _checkDonationAmount(msg.value);
        uint rewardAmount = msg.value.mul(getLastPrice().div(100)).div(currentPrice);
        uint[] memory prices = new uint[](2);
        uint[] memory amounts = new uint[](2);
        lockDetail storage detail =  userLock[msg.sender];
        if (currentRemaining < rewardAmount){
            uint firstETHAmount = currentRemaining.mul(currentPrice);
            uint rewardAmountNext = (msg.value.sub(firstETHAmount)).mul(getLastPrice().div(100)).div(currentPrice + 10000);
            uint allReward = currentRemaining.add(rewardAmountNext);
            round+=1;
            prices[0] = currentPrice;
            prices[1] = currentPrice + 10000;
            currentPrice+=10000;
            amounts[0] = currentRemaining;
            amounts[1] = rewardAmountNext;
            currentRemaining = roundAmount.sub(rewardAmountNext);
            FDT.transfer(msg.sender, allReward.mul(30).div(100));
       
           if(detail.amount != 0) {
               detail.amount = detail.amount.add(allReward.sub(allReward.mul(30).div(100)));
           }else{
               detail.amount = allReward.sub(allReward.mul(30).div(100));
               detail.startBlock = block.number;
           }
        } else {
            prices[0] = currentPrice;
            prices[1] = 0;
            amounts[0] = rewardAmount;
            amounts[1] = 0;
            currentRemaining = currentRemaining.sub(rewardAmount);
            FDT.transfer(msg.sender, rewardAmount.mul(30).div(100));
            if(detail.amount != 0) {
               detail.amount = detail.amount.add(rewardAmount.sub(rewardAmount.mul(30).div(100)));
            }else{
               detail.amount = detail.amount.add(rewardAmount.sub(rewardAmount.mul(30).div(100)));
               detail.startBlock = block.number;
           }
        }
         emit Donation(msg.sender, amounts, prices);
    }

    function claim() external whenNotPaused {
        uint amount = getClaimAmount();
        FDT.transfer(msg.sender, amount);
        userLock[msg.sender].amount = userLock[msg.sender].amount.sub(amount);
        emit Claim(msg.sender,amount);
    }
    function getClaimAmount() public view returns(uint) {
        uint blockReward = intervalBlock.mul(userLock[msg.sender].amount).div(31536000);
        return (block.number.sub(userLock[msg.sender].startBlock)).mul(blockReward);
    }
    
    //todo  delete
    function getRewardAmount(uint _amount) external view returns(uint){
        uint rewardAmount = _amount.mul(getLastPrice().div(100)).div(currentPrice);
          if (currentRemaining < rewardAmount){
            uint firstETHAmount = currentRemaining.mul(currentPrice);
            uint rewardAmountNext = (_amount.sub(firstETHAmount)).mul(getLastPrice().div(100)).div(currentPrice + 10000);
            uint allReward = currentRemaining.add(rewardAmountNext);
            return allReward;
          }else{
            return rewardAmount;
          }
    }
    function getLastPrice() public view returns(uint){
          (
            ,
            int price,
            ,
            ,
        ) = priceFeed.latestRoundData();
        return uint(price);
    }
    function _checkDonationAmount(uint _amount) internal pure{
        require(_amount>=1e17 && _amount <= 2e18,"The quantity does not meet the requirements");
        bool allow = false;
        for (uint i = 1e17;i<=2e18;i=i+1e17){
            if (_amount == i) {
                allow = true;
            }
        }
        require(allow,"The quantity can only be a multiple of 0.1");
    }
    receive() external payable {}
}
