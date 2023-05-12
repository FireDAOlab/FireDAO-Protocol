// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract FDSBT007 is ERC20 ,Ownable{
    using SafeMath for uint256;
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }
    bool public status = false;
    address public minter;
    address public admin;
    address public LockAddress;
    address public fireSoul;
    address public fireSeed;
    address public passPort;
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;
    mapping (address => uint32) public numCheckpoints;
    
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);
    event AdminChange(address indexed Admin, address indexed newAdmin);
    //set fireSeed, fireSoul
    constructor() ERC20("SBT-007", "SBT-007"){
    }
   
    function setFireSoul(address firesoulAddress) public onlyOwner{
        fireSoul = firesoulAddress;
    } 
    function setFireSeed(address _fireSeed) public onlyOwner {
        fireSeed = _fireSeed;
    }
    function setPassPort(address _passPort) public onlyOwner {
        passPort = _passPort;
    }
    function setMintExternalAddress(address _LockAddress) public onlyOwner{
        LockAddress =_LockAddress;
    }
    function setContractStatus() public onlyOwner {
        status = !status;
    }

    function mint(address account, uint256 amount) external {
        require(msg.sender == LockAddress || msg.sender == fireSeed || msg.sender ==passPort,"SBT007:you set Address is error"); 
        _mint(account, amount);
    }
    function burn(address account, uint256 amount) external {
        require(msg.sender == LockAddress || msg.sender == fireSeed || msg.sender ==passPort,"SBT007:you set Address is error"); 
        _burn(account, amount);
    }
    

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(!status , "status is not able");
        require(false);
       _transferErc20(msg.sender,recipient,amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(!status , "status is not able");
        require(false);
        _transferErc20(sender,recipient,amount);
        uint256 currentAllowance = allowance(sender,_msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance-amount);
        return true;
    }
   
    function getCurrentVotes(address account) external view returns (uint96) {
        require(!status , "status is not able");
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }
    
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(!status , "status is not able");

         require(blockNumber <= block.number, "ERC20: not yet determined");
    
         uint32 nCheckpoints = numCheckpoints[account];
         if (nCheckpoints == 0 || checkpoints[account][0].fromBlock > blockNumber) {
             return 0;
         }
         
         if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
             return checkpoints[account][nCheckpoints - 1].votes;
         }
    
         uint32 lower = 0;
         uint32 upper = nCheckpoints - 1;
         while (upper > lower) {
             uint32 center = upper - (upper - lower) / 2; 
             Checkpoint memory cp = checkpoints[account][center];
             if (cp.fromBlock == blockNumber) {
                 return cp.votes;
             } else if (cp.fromBlock < blockNumber) {
                 lower = center;
             } else {
                 upper = center - 1;
             }
        }
        return checkpoints[account][lower].votes;
     }
   
    function _transferErc20(address sender, address recipient, uint256 amount) internal {
          
        uint96 amount96 = safe96(amount,"vote: vote amount underflows");
           
        _transfer(sender, recipient, amount);
        _addDelegates(recipient, amount96);
        _devDelegates(sender, amount96);
    }
  
    function _addDelegates(address dstRep, uint96 amount) internal {
          
        uint32 dstRepNum = numCheckpoints[dstRep];
        uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
        uint96 dstRepNew = add96(dstRepOld, amount, "vote: vote amount overflows");
        _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
        
    }
   
    function _devDelegates(address srcRep,  uint96 amount) internal {
          
        uint32 srcRepNum = numCheckpoints[srcRep];
        uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
        uint96 srcRepNew = sub96(srcRepOld, amount, "vote: vote amount underflows");
        _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
    }
    
    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
        uint32 blockNumber = safe32(block.number, "erc: block number exceeds 32 bits");
    
        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }
    
        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }
    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }
    
    function safe96(uint256 n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }
    
    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }
}
