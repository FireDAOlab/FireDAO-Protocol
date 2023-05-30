// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TeamFundingAllocation is Initializable, UUPSUpgradeable, AccessControlEnumerableUpgradeable {
    IERC20 weth;
    bool public status;
    uint256 public billingCycle;
    address[] public secondary;
    mapping(address => bool) public reachQuota;
    mapping(address => uint256) public totalAmount;
    mapping(address => uint256) public allocationCycle;
    mapping(address => uint256) public maximumAmount;
    mapping(address => uint) public rate;
    function initialize() public initializer {
        __UUPSUpgradeable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
     function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}
      function Init(
        uint256 _billingCycle,
        address[] memory _secondary,
        uint256[] memory _allocationCycle,
        uint256[] memory _maximumAmount,
        uint[] memory _rate
        ) public onlyRole(DEFAULT_ADMIN_ROLE){
            billingCycle = _billingCycle;
            for(uint i = 0; i < _secondary.length;i++){
                secondary.push(_secondary[i]);
                allocationCycle[_secondary[i]] = _allocationCycle[i];
                maximumAmount[_secondary[i]] = _maximumAmount[i];
                rate[_secondary[i]] = _rate[i];
            }
        status = true;
    }
    function addAddr(address _addr, uint _rate, uint256 _allocationCycle,uint256 _maximumAmount) public onlyRole(DEFAULT_ADMIN_ROLE){
        secondary.push(_addr);
        rate[_addr] = _rate;
        allocationCycle[_addr] = _allocationCycle;
        maximumAmount[_addr] = _maximumAmount;
    }
    function removeAddr(address _addr) public onlyRole(DEFAULT_ADMIN_ROLE){
        uint id;
        for(uint i = 0 ; i < secondary.length; i++){
           if(secondary[i] == _addr){
               id = i;
           }  
        }
        secondary[id] = secondary[secondary.length -1];
        secondary.pop();

    }
    function setBillingCycle(uint256 _billingCycle) public onlyRole(DEFAULT_ADMIN_ROLE){
        billingCycle = _billingCycle;
        status = true;
    }
    function setAddr(uint _num,address _addr) public onlyRole(DEFAULT_ADMIN_ROLE) {
        secondary[_num] = _addr;
    }
    function setRate(address _addr, uint _rate) public onlyRole(DEFAULT_ADMIN_ROLE) {
        rate[_addr] = _rate;
    }
    function setAllocationCycle(address _addr, uint256 _allocationCycle) public onlyRole(DEFAULT_ADMIN_ROLE){
        allocationCycle[_addr] = _allocationCycle;
    }
    function setMaximumAmount(address _addr, uint256 _maximumAmount) public onlyRole(DEFAULT_ADMIN_ROLE){
        maximumAmount[_addr] = _maximumAmount;
    }
    function setReachQuota(address _addr, bool _reachQuota) public onlyRole(DEFAULT_ADMIN_ROLE){
        reachQuota[_addr] = _reachQuota;
    }
    function setWeth(IERC20 _addr) public onlyRole(DEFAULT_ADMIN_ROLE){
        weth = _addr;
    }
  
    function allocateFunds() public {
        require(getTotalRate() == 100, "Please adjust the allocation ratio");
        require(status,"Please initialize the contract");
        require(billingCycle > block.timestamp,"Unable to allocate beyond the billing cycle");
        uint256 amount = balance();
        for(uint i = 0; i<secondary.length;i++){
            if(
            totalAmount[secondary[i]] > maximumAmount[secondary[i]] &&
            !reachQuota[secondary[i]] ||
            allocationCycle[secondary[i]] < block.timestamp
              ){
            reachQuota[secondary[i]] = true;
            }else{
            weth.transfer(secondary[i],amount*rate[secondary[i]]/100);
            totalAmount[secondary[i]] += amount*rate[secondary[i]]/100;
            }
        }
        if(billingCycle < block.timestamp){
            status = false;
        }
    }
    function getSecondaryLength() public view returns(uint256){
        return secondary.length;
    }
    function getTotalRate() public view returns(uint){
        uint totalRate;
        for(uint i = 0; i<secondary.length;i++){
           totalRate += rate[secondary[i]];
        }
        return totalRate;
    }
    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE){
        weth.transfer(msg.sender, balance());
    }
    function balance() public view returns(uint256) {
        return weth.balanceOf(address(this));
    }
    function version() public pure returns (string memory) {
        return "1";
    }
}