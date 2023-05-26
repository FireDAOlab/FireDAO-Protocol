// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IFireSoul.sol";

contract Reputation is Ownable {
    mapping(address => uint256) public coefficients;
    address[] public tokens;
    address[] public subTokens;
    address public fireSoul;
    mapping (address => uint256) public userSource;

        //compound
    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }
    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;
    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;
    /// @notice A record of each accounts delegate
    mapping (address => address) public delegates;
    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);
    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    constructor() {
        _addDelegates(address(this), safe96(type(uint96).max,"erc20: vote amount underflows"));

    }

    function setFireSoulAddress(address _fireSoul) external onlyOwner {
        fireSoul = _fireSoul;
    }

    function addTokenAddress(address _token, uint256 _coefficient) external onlyOwner {
        for(uint256 i = 0 ; i < tokens.length; i ++ ) {
            require(tokens[i] != _token, "FireReputation: token is exist");
        }
        tokens.push(_token);
        coefficients[_token] = _coefficient;
    }
    function subTokenAddress(address _token, uint256 _coefficient) external onlyOwner{
        for(uint256 i = 0 ; i < subTokens.length; i ++ ) {
            require(subTokens[i] != _token, "FireReputation: token is exist");
        }
        subTokens.push(_token);
        coefficients[_token] = _coefficient;
        
    }
    function setCoefficient(address _token, uint256 _coefficient) external onlyOwner {
        require(coefficients[_token] > 0, "FireReputation: token does not exist");
        coefficients[_token] = _coefficient;
    }
    function deleteToken(address _token) external onlyOwner{
        require(coefficients[_token] > 0, "FireReputation: token does not exist");
        delete coefficients[_token];
        for(uint256 i = 0 ; i < tokens.length ; i++) {
            if(tokens[i] == _token) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
            }
        }
    }
    function deleteSubToken(address _token) external onlyOwner {
        require(coefficients[_token] > 0, "FireReputation: token does not exist");
        delete coefficients[_token];
        for(uint256 i = 0 ; i< subTokens.length ; i++ ){
            if(subTokens[i] == _token){
                subTokens[i] = subTokens[subTokens.length - 1];
                subTokens.pop();
            }
        }
    }
    function checkReputation(address _user) external  returns (uint256) {
        uint256 reputationPoints = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            reputationPoints += IERC20(tokens[i]).balanceOf(IFireSoul(fireSoul).getSoulAccount(_user)) * coefficients[tokens[i]];
        }
        for(uint256 j = 0; j < subTokens.length;j++){
            reputationPoints -= IERC20(subTokens[j]).balanceOf(IFireSoul(fireSoul).getSoulAccount(_user)) * coefficients[subTokens[j]];
        }
        userSource[_user] = reputationPoints;
        _moveDelegates(address(this), _user, safe96(reputationPoints,""));
        
        return reputationPoints;
    }


    function getTokensLength() external view returns (uint256) {
        return tokens.length;
    }
    function getSubTokensLength() external view returns(uint256){
        return subTokens.length;
    }
    

//compound 
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, "Comp::getPriorVotes: not yet determined");

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


function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }


    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = safe96(userSource[delegator],"");
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }


    function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "Comp::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "Comp::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }


   function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "Comp::_writeCheckpoint: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }
    function _addDelegates(address dstRep, uint96 amount) internal {
          
        uint32 dstRepNum = numCheckpoints[dstRep];
        uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
        uint96 dstRepNew = add96(dstRepOld, amount, "vote: vote amount overflows");
        _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
        
    }
   

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
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
