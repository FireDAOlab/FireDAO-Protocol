// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IUniswapV2Router02.sol";
import "./interface/IReputation.sol";
contract FidPromotionCompetition is Ownable{
    struct userInfo{
        address user;
        uint256 initFund;
        uint256 time;
        bool    isNotList;
    }
    IUniswapV2Router02 public uniswapV2Router;
    address public sbt;
    address public newWeek;
    address public newMoon;
    address public newYear;
    address public cityNode;
    address public cityNodeAddress;
    address public SBT003Address;
    address public Reputation;
    mapping(address => userInfo) public addressToInfo;
    mapping(address => uint256) public exchangeFund;
    bool public Status;
    address public pauseControlAddress;
    mapping(string => address) public CompetitionAddress;
    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Router = _uniswapV2Router;
    }
    //onlyOwner
    function initial(string memory _week,string memory _moon,string memory _year) public onlyOwner{
        address Week =address( new weekPool());
        address Moon =address( new moonPool());
        address Year =address( new yearPool());

        newWeek = Week;
        newMoon = Moon;
        newYear = Year;

        CompetitionAddress[_week]  = newWeek;
        CompetitionAddress[_moon]  = newMoon;
        CompetitionAddress[_year]  = newYear;
    }
    function injectionFunds() public onlyOwner{
        IERC20(uniswapV2Router.WETH()).transfer(newWeek , IERC20(uniswapV2Router.WETH()).balanceOf(address(this))/100*50);
        IERC20(uniswapV2Router.WETH()).transfer(newMoon , IERC20(uniswapV2Router.WETH()).balanceOf(address(this))/100*30);
        IERC20(uniswapV2Router.WETH()).transfer(newYear , IERC20(uniswapV2Router.WETH()).balanceOf(address(this))/100*20);
    }
    function setSBT003Address(address _SBT003Address) public onlyOwner{
        SBT003Address =_SBT003Address;
    }
    function setSBTAddress(address _sbt) public onlyOwner{
        sbt = _sbt;
    }
    function setPoolStatus() public onlyOwner {
       weekPool(newWeek).setStatus();
       moonPool(newMoon).setStatus();
       yearPool(newYear).setStatus();
    }
    function setCityNodeAddress(address _cityNode) public onlyOwner{
        cityNode =_cityNode;
    }
    function setPauseControlAddress(address _pauseControlAddress) public onlyOwner{
        pauseControlAddress =_pauseControlAddress;
    }
    //main
    function setContractsStatus() external {
        require(msg.sender == pauseControlAddress,"address is error");
        Status = !Status;
    }
    
    function distribute() external {
        require(!Status, "status is error");
        require(IReputation(Reputation).checkReputation(msg.sender) > 100000*10*18 ,"Reputation Points is not enough");
        weekPool(newWeek).AllocateFunds();
        moonPool(newMoon).AllocateFunds();
        yearPool(newYear).AllocateFunds();
    }
    function updateWeekList() public {
        userInfo memory info = userInfo({
            user:msg.sender,
            initFund:IERC20(SBT003Address).balanceOf(msg.sender),
            time: block.timestamp,
            isNotList:false
        });
        addressToInfo[msg.sender] = info;
    }

    function fundExchange() public {
        require(block.timestamp > addressToInfo[msg.sender].time + 604800, "the week time is error");
        exchangeFund[msg.sender] =IERC20(SBT003Address).balanceOf(address(this)) - addressToInfo[msg.sender].initFund;

        addressToInfo[msg.sender].isNotList = true;
    }
}

contract weekPool{
    bool public status;
    IUniswapV2Router02 public uniswapV2Router;
    constructor(){
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Router = _uniswapV2Router;
    }
    function setStatus() external {
        status = !status;
    } 
    function AllocateFunds() external  {
        require(!status ,"status is false");
        IERC20(uniswapV2Router.WETH()).transfer(msg.sender,10**17);
    }
}

contract moonPool{
    bool public status;
    IUniswapV2Router02 public uniswapV2Router;
    constructor(){
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Router = _uniswapV2Router;
    }
      function setStatus() external {
        status = !status;
    } 
        function AllocateFunds() external  {
        require(!status ,"status is false");
        IERC20(uniswapV2Router.WETH()).transfer(msg.sender,10**17);
    }
}
contract yearPool{
    bool public status;
    IUniswapV2Router02 public uniswapV2Router;
    constructor(){
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Router = _uniswapV2Router; 
    }
    function setStatus() external {
        status = !status;
    }
    
    function AllocateFunds() external  {
        require(!status ,"status is false");
        IERC20(uniswapV2Router.WETH()).transfer(msg.sender,10**17);
    }
}