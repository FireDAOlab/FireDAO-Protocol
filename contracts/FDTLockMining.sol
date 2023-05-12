// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/ISbt001.sol";
import "./interface/ISbt006.sol";

contract FDTLockMining is Ownable {
    struct LPStakeInfo {
        address user;
        uint256 startStakeTime;
        uint256 endStakeTime;
        uint256 stakeAmount;
        bool isFristStake;
        uint256 coefficient;
    }
    struct StakeInfo {
        address user;
        uint256 startStakeTime;
        uint256 endStakeTime;
        uint256 stakeAmount;
        bool isFristStake;
        uint256 coefficient;
    }
    uint256 public Id;
    address public FDTAddress;
    address public flame;
    address public FDSBT001Address;
    address public FDSBT006Address;
    bool public Status;
    address public controlAddress;
    address public LPTokenAddress;
    mapping(address => mapping(uint256 => uint256)) userStakeInfo;
    mapping(address => StakeInfo[]) public StakeInfos;
    mapping(address => LPStakeInfo[]) public LPStakeInfos;
    mapping(address => mapping(uint256 => uint256)) public UserWithdraw; 
    mapping(address => uint256) public FDSBT001Amount;
    mapping(address => uint256) public LPGrandTotal;
    mapping(address => uint256) public GrandTotal;
    uint256 public BounsTime;
    uint256 public FlameAmount;
    StakeInfo[] public _StakeInfos;
    LPStakeInfo[] public _LPStakeInfos;

    address[] public StakeUser;
    constructor () {

    }
    function setControlAddress(address _controlAddress) public onlyOwner{
        controlAddress = _controlAddress;
    }
    function setLPTokenAddress(address _LPTokenAddress) public onlyOwner{
        LPTokenAddress = _LPTokenAddress;
    }
    function setStatus() external {
        require(msg.sender == controlAddress ,"you are not controlAddress");
        Status = !Status;
    }
    function setFDSBT001Address(address _FDSBT001Address) public onlyOwner{
        FDSBT001Address = _FDSBT001Address;
    }
    function setBonusTime(uint256 _BounsTime) public onlyOwner {
        BounsTime = _BounsTime;
        FlameAmount = IERC20(flame).balanceOf(address(this));
    }
    function withdraw(uint256 amount) public onlyOwner {
        IERC20(flame).transfer(msg.sender,amount);
    }

    function setFDTAddress(address _FDTAddress) public onlyOwner {
        FDTAddress = _FDTAddress;
    }

    function stakeMining(uint256 amount, uint256 inputEndTime ) public {
        require(!Status,"Status is error");
        require(inputEndTime == 0 || inputEndTime == 1 || inputEndTime == 3 || inputEndTime == 6 || inputEndTime == 12 || inputEndTime == 24 || inputEndTime == 36 , "input type error");
        IERC20(FDTAddress).transfer(address(this), amount);
        userStakeInfo[msg.sender][block.timestamp] = amount;
        StakeInfo memory info = StakeInfo({
            user:msg.sender,
            startStakeTime:block.timestamp,
            endStakeTime:block.timestamp + inputEndTime*2592000,
            stakeAmount:amount,
            isFristStake:true,
            coefficient:inputEndTime
        });
        ISbt001(FDSBT001Address).mint(msg.sender, amount*inputEndTime);
        StakeInfos[msg.sender].push(info);
        FDSBT001Amount[msg.sender] = amount*inputEndTime + FDSBT001Amount[msg.sender];
        StakeUser.push(msg.sender);
        _StakeInfos.push(info);

        if(StakeInfos[msg.sender][0].isFristStake){
        ReceiveAward();
        }
        Id++;
    }
    function LockLP(uint256 amount , uint256 inputTime) public {
        require(!Status,"Status is error");
        IERC20(LPTokenAddress).transfer(address(this), amount);
        ISbt006(FDSBT006Address).mint(msg.sender,amount* inputTime);
        LPStakeInfo memory LPinfo = LPStakeInfo({
            user:msg.sender,
            startStakeTime:block.timestamp,
            endStakeTime:block.timestamp + inputTime*2592000,
            stakeAmount:amount,
            isFristStake:true,
            coefficient:inputTime
        });
        _LPStakeInfos.push(LPinfo);
        LPStakeInfos[msg.sender].push(LPinfo);
        }
    function withdrawLP(uint256 order ) public {
        require(LPStakeInfos[msg.sender][order].stakeAmount > 0 , "you haven't amount");
        IERC20(LPTokenAddress).transfer(msg.sender, LPStakeInfos[msg.sender][order].stakeAmount );
        ISbt006(FDSBT006Address).burn(msg.sender , LPStakeInfos[msg.sender][order].coefficient*LPStakeInfos[msg.sender][order].stakeAmount);
    }
    
    function ReceiveAward() internal {
        for(uint i = 0 ;i< _StakeInfos.length ; i++){
        // IERC20(flame).transfer(_StakeInfos[i].user,_StakeInfos[i].stakeAmount/(IERC20(FDTAddress).balanceOf(address(this)))*(FlameAmount/BounsTime));
        GrandTotal[_StakeInfos[i].user] = _StakeInfos[i].stakeAmount/(IERC20(FDTAddress).balanceOf(address(this)))*(FlameAmount/BounsTime) + GrandTotal[_StakeInfos[i].user];
        }
    }
    function ReceiveAwardOfLockLP() internal{
        for(uint i = 0 ; i< _LPStakeInfos.length; i++){
        // IERC20(flame).transfer(_LPStakeInfos[i].user,IERC20(FDSBT006Address).balanceOf(_LPStakeInfos[i].user)/IERC20(FDSBT006Address).totalSupply());
        LPGrandTotal[_LPStakeInfos[i].user] = (IERC20(FDSBT006Address).balanceOf(_LPStakeInfos[i].user)/IERC20(FDSBT006Address).totalSupply())*(FlameAmount/BounsTime) + LPGrandTotal[_LPStakeInfos[i].user];
        }
    }

    function UserWithdrawFDT(uint256 order)public {
        require(!Status,"Status is error");
        require(StakeInfos[msg.sender][order].stakeAmount > 0 ,"you havent amount");
        for(uint i = 0 ; i < StakeInfos[msg.sender].length ; i++) {
            if(StakeInfos[msg.sender][i].user == msg.sender) {
                if(block.timestamp > StakeInfos[msg.sender][i].endStakeTime){
                    IERC20(flame).transfer(msg.sender, StakeInfos[msg.sender][i].stakeAmount);
                    ISbt001(FDSBT001Address).burn(msg.sender,StakeInfos[msg.sender][i].stakeAmount* StakeInfos[msg.sender][i].coefficient);
                }
            }
        }
    }
}
