// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./FireLock.sol";

contract FireLockFactory is Ownable{

    address private currentLock;
    address[] public lockList;
    address public weth;
    address public fireLockFeeAddress;
    address public treasuryDistributionContract;
    mapping(address => address )  currentLockAddress;
    mapping(address => address[]) public ownerLock; 
    mapping(address => bool) public lockVerify;
    mapping(address => bool) public uninitialized;
    event totalLockList(address lockOwner, address lockAddr);
    event allLockItem(
        address lockAddr,
        string  title,
        uint256 lockAmount, 
        uint256 lockTime, 
        uint256 cliffPeriod, 
        uint256 unlockCycle,
        uint256 unlockRound,
        uint256 ddl,
        address admin
    );
    event claimInfo(address lock, uint256 amount);
    event changeAdmin(address lock, address admin);
    constructor(address _weth,address _fireLockFeeAddress,address _treasuryDistributionContract){
    weth = _weth;
    fireLockFeeAddress = _fireLockFeeAddress;
    treasuryDistributionContract = _treasuryDistributionContract;
    }
 
    function createLock() public {
        currentLock = address(new FireLock(weth,fireLockFeeAddress,treasuryDistributionContract, address(this),msg.sender));
        ownerLock[msg.sender].push(currentLock);
        currentLockAddress[msg.sender] = currentLock;
        lockList.push(currentLock);
        lockVerify[currentLock] = true;
        emit totalLockList(msg.sender, currentLock);
    }
    function setfireLockFeeAddress(address _addr) public onlyOwner{
        fireLockFeeAddress = _addr;
    }
    function addLockItem(
        address _lockAddr,
        string memory _title,
        uint256 _lockAmount, 
        uint256 _lockTime, 
        uint256 _cliffPeriod, 
        uint256 _unlockCycle,
        uint256 _unlockRound,
        uint256 _ddl,
        address _admin
        ) external   {
        require(lockVerify[msg.sender], "address is error");

        emit allLockItem(
        _lockAddr,
        _title,
        _lockAmount, 
        _lockTime, 
        _cliffPeriod, 
        _unlockCycle,
        _unlockRound,
        _ddl,    
        _admin
        );
    }
    function addClaimInfo(address _lock, uint256 _amount) external {
        require(lockVerify[msg.sender], "address is error");

        emit claimInfo(_lock, _amount);
    }
    function addlockAdmin(address _lock, address _admin) external  {
        require(lockVerify[msg.sender], "address is error");

        emit changeAdmin(_lock, _admin);
    }
    function isNotUninitialized(address _lock,bool _uninitalized) external{
        require(lockVerify[msg.sender], "address is error");
        uninitialized[_lock] = _uninitalized;
    }
    function getUserCurrentLock() public view returns(address) {
        return currentLockAddress[msg.sender];
    }

    function getOwnerLockLenglength() public view returns(uint256){
        return ownerLock[msg.sender].length;
    }

    function getLockList() public view returns(uint256){
        return lockList.length;
    }

}