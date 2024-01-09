// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract FDSBT005 is ERC20,Ownable{
    using SafeMath for uint256;

    string public logo;
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }
    bool public status = false;

    address public minter;
    address public admin;
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;
    mapping (address => uint32) public numCheckpoints;
    
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);
    event AdminChange(address indexed Admin, address indexed newAdmin);
    constructor(address manager,address _minter,uint256 _totalSupply,string memory _logo)  public ERC20("SBT-005","SBT-005"){
        logo = _logo;
        _mint(manager, _totalSupply * 10 ** 18);
        _addDelegates(manager, safe96(_totalSupply * 10 ** 18,"erc20: vote amount underflows"));
        minter = _minter;
        admin = manager;
    }
    modifier  _isMinter() {
        require(msg.sender == minter);
        _;
    }
    modifier  _isOwner() {
        require(msg.sender == admin);
        _;
    }
    function setStatus() public onlyOwner {
        status =!status;
    }
    function mint(address account, uint256 amount) public _isMinter returns (bool) {
        require(!status ,"status is false");
        _mint( account, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(false);
       _transferErc20(msg.sender,recipient,amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(false);
        _transferErc20(sender,recipient,amount);
        uint256 currentAllowance = allowance(sender,_msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance-amount);
        return true;
    }
   
    function getCurrentVotes(address account) external view returns (uint96) {
        require(!status ,"status is false");

        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }
    
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(!status ,"status is false");

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
        require(!status ,"status is false");

          
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

}
