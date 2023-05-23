
//File:./interface/IFireLockFactory.sol

pragma solidity ^0.8.0;
interface IFireLockFactory {
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
        ) external;
     function addClaimInfo(address _lock, uint256 _amount) external;
     function addlockAdmin(address _lock, address _admin) external;
     function isNotUninitialized(address _lock,bool _uninitalized) external;

}
//File:./interface/ITreasuryDistributionContract.sol
pragma solidity ^0.8.0;

interface ITreasuryDistributionContract {
  function AllocationFund() external;
  function setSourceOfIncome(uint num,uint tokenNum,uint256 amount) external;
}
//File:./interface/IFireLockFeeTransfer.sol
pragma solidity ^0.8.0;
interface IFireLockFeeTransfer {
    function getAddress() external view returns(address);
    function getFee() external view returns(uint256);
    function getUseTreasuryDistributionContract() external view returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interface/IWETH.sol";
import "./lib/TransferHelper.sol";

contract FireLock {
     using SafeMath for uint256;
     using Address for address;
     using SafeERC20 for IERC20;

    struct LockDetail{
        string LockTitle;
        uint256 ddl;
        uint256 startTime;
        address admin;
        uint256 amount;
        uint256 unlockCycle;
        uint256 unlockRound;
        uint256[] rate;
        address token;
        address[] member;
        uint256 cliffPeriod;
    }
    struct unLockRecord{
        address user;
        uint256 amount;
        uint256 time;
    }
    uint256 constant ONE_DAY_TIME_STAMP = 86400;

    bool private locked;
    bool public lockStatus;
    bool public unlockStatus;
    address public weth;
    address public factoryAddr;
    address public treasuryDistributionContract;
    address public fireLockFeeTransfer;
    address public adminForLock;
    address public createUser;
    uint256 public totalAmount;
    uint256 public totalRate;
    LockDetail public adminLockDetail;
    unLockRecord[] public record;
    mapping(address => uint256) public claimed;
    mapping(address => uint256) private userTime;
    mapping(address => uint256) public remaining;

    modifier lock() {
    require(lockStatus,"FireLock: You have already locked the position");
        _;
    }
    modifier unlock(){
        require(unlockStatus,"FireLock: The contract has already terminated");
        _;
    }

    modifier nonReentrant() {
        require(!locked, "FireLock: ReentrancyGuard: reentrant call");
        locked = true;
        _;
        locked = false;
    }


    constructor(address _weth,address _fireLockFeeTransfer,address _treasuryDistributionContract,address _factoryAddr,address _createUser) {
        weth = _weth;
        fireLockFeeTransfer = _fireLockFeeTransfer;
        treasuryDistributionContract = _treasuryDistributionContract;
        factoryAddr = _factoryAddr;
        createUser = _createUser;
        lockStatus = true;
        unlockStatus = true;
    }

    function validateSum(uint[] memory nums) public pure returns (bool) {
        uint sum = 0;
        for (uint i = 0; i < nums.length; i++) {
            sum += nums[i];
            if (sum > 100) {
                return false;
            }
        }
        return sum == 100;
    }
     function isUnique(address[] memory addresses) public pure returns (bool) {
        uint length = addresses.length;
        for (uint i = 0; i < length; i++) {
            for (uint j = i + 1; j < length; j++) {
                if (addresses[i] == addresses[j]) {
                    return false;
                }
            }
        }
        return true;
    }
function isContractAddress(address addr) private view returns (bool) {
    uint32 size;
    assembly {
        size := extcodesize(addr)
    }
    return (size > 0);
}


function Lock(
    address _token,
    address _admin,
    uint256 _unlockCycle,
    uint256 _unlockRound,
    uint256 _amount,
    address[] memory _to,
    uint256[] memory _rate,
    string memory _title,
    uint256 _cliffPeriod
) public payable  lock {
    require(isUnique(_to),"FireLock: address is not unique");
    require(_to.length > 0 && _rate.length > 0 , "FireLock: Address and scale cannot be empty");
    require(_to.length == _rate.length , "FireLock: user amount error");
    for(uint256 i = 0; i < _to.length; i++){
        require(!_to[i].isContract(), "FireLock: Contract address found in _to array.");
    }
    require(msg.sender == createUser, "FireLock: you are not creat user");
    require(block.timestamp.add(_unlockCycle.mul(_unlockRound).mul(ONE_DAY_TIME_STAMP)) > block.timestamp, "FireLock: Deadline should be bigger than current block number");
    require(_amount > 0, "FireLock: Token amount should be bigger than zero");
    require(validateSum(_rate),"FireLock: rate error");
    require(_unlockCycle > 0 && _unlockRound > 0, "FireLock: Period and round input errors");
    require(bytes(_title).length > 0, "FireLock: String must not be empty.");
    address owner = msg.sender;
    uint256 cliffPeriod = block.timestamp.add(_cliffPeriod.mul(ONE_DAY_TIME_STAMP)) ;
    uint256 _ddl = cliffPeriod.add(_unlockCycle.add(_unlockRound).mul(ONE_DAY_TIME_STAMP));

    if (msg.value == 0) {
        TransferHelper.safeTransferFrom(weth, msg.sender, feeReceiver(), feeAmount());
    } else {
        require(msg.value == feeAmount(), 'Amount error');
        IWETH(weth).deposit{value: feeAmount()}();
        IWETH(weth).transfer(feeReceiver(), feeAmount());
    }
    

    LockDetail memory _LockDetail = LockDetail({
        LockTitle: _title,
        ddl: _ddl,
        startTime: cliffPeriod,
        admin: _admin,
        amount: _amount,
        unlockCycle: _unlockCycle,
        unlockRound: _unlockRound,
        rate: _rate,
        token: _token,
        member: _to,
        cliffPeriod: cliffPeriod
    });

    adminLockDetail = _LockDetail;

    IERC20(_token).transferFrom(owner, address(this), _amount);
    lockStatus = false;

    IFireLockFactory(factoryAddr).addLockItem(
        address(this),
        _LockDetail.LockTitle,
        _LockDetail.amount,
        block.timestamp,
        _LockDetail.startTime,
        _LockDetail.unlockCycle,
        _LockDetail.unlockRound,
        _LockDetail.ddl,
        _LockDetail.admin
    );
    totalAmount =  _amount;
    checkRate();
    IFireLockFactory(factoryAddr).isNotUninitialized(address(this), true);
}

function isUserUnlock(address _user) public view returns(uint256 _userId) {
    uint256 len = adminLockDetail.member.length;
    for(uint256 i = 0 ; i < len; i++){
        if(_user == adminLockDetail.member[i]){
            return i;
        }
    }
    revert("FireLock: You are not a user of this lock address");
}


function claim(uint256 _amount) public nonReentrant unlock {
    require(totalRate == 100, "FireLock: rate is error");
    require(block.timestamp > adminLockDetail.cliffPeriod, "FireLock: still cliffPeriod");
    uint256 userId = isUserUnlock(msg.sender);
    uint256 amountOfUser = totalAmount;
    address _token = adminLockDetail.token;
    uint256 timeA = (userTime[msg.sender] == 0) ? block.timestamp.sub(adminLockDetail.cliffPeriod) : block.timestamp.sub(userTime[msg.sender]);
    uint256 timeB = adminLockDetail.unlockCycle.mul(adminLockDetail.unlockRound).mul(ONE_DAY_TIME_STAMP);
    uint256 userMaxClaim = amountOfUser.mul(adminLockDetail.rate[userId]).div(100);
    uint256 _unLockAmount = userMaxClaim.mul(timeA).div(timeB);

    require(claimed[msg.sender] < userMaxClaim, "FireLock: You do not have enough balance to claim");
    require(_amount <= userMaxClaim, "FireLock: Insufficient quota");
    require(_amount <= _unLockAmount.add(remaining[msg.sender]), "FireLock: Claim amount exceeds allowed maximum");
    require(claimed[msg.sender].add(_amount) <= userMaxClaim, "FireLock: Claim amount exceeds user's allowed maximum");

    IERC20(_token).safeTransfer(msg.sender, _amount);
    adminLockDetail.amount = adminLockDetail.amount.sub(_amount);
    userTime[msg.sender] = block.timestamp;
    remaining[msg.sender] = _unLockAmount.add(remaining[msg.sender]).sub(_amount);

    unLockRecord memory _unlockRecord = unLockRecord({
        user: msg.sender,
        amount: _amount,
        time: block.timestamp
    });
    record.push(_unlockRecord);
    claimed[msg.sender] = claimed[msg.sender].add(_amount);
    IFireLockFactory(factoryAddr).addClaimInfo(address(this), _amount);

    if (adminLockDetail.amount == 0) {
        unlockStatus = false;
    }
}

    function checkRate() internal {
        uint256 _totalRate;
        for(uint256 i =0; i < adminLockDetail.rate.length; i++ ){
            _totalRate = _totalRate.add(adminLockDetail.rate[i]) ;
        }
        totalRate = _totalRate;
    }

    function changeLockAdmin(address _to) public  {
    address sender = msg.sender;
    address lockAdmin = adminLockDetail.admin;
    require(lockAdmin != address(0), "FireLock: Lock admin must exist");
    require(lockAdmin == sender, "FireLock: Sender must be admin");
    require(_to != address(0), "FireLock: transfer address does not exist");

    adminLockDetail.admin = _to;

    IFireLockFactory(factoryAddr).addlockAdmin(address(this), _to);
    }

    function isNotExist(address _to) internal view returns(bool) {
        for(uint256 i = 0 ; i < adminLockDetail.member.length; i++) {
            if(_to == adminLockDetail.member[i]){
                return false;
            }
        }
        return true;
    }
function setLockMemberAddr(uint256 _id, address _to) public  unlock {
    require(isNotExist(_to), "FireLock: the address is exist");
    require(_to != address(0),"FireLock: the address zero is not allow");
    require(adminLockDetail.member.length > 0, "FireLock: user amount error");
    require(msg.sender == adminLockDetail.admin);
    require(_id < adminLockDetail.member.length, "FireLock: Invalid member ID");

    address oldAddress = adminLockDetail.member[_id];

    claimed[_to] = claimed[oldAddress];
    delete claimed[oldAddress];

    remaining[_to] = remaining[oldAddress];
    delete remaining[oldAddress];

    userTime[_to] = userTime[oldAddress];
    delete userTime[oldAddress];

    adminLockDetail.member[_id] = _to;
}

  
    function checkGroupMember() public view returns(address[] memory){
        return adminLockDetail.member;
    }
    function setMemberRate(uint[] memory _rate) public {
        require(msg.sender == adminLockDetail.admin,"FireLock: you are not admin");
        require(_rate.length == adminLockDetail.rate.length , "FireLock: rate is not match");
        require(_rate.length == adminLockDetail.member.length, "FireLock: rate is not match");
        for(uint256 i =0; i< adminLockDetail.rate.length ;i++){
        
        adminLockDetail.rate[i] = _rate[i];
        }
        checkRate();
    }
    
   function calculateClaimableAmount(uint256 userId) public view returns(uint256) {
    address _user = adminLockDetail.member[userId];
    require(userId < adminLockDetail.member.length , "FireLock: User does not exist");
    require(_user != address(0), "FireLock: User does not exist");
    uint256 unLockAmount;
    if (userTime[_user] == 0) {
        unLockAmount = totalAmount.mul(adminLockDetail.rate[userId]).mul(block.timestamp.sub(adminLockDetail.startTime))
        .div(100).div(adminLockDetail.unlockRound).div(adminLockDetail.unlockCycle).mul(ONE_DAY_TIME_STAMP);
    } else {
        unLockAmount = totalAmount.mul(adminLockDetail.rate[userId]).mul(block.timestamp.sub(userTime[_user]))
        .div(100).div(adminLockDetail.unlockRound).div(adminLockDetail.unlockCycle).mul(ONE_DAY_TIME_STAMP);
    }
    return unLockAmount;
}


    function getLockTitle() public view returns(string memory) {
        return adminLockDetail.LockTitle;
    }
   
    function feeAmount() public view returns(uint256) {
        return IFireLockFeeTransfer(fireLockFeeTransfer).getFee();
    }
    function feeReceiver() public view returns(address) {
        return IFireLockFeeTransfer(fireLockFeeTransfer).getAddress();
    }
    
    function getMember() public view returns(address[] memory) {
        return adminLockDetail.member;
    }
    function getMemberRate() public view returns(uint256[] memory) {
        return adminLockDetail.rate;
    }
    function getMemberAmount() external view returns(uint256) {
        return adminLockDetail.member.length;
    }
    function getRecordLength() external view returns(uint256) {
        return record.length;
    }
}