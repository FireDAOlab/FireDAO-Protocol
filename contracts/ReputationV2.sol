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
    mapping (address => tokenInfo) public tokens;
    mapping (address => address) public delegates;
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;
    mapping (address => uint32) public numCheckpoints;
    event AddToken(address indexed _address,uint _weight);
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);


    function addToken(address _token,uint _weight) onlyOwner{
        require(_weight > 0 ,"Wrong weight");
        tokenInfo storage ti = tokens[_token];
        ti.weight = _weight;
        ti.enabled = true;
        emit AddToken(_token,_weight);
    }
    function deactivateToken(address _token) onlyOwner{
        tokenInfo storage ti = tokens[_token];
        ti.enabled = false;
    }
    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    function getCurrentScore(address account) public view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }


    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
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

    function addScore(uint amount) external {
        require(tokens[msg.sender].weight > 0 , "Wrong weight");
        if(tokens[msg.sender].enabled){
            amount=amount.mul(tokens[msg.sender].weight);
            _moveDelegates(address(0),delegates[msg.sender], amount);
        }
    }
    function subScore(uint amount) external {
        require(tokens[msg.sender].weight > 0 , "Wrong weight");
        if(tokens[msg.sender].enabled){
            amount = amount.mul(tokens[msg.sender].weight);
            _moveDelegates(delegates[msg.sender],address(0),amount);
        }
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = getCurrentScore[delegator];
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

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint oldVotes, uint96 newVotes) internal {
        uint32 blockNumber = safe32(block.number, "Reputation::_writeCheckpoint: block number exceeds 32 bits");
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


    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

}
