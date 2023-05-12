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
    function checkReputation(address _user) external view returns (uint256) {
        uint256 reputationPoints = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            reputationPoints += IERC20(tokens[i]).balanceOf(IFireSoul(fireSoul).getSoulAccount(_user)) * coefficients[tokens[i]];
        }
        for(uint256 j = 0; j < subTokens.length;j++){
            reputationPoints -= IERC20(subTokens[j]).balanceOf(IFireSoul(fireSoul).getSoulAccount(_user)) * coefficients[subTokens[j]];
        }
        return reputationPoints;
    }

    function getTokensLength() external view returns (uint256) {
        return tokens.length;
    }
    function getSubTokensLength() external view returns(uint256){
        return subTokens.length;
    }
}
