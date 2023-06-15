// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IFireSoul.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
contract ReputationV3 is ERC20, ERC20Permit, ERC20Votes,Ownable {
    using SafeMath for uint256;
    struct tokenInfo {
        uint weight;
        bool enabled;
    }
    mapping (address => tokenInfo) public tokens;
    IFireSoul public FireSoul;
    constructor(IFireSoul _fireSoul) ERC20("Fire Reputation Token", "FRT") ERC20Permit("FRT") {
        FireSoul = _fireSoul;
    }

    // The functions below are overrides required by Solidity.
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
    function mint(address to,uint amount) public {
        if(tokens[msg.sender].enabled && FireSoul.checkFID(to)){
             amount = amount.mul(tokens[msg.sender].weight);
            _mint(to, amount);
        }
    }
    function burn(address account,uint256 amount){
        if(tokens[msg.sender].enabled && FireSoul.checkFID(account)){
            amount = amount.mul(tokens[msg.sender].weight);
            _burn(account,amount);
        }
    }
    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) external override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) external override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
}
