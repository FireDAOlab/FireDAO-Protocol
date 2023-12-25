// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FDSBT004 is ERC20,Ownable{
    using SafeMath for uint256;
    string public logo;
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }
    bool public status = false;
    address public minter;
    address public admin;
    address public aa;
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;
    mapping (address => uint32) public numCheckpoints;
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);
    event AdminChange(address indexed Admin, address indexed newAdmin);
    constructor()  ERC20("SBT-004", "SBT-004"){
    }
    function setStatus() public {
        status = !status;
    }
    function setaa(address _aa) public onlyOwner{
        aa = _aa;
    }
    function mint(address account, uint256 amount) external returns (bool) {
        require(!status , "status is false");
        require(msg.sender == aa);
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
        require(!status , "status is false");

        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }
    
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(!status , "status is false");

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
   

