// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interface/IFireSoul.sol";

contract ReputationV2 is Ownable{
    using SafeMath for uint256;
    struct tokenInfo {
        uint weight;
        bool enabled;
    }
    struct Checkpoint {
        uint32 fromBlock;
        uint votes;
    }
        /// @notice EIP-20 token name for this token
    string public constant name = "Fire Reputation Token";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "FRT";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;
    uint public  totalSupply;
    IFireSoul public FireSoul;
    mapping (address => tokenInfo) public tokens;
    mapping (address => address) public delegates;
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;
    mapping (uint32 => Checkpoint) public allCheckpoints;
    mapping (address => uint32) public numCheckpoints;
    uint32 public allNumCheckpoints;
    mapping (address => mapping (address => uint)) internal allowances;
    mapping (address => uint) internal balances;
    event AddToken(address indexed _address,uint _weight);
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    constructor(IFireSoul _fireSoul) {
        FireSoul = _fireSoul;
    }

    function addToken(address _token,uint _weight) public onlyOwner{
        require(_weight > 0 ,"Wrong weight");
        tokenInfo storage ti = tokens[_token];
        ti.weight = _weight;
        ti.enabled = true;
        emit AddToken(_token,_weight);
    }
    function deactivateToken(address _token) public onlyOwner{
        tokenInfo storage ti = tokens[_token];
        ti.enabled = false;
    }
    function delegate(address delegatee) public {
        require(FireSoul.checkFID(msg.sender),"You don't have a FID");
        return _delegate(msg.sender, delegatee);
    }

    function getCurrentVotes(address account) public view returns (uint) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    function getAllPriorVotes(uint blockNumber) public view returns (uint) {
        require(blockNumber < block.number, "Reputation::getPriorVotes: not yet determined");
        uint32 nCheckpoints = allNumCheckpoints;
        if (nCheckpoints == 0) {
            return 0;
        }
        if (allCheckpoints[nCheckpoints - 1].fromBlock <= blockNumber) {
            return allCheckpoints[nCheckpoints - 1].votes;
        }
        // Next check implicit zero balance
        if (allCheckpoints[0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = allCheckpoints[center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return allCheckpoints[lower].votes;
    }
    function getPriorVotes(address account, uint blockNumber) public view returns (uint) {
        require(blockNumber < block.number, "Reputation::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
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

    function mint(address user,uint amount) external {
        if(tokens[msg.sender].enabled && FireSoul.checkFID(user)){
            amount=amount.mul(tokens[msg.sender].weight);
            _moveDelegates(address(0),delegates[user], amount);
            balances[user] = balances[user].add(amount);
            totalSupply = totalSupply.add(amount);
            emit Transfer(address(0), user, amount);
        }
    }
    function burn(address user,uint amount) external {
        if(tokens[msg.sender].enabled && FireSoul.checkFID(user)){
            amount = amount.mul(tokens[msg.sender].weight);
            _moveDelegates(delegates[user],address(0),amount);
            balances[user] = balances[user].sub(amount);
            totalSupply = totalSupply.sub(amount);
            emit Transfer(user, address(0), amount);
        }
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint32 nCheckpoints = numCheckpoints[delegator];
        uint delegatorBalance = nCheckpoints > 0 ? checkpoints[delegator][nCheckpoints - 1].votes : 0;
        delegates[delegator] = delegatee;
        emit DelegateChanged(delegator, currentDelegate, delegatee);
        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }

    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint oldVotes, uint newVotes) internal {
        uint32 blockNumber = safe32(block.number, "Reputation::_writeCheckpoint: block number exceeds 32 bits");
        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
            allCheckpoints[nCheckpoints - 1].votes = allCheckpoints[nCheckpoints - 1].votes.add(newVotes);
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            allCheckpoints[nCheckpoints] = Checkpoint(blockNumber,allCheckpoints[nCheckpoints].votes.add(newVotes));
            numCheckpoints[delegatee] = nCheckpoints + 1;
            allNumCheckpoints = nCheckpoints + 1;
        }
        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }


    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

}
