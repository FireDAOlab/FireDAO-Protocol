// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interface/IUniswapV2Router02.sol";
import "./interface/IReputation.sol";


contract TreasuryDistributionContract is Initializable,UUPSUpgradeable,AccessControlEnumerableUpgradeable {
    uint256 public intervalTime;
    address[] public AllocationFundAddress;
    uint private rate;
    uint private userTime;
    bool public pause;
    address public controlAddress;
    address public Reputation;
    uint256 public ReputationAmount;
    address public GovernanceAddress;
    address public owner;
    address public weth;
    mapping(address => uint) public distributionRatio;
    mapping(address => uint256) public AllocationFundUserTime;
    mapping(uint =>mapping(uint => uint256[])) public sourceOfIncome;
    mapping(uint => address) public tokenList;
    mapping(address => bool) public allowAddr;
    constructor() initializer {
    }
    function initialize() public initializer {
        __UUPSUpgradeable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        userTime = 43200;
        owner = msg.sender;
    }
     function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    //onlyOwner
    function setAllowAddr(address _addr, bool _status) public onlyRole(DEFAULT_ADMIN_ROLE){
        allowAddr[_addr] = _status;
    }
    function setWeth(address _weth) public onlyRole(DEFAULT_ADMIN_ROLE){
        weth = _weth;
    }
    function setUerIntverTime(uint256 _time) public onlyRole(DEFAULT_ADMIN_ROLE){
        userTime = _time;
    }
    function setTotalDistributionRatio(address _addr, uint _rate) public onlyRole(DEFAULT_ADMIN_ROLE){
        distributionRatio[_addr] = _rate;
    }
    function removeAddr(address _addr) public onlyRole(DEFAULT_ADMIN_ROLE){
        uint _num;
        for(uint i = 0; i<AllocationFundAddress.length;i++){
            if(AllocationFundAddress[i] == _addr){
                _num = i;
            }
        }
        AllocationFundAddress[_num] = AllocationFundAddress[AllocationFundAddress.length - 1];
        AllocationFundAddress.pop();
    }
    function setTokenList(uint tokenNum, address tokenAddr)public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(tokenNum < 10,"input error");
        tokenList[tokenNum] = tokenAddr;
    }
    function setReputation(address _Reputation) public onlyRole(DEFAULT_ADMIN_ROLE) {
        Reputation = _Reputation;
    }
    
    function setControlAddress(address _controlAddress) public onlyRole(DEFAULT_ADMIN_ROLE){
        controlAddress = _controlAddress;
    }
    
    function setGovernanceAddress(address _GovernanceAddress) public onlyRole(DEFAULT_ADMIN_ROLE){
        GovernanceAddress = _GovernanceAddress;
    }
    
    function addAllocationFundAddress(address[] memory assigned) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for(uint i = 0 ; i < assigned.length ; i++){
            AllocationFundAddress.push(assigned[i]);
        }
    }
    function setAddr(uint256 _id,address _addr) public onlyRole(DEFAULT_ADMIN_ROLE){
        AllocationFundAddress[_id] = _addr;
    }
    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(weth).transfer(msg.sender, getWETHBalance());
    }
    //getSource
    function setSourceOfIncome(uint num,uint tokenNum,uint256 amount) external {
        require(allowAddr[msg.sender],"no access");
        sourceOfIncome[num][tokenNum].push(amount);
    }
    function getSourceOfIncomeLength(uint num,uint tokenNum) public view returns(uint256){
        return sourceOfIncome[num][tokenNum].length;
    }
    function getSourceOfIncome(uint num , uint tokenNum) public view returns(uint256[] memory){
        return sourceOfIncome[num][tokenNum];
    }
    function getWETHBalance() public view returns(uint256){
        return IERC20(weth).balanceOf(address(this));
    }
    //main
    function setStatus() external {
        require(msg.sender == controlAddress || msg.sender == owner,"the callback address is error");
        pause = !pause;
    }
    function setReputationAmount(uint256 _amount) public onlyRole(DEFAULT_ADMIN_ROLE){
        ReputationAmount = _amount; 
    }
    
    function AllocationFund(uint _tokenNum) public {
        require(!pause, "contract is pause");
        require(checkRate() == 100,'rate error');
        require(IReputation(Reputation).checkReputation(msg.sender) > ReputationAmount*10*18 || msg.sender == owner ,"Reputation Points is not enough");
        require( block.timestamp > intervalTime + 3600,"AllocationFund need interval 30 minute");
        require( block.timestamp >  AllocationFundUserTime[msg.sender] + userTime ,"wallet need 12 hours to callback that");
        require(getWETHBalance() > 0, "the balance of WETH is error");
        uint256 totalBalance = getTokenBalance(_tokenNum);
        for(uint i = 0 ; i < AllocationFundAddress.length; i ++){
        ERC20(tokenList[_tokenNum]).transfer(AllocationFundAddress[i], totalBalance*rate*distributionRatio[AllocationFundAddress[i]]/10000);
    }
        intervalTime = block.timestamp;
        AllocationFundUserTime[msg.sender] = block.timestamp;
        IERC20(weth).transfer(msg.sender, 5 * 10**16);
    }
    function checkRate() public view returns(uint256){
        uint256 num;
        for(uint i = 0; i < AllocationFundAddress.length;i++){
            num += distributionRatio[AllocationFundAddress[i]];
        }
        return num;
    }
    function getTokenBalance(uint num) public view returns(uint256) {
        return IERC20(tokenList[num]).balanceOf(address(this));
    }
    function version() public pure returns (string memory) {
        return "1";
    }

}