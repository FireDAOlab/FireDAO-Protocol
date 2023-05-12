// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Flame is ERC20, Ownable {
    uint256 public _currentSupply;
    constructor() ERC20("FLAME","FLAME"){
        uint256 total = 10**29;
        _mint(owner(), total);
        _currentSupply = total;
    }
    function currentSupply() public view virtual returns (uint256) {
        return _currentSupply;
    }
    function burn(uint256 burnAmount) public {
        _burn(msg.sender, burnAmount);
    }
    function burnExternal(address user , uint256 burnAmount) external {
        _burn(user, burnAmount);
    }
}