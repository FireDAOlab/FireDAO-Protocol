// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interface/ISbt001.sol";
import "./interface/IFireSeed.sol";
import "./interface/IWETH.sol";
contract SeedDonation is Ownable,Pausable{
    using SafeMath for uint256;
    struct lockDetail{
        uint startBlock;
        uint amount;
    }
    uint constant ONE_YEAR =  31536000;
    AggregatorV3Interface internal priceFeed; //matic test 0x0715A7794a1dc8e42615F059dD6e406A6594651A
    IERC20 public FDT;
    ISbt001 public SBT001;
    IFireSeed public FireSeed;
    IERC721 public FirePassport;
    IERC721 public FireSoul;
    IWETH public WETH;
    address public FDTLiquity;
    address public Treasury;
    uint public round = 1;
    uint public currentPrice = 1e16;
    uint public currentRemaining = 5000000e18; //5000000e18
    uint public roundAmount = 5000000e18; //5000000e18
    uint public intervalBlock = 3; //arb 3 s
    uint public PIDDiscount = 96;
    uint public FIDDiscount = 92;
    uint public FDTLiquityRatio = 30;
    uint public TreasuryRatio = 60;
    uint public ReferenceRatio = 10;
    mapping (address => lockDetail) public userLock;
    event Donation(address indexed _user,uint _spend,uint[] _amounts,uint[] _prices);
    event Claim(address indexed _user,uint _amount);
    constructor(IERC20 _FDT,ISbt001 _SBT001,IERC721 _firePassport,IERC721 _fireSoul,address _priceFeed,address _FDTLiquity,address _treasury,IFireSeed _fireSeed,IWETH _weth){
        FDT = _FDT;
        SBT001 = _SBT001;
        priceFeed = AggregatorV3Interface(
            _priceFeed
        );
        FirePassport = _firePassport;
        FireSoul = _fireSoul;
        FDTLiquity = _FDTLiquity;
        Treasury = _treasury;
        FireSeed = _fireSeed;
        WETH = _weth;
    }
    function withdraw(address _to,uint _amount) external onlyOwner {
        FDT.transfer(_to,_amount);
    }
    function changeFIDDiscount(uint _discount) external onlyOwner {
        FIDDiscount = _discount;
    }
      function changePIDDiscount(uint _discount) external onlyOwner {
        PIDDiscount = _discount;
    }
    function changeFDTLiquity(address _liquity) external onlyOwner {
        FDTLiquity = _liquity;
    }
    function changeFDTRatio(uint _ratio) external onlyOwner {
        FDTLiquityRatio = _ratio;
    }
    function changeTreasury(address _treasury) external onlyOwner {
        Treasury = _treasury;
    }
     function changeTreasuryRatio(uint _ratio) external onlyOwner {
        TreasuryRatio = _ratio;
    }
    function changeReferenceRatio(uint _ratio) external onlyOwner {
        ReferenceRatio = _ratio;
    }
    
    function donation() payable external  whenNotPaused{
        require(round<=100,"Seed donation has ended");
        _checkDonationAmount(msg.value);
        bool hasFID = FireSoul.balanceOf(msg.sender) > 0 ? true : false;
        bool hasPID = FirePassport.balanceOf(msg.sender) > 0 ? true : false;
        uint buyPrice;
        if (hasFID) {
            buyPrice = currentPrice.mul(FIDDiscount).div(100);
        }else if(hasPID) {
            buyPrice = currentPrice.mul(PIDDiscount).div(100);
        }else{
            buyPrice = currentPrice;
        }
        uint rewardAmount = msg.value.mul(getLastPrice()).div(buyPrice);
        uint[] memory prices = new uint[](2);
        uint[] memory amounts = new uint[](2);
        lockDetail storage detail =  userLock[msg.sender];
         uint firstETHAmount = currentRemaining.mul(buyPrice).div(getLastPrice());
        if (firstETHAmount < msg.value){
            uint rewardAmountNext = (msg.value.sub(firstETHAmount)).mul(getLastPrice()).div(buyPrice + 1e16);
            uint allReward = currentRemaining.add(rewardAmountNext);
            round+=1;
            prices[0] = buyPrice;
            prices[1] = buyPrice + 1e16;
            currentPrice+=1e16;
            amounts[0] = currentRemaining;
            amounts[1] = rewardAmountNext;
            currentRemaining = roundAmount.sub(rewardAmountNext);
            FDT.transfer(msg.sender, allReward.mul(30).div(100));
            uint lockAmount = allReward.sub(allReward.mul(30).div(100));
           if(detail.amount != 0) {
               detail.amount = detail.amount.add(lockAmount);
           }else{
               detail.amount = lockAmount;
               detail.startBlock = block.number;
           }
           if (hasFID){
               SBT001.mint(msg.sender,lockAmount);
           }
        } else {
            prices[0] = buyPrice;
            prices[1] = 0;
            amounts[0] = rewardAmount;
            amounts[1] = 0;
            currentRemaining = currentRemaining.sub(rewardAmount);
            FDT.transfer(msg.sender, rewardAmount.mul(30).div(100));
            uint lockAmount = rewardAmount.sub(rewardAmount.mul(30).div(100));
            if(detail.amount != 0) {
               detail.amount = detail.amount.add(lockAmount);
            }else{
               detail.amount = lockAmount;
               detail.startBlock = block.number;
           }
           if (hasFID){
              SBT001.mint(msg.sender,lockAmount);
           }
        }
        WETH.deposit{value: msg.value}();
        address topReference = FireSeed.upclass(msg.sender);
        uint referenceReward = msg.value.mul(ReferenceRatio).div(100);
        uint FDTLiquityReward = msg.value.mul(FDTLiquityRatio).div(100);
        uint TreasuryReward = msg.value.mul(TreasuryRatio).div(100);
        if(topReference!=address(0)){
              WETH.transfer(topReference,referenceReward.mul(70).div(100));
              address middleReference = FireSeed.upclass(topReference);
              if (middleReference!=address(0)){
                 WETH.transfer(topReference,referenceReward.mul(20).div(100));
                 address bottomReference = FireSeed.upclass(middleReference);
                 if (bottomReference != address(0)) {
                    WETH.transfer(bottomReference,referenceReward.mul(10).div(100));
                 }else{
                    WETH.transfer(Treasury,referenceReward.mul(10).div(100));
                 }
              }else{
                WETH.transfer(Treasury,referenceReward.mul(30).div(100));
              }
        }else{
          WETH.transfer(Treasury,referenceReward);
        }
        WETH.transfer(FDTLiquity,FDTLiquityReward);
        WETH.transfer(Treasury,TreasuryReward);
        emit Donation(msg.sender, msg.value, amounts, prices);
    }

    function claim() external {
        uint amount = getClaimAmount();
        require(userLock[msg.sender].amount<=amount,"Not enough quantity");
        require(FDT.balanceOf(address(this)) >= amount,"Insufficient quantity in the pool");
        FDT.transfer(msg.sender, amount);
        userLock[msg.sender].amount = userLock[msg.sender].amount.sub(amount);
        SBT001.burn(msg.sender,amount);
        emit Claim(msg.sender,amount);
    }
    function getClaimAmount() public view returns(uint) {
        uint blockReward = userLock[msg.sender].amount.div(ONE_YEAR.div(intervalBlock));
        // uint blockReward = intervalBlock.mul(userLock[msg.sender].amount).div(ONE_YEAR);
        return (block.number.sub(userLock[msg.sender].startBlock)).mul(blockReward);
    }
    
    //todo  
    function getRewardAmount(uint _amount) external view returns(uint){
        bool hasFID = FireSoul.balanceOf(msg.sender) > 0 ? true : false;
        bool hasPID = FirePassport.balanceOf(msg.sender) > 0 ? true : false;
        uint buyPrice;
        if (hasFID) {
            buyPrice = currentPrice.mul(FIDDiscount).div(100);
        }else if(hasPID) {
            buyPrice = currentPrice.mul(PIDDiscount).div(100);
        }else{
            buyPrice = currentPrice;
        }
        uint firstETHAmount = currentRemaining.mul(buyPrice).div(getLastPrice());
        if(firstETHAmount < _amount){
            uint rewardAmountNext = (_amount.sub(firstETHAmount)).mul(getLastPrice()).div(buyPrice + 1e16);
            uint allReward = currentRemaining.add(rewardAmountNext);
            return allReward;
        }else{
            return _amount.mul(getLastPrice()).div(buyPrice);    
        }
    }

    function getLastPrice() public view returns(uint){
          (
            ,
            int price,
            ,
            ,
        ) = priceFeed.latestRoundData();
        return uint(price).mul(10000000000);
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
