// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interface/IERC20ForLock.sol";
import "./lib/TransferHelper.sol";
import "./interface/IWETH.sol";

/**
  * @title Lock tokens to the contract.
  */

contract FireLockMain {

    struct LockDetail{
        string LockTitle;
        bool isNotTerminate;
        uint256 ddl;
        uint256 startTime;
        uint256 amount;
        uint256 unlockCycle;
        uint256 unlockRound;
        address token;
        uint256 cliffPeriod;
    }

    struct groupLockDetail{
        string LockTitle;
        uint256 ddl;
        uint256 startTime;
        address admin;
        uint256 amount;
        uint256 unlockCycle;
        uint256 unlockRound;
        uint8[] rate;
        address token;
        address[] member;
        bool isNotchange;
        bool isNotTerminate;
    }

    address public treasuryDistributionContract;
    uint256 public fee;
    bool public feeON;
    address public owner;
    address public feeReceiver;
    address public weth;
    uint256 constant oneDayBlock  = 5760;
    mapping(address => address)  adminAndOwner;
    mapping(address => address[]) public tokenAddress;
    mapping(address => LockDetail[]) public ownerLockDetail;
    mapping(address => groupLockDetail[]) public adminGropLockDetail;
    address[] public ListTokenAddress;
    LockDetail[] public ListOwnerLockDetail;
    groupLockDetail[] public ListGropLockDetail;

    modifier onlyOwner{
        require(msg.sender == owner ,"you are not the lock owner");
        _;
    }
    
    modifier checkFee() {
    if (feeON) {
        require(msg.value == fee, "Please send the correct number of ETH");
        IWETH(weth).deposit{value: fee}();
        IWETH(weth).transfer(feeReceiver, fee);
    }
    _;
    }
    modifier onlyAdmin(uint _index) {
        require(adminAndOwner[msg.sender] == address(0) && msg.sender == adminGropLockDetail[msg.sender][_index].admin ||
        adminAndOwner[msg.sender] != address(0) && msg.sender == adminGropLockDetail[adminAndOwner[msg.sender]][_index].admin,"you are not admin");
        _;
    }

    
    constructor(address _weth ,address _feeReceiver) {
    owner = msg.sender;
    weth = _weth;
    feeReceiver = _feeReceiver;
    fee = 8000000000000000;
    }

     function setFee(uint fees) public  onlyOwner{
      require(fees <= 100000000000000000,'The maximum fee is 0.1ETH');
      fee = fees;
   }
    function setFeeOn() public onlyOwner{
        feeON = !feeON;
    }


function lock(address _token, address _to, uint256 _unlockCycle, uint256 _unlockRound, uint256 _amount, uint256 _cliffPeriod, string memory _titile, bool _Terminate) public payable checkFee {
  require(_unlockCycle * _unlockRound * oneDayBlock > 0, "ddl should be bigger than ddl current time");
  require(_amount > 0, "token amount should be bigger than zero");

  uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
  IERC20(_token).transferFrom(msg.sender, address(this), _amount);
  uint256 balanceAfter = IERC20(_token).balanceOf(address(this));
  require(balanceAfter - balanceBefore == _amount, "Token transfer failed");

  LockDetail memory lockinfo = LockDetail({
    LockTitle:_titile,
    ddl:block.number + _unlockCycle * _unlockRound * oneDayBlock + _cliffPeriod * oneDayBlock,
    startTime: block.number,
    amount: _amount,
    unlockCycle: _unlockCycle,
    unlockRound: _unlockRound,
    token: _token,
    cliffPeriod: block.number + _cliffPeriod * oneDayBlock,
    isNotTerminate: _Terminate
  });
  tokenAddress[_to].push(_token);
  ownerLockDetail[_to].push(lockinfo);
}

  function groupLock(
    address _token, 
    uint256 _unlockCycle, 
    uint256 _unlockRound, 
    uint256 _amount, 
    address[] memory _to, 
    uint8[] memory _rate, 
    string memory _titile, 
    uint256 _cliffPeriod, 
    bool _isNotTerminate, 
    bool _isNotChange
) public payable checkFee {
    require(_unlockCycle > 0 && _unlockRound > 0, "The lock time is wrong");
    require(_amount > 0, "Token amount should be bigger than zero");

    uint256 cliffPeriodDays = _cliffPeriod * oneDayBlock;
    groupLockDetail memory _groupLockDetail = groupLockDetail({
        token: _token,
        LockTitle: _titile,
        ddl: block.number + _unlockCycle * _unlockRound * oneDayBlock + cliffPeriodDays,
        startTime: block.number,
        admin: msg.sender,
        amount: _amount,
        unlockCycle: _unlockCycle,
        unlockRound: _unlockRound,
        rate: _rate,
        member: _to,
        isNotchange: _isNotChange,
        isNotTerminate: _isNotTerminate
    });
    ListTokenAddress.push(_token);
    ListGropLockDetail.push(_groupLockDetail);
    adminGropLockDetail[msg.sender].push(_groupLockDetail);
    IERC20(_token).transferFrom(msg.sender, address(this), _amount);
}

 function terminateLock(uint256 _lockId, address _token) public {
    require(ownerLockDetail[msg.sender][_lockId].amount > 0, "Insufficient balance for lock");
    require(ownerLockDetail[msg.sender][_lockId].isNotTerminate, "!isNotTerminate");
    TransferHelper.safeTransfer(_token, msg.sender, ownerLockDetail[msg.sender][_lockId].amount);
    ownerLockDetail[msg.sender][_lockId].amount = 0;
}

 function TerminateLockForGroupLock(uint256 _lockId, address _token) public {
    groupLockDetail storage lockDetail = adminGropLockDetail[msg.sender][_lockId];
    require(lockDetail.admin == msg.sender, "Unauthorized");
    require(lockDetail.isNotTerminate, "Lock is already terminated");
    uint256 lockAmount = lockDetail.amount;
    require(lockAmount > 0, "Lock amount is zero");
    lockDetail.amount = 0;
    TransferHelper.safeTransfer(_token, msg.sender, lockAmount);

}

    function unlock(uint _index, address _token) public {
    // 要求当前区块高度大于等于锁定期的结束时间（即可解锁时间）。
    require(block.number >= ownerLockDetail[msg.sender][_index].cliffPeriod, "Current time should be bigger than cliffPeriod");

    // 获取用户锁定的代币数量。
    uint amountOfUser = ownerLockDetail[msg.sender][_index].amount;

    // 获取合约地址下代币的余额。
    uint amount = IERC20(_token).balanceOf(address(this));

    // 判断余额是否足够解锁或者刚好足够解锁。
    if(amount > amountOfUser || amount == amountOfUser) {
        // 计算需要解锁的数量。
        uint unlockAmount = (amountOfUser / (ownerLockDetail[msg.sender][_index].unlockCycle * ownerLockDetail[msg.sender][_index].unlockRound)) * (block.number - ownerLockDetail[msg.sender][_index].startTime) / oneDayBlock;

        // 将代币转移到用户账户中。
        IERC20(_token).transfer(msg.sender, unlockAmount);

        // 更新锁定的代币数量和锁定时间。
        ownerLockDetail[msg.sender][_index].amount -= unlockAmount;
        ownerLockDetail[msg.sender][_index].startTime = block.number;
    } else {
        revert("Not enough balance for unlock");
    }
}

function groupUnLock(uint256 _index, address _token) public {
    require(checkRate(msg.sender, _index) == 100, "rate is error");
    require(block.number >= adminGropLockDetail[msg.sender][_index].ddl, "current time should be bigger than deadlineTime");
    uint256 amountOfUser = adminGropLockDetail[msg.sender][_index].amount;
    uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
    require(tokenBalance >= amountOfUser, "Insufficient balance");

    uint256 totalAmount = 0;
    uint256 unlockAmount = 0;
    for (uint256 i = 0; i < adminGropLockDetail[msg.sender][_index].member.length; i++) {
        totalAmount = (amountOfUser * adminGropLockDetail[msg.sender][_index].rate[i]) / 100;
        unlockAmount = totalAmount / (adminGropLockDetail[msg.sender][_index].unlockRound * adminGropLockDetail[msg.sender][_index].unlockRound);
        unlockAmount *= (block.number - adminGropLockDetail[msg.sender][_index].startTime) / oneDayBlock;
        IERC20(_token).transfer(adminGropLockDetail[msg.sender][_index].member[i], unlockAmount);
        adminGropLockDetail[msg.sender][_index].amount -= unlockAmount;
    }
    adminGropLockDetail[msg.sender][_index].startTime = block.number;
}

function checkRate(address _user, uint256 _index) public view returns(uint) {
    uint totalRate;
    uint8[] memory rates = adminGropLockDetail[_user][_index].rate;
    if (rates.length == 0) {
        return 0;
    }
    for(uint i = 0; i < rates.length; i++ ){
        totalRate += rates[i];
    }
    return totalRate;
}

    function changeLockAdmin(address _to, uint256 _index) public {
    address originalAdmin = adminAndOwner[msg.sender] != address(0) ? adminAndOwner[msg.sender] : msg.sender;
    require(adminGropLockDetail[originalAdmin][_index].admin == msg.sender, "you are not admin");
    require(!adminGropLockDetail[originalAdmin][_index].isNotchange, "you can't turn on isNotchange when you create ");
    adminGropLockDetail[originalAdmin][_index].admin = _to;
    adminAndOwner[_to] = originalAdmin;
}

 function setIsNotChange(uint _index) public onlyAdmin(_index) {
    if (adminAndOwner[msg.sender] == address(0)) {
        adminGropLockDetail[msg.sender][_index].isNotchange = !adminGropLockDetail[msg.sender][_index].isNotchange;
    } else {
        adminGropLockDetail[adminAndOwner[msg.sender]][_index].isNotchange = !adminGropLockDetail[adminAndOwner[msg.sender]][_index].isNotchange;
    }
}

    function addLockMember(address _to, uint _index, uint8 _rate) public {
    require(msg.sender == adminGropLockDetail[msg.sender][_index].admin, "you are not admin");
    require(_rate > 0, "rate should be positive");
    uint totalRate = 0;
    for (uint i = 0; i < adminGropLockDetail[msg.sender][_index].rate.length; i++) {
        totalRate += adminGropLockDetail[msg.sender][_index].rate[i];
    }
    require(totalRate + _rate <= 100, "rate exceeds limit");
    if (adminGropLockDetail[msg.sender][_index].rate.length == 0) {
        adminGropLockDetail[msg.sender][_index].member.push(address(0));
        adminGropLockDetail[msg.sender][_index].rate.push(0);
    }
    if (adminGropLockDetail[msg.sender][_index].rate[0] >= _rate) {
        adminGropLockDetail[msg.sender][_index].rate[0] -= _rate;
    } else {
        revert("insufficient rate for new member");
    }
    adminGropLockDetail[msg.sender][_index].member.push(_to);
    adminGropLockDetail[msg.sender][_index].rate.push(_rate);
}

   function removeLockMember(address _to, uint _index) public {
    require(msg.sender == adminGropLockDetail[msg.sender][_index].admin,'no access');
    uint memberIndex = findMemberIndex(adminGropLockDetail[msg.sender][_index].member, _to);
    if (memberIndex == adminGropLockDetail[msg.sender][_index].member.length) {
        // 如果成员不在锁定组中，则返回
        return;
    }
    uint8 quota = adminGropLockDetail[msg.sender][_index].rate[memberIndex];
    uint8 totalQuota = adminGropLockDetail[msg.sender][_index].rate[0];
    // 将该成员的配额加回到0号成员的配额中
    adminGropLockDetail[msg.sender][_index].rate[0] = totalQuota + quota;
    // 将该成员从成员数组中删除
    adminGropLockDetail[msg.sender][_index].member[memberIndex] = adminGropLockDetail[msg.sender][_index].member[adminGropLockDetail[msg.sender][_index].member.length - 1];
    adminGropLockDetail[msg.sender][_index].member.pop();
    // 将该成员的配额从配额数组中删除
    adminGropLockDetail[msg.sender][_index].rate[memberIndex] = adminGropLockDetail[msg.sender][_index].rate[adminGropLockDetail[msg.sender][_index].member.length];
    adminGropLockDetail[msg.sender][_index].rate.pop();
}

function findMemberIndex(address[] memory members, address member) private pure returns(uint) {
    for(uint i = 0; i < members.length; i++){
        if(member == members[i]){
            return i;
        }
    }
    return members.length;
}


function getGroupMembers(address _admin, uint256 _index) public view returns(address[] memory) {
    return adminGropLockDetail[_admin][_index].member;
}

function setGroupMemberRate(uint _index, uint8[] memory _rate) public {
    require(msg.sender == adminGropLockDetail[msg.sender][_index].admin);
    require(_rate.length == adminGropLockDetail[msg.sender][_index].member.length, "Rate array length must match number of group members");
    uint memberCount = adminGropLockDetail[msg.sender][_index].member.length;
    for(uint i = 0; i < memberCount; i++) {
        adminGropLockDetail[msg.sender][_index].rate[i] = _rate[i];
    }
}




    function getLockTitle(uint _index) public view returns(string memory){
        return ownerLockDetail[msg.sender][_index].LockTitle;
    }

    function getGroupLockTitle(uint _index) public view returns(string memory) {
        return adminGropLockDetail[msg.sender][_index].LockTitle;
    }

    function getAmount(uint _index) public view returns(uint) {
        return ownerLockDetail[msg.sender][_index].amount;
    }

    function getDdl(uint _index) public view returns(uint) {
        return ownerLockDetail[msg.sender][_index].ddl;
    }

    function getTokenName(uint _index) public view returns(string memory) {
        return IERC20(ownerLockDetail[msg.sender][_index].token).name();
    }

    function getTokenSymbol(uint _index) public view returns(string memory) {
        return IERC20(ownerLockDetail[msg.sender][_index].token).symbol();
    }

    function getTokenDecimals(uint _index) public view returns(uint) {
        return IERC20(ownerLockDetail[msg.sender][_index].token).decimals();
    }

    function getToken() public view returns(address[] memory) {
        return tokenAddress[msg.sender];
    }

    function ListOwnerLockDetailLength() public view returns(uint256){
        return ListOwnerLockDetail.length;
    }

    function ListGropLockDetailLength() public view returns(uint256) {
        return ListGropLockDetail.length;
    }

    function getGroupMember(uint _index) public view returns(address[] memory) {
    return ListGropLockDetail[_index].member;
    }
}
