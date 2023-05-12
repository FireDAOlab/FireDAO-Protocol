// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract FDSBT001 is ERC20 ,Ownable{
    using SafeMath for uint256;
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }
    bool public status;
    address public exchangePoolAddress;
    address public LockAddress;
 
    
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);
    event AdminChange(address indexed Admin, address indexed newAdmin);
    constructor() ERC20("SBT-001", "SBT-001"){
    }
    function setExchangepool(address _exchangePoolAddress) public onlyOwner {
        exchangePoolAddress = _exchangePoolAddress;
    }
    function setMintExternalAddress(address _LockAddress) public onlyOwner{
        LockAddress =_LockAddress;
    }
    function setContractStatus() public onlyOwner {
        status = !status;
    }

    function mint(address Account, uint256 Amount) external {
        require(msg.sender == LockAddress || msg.sender == exchangePoolAddress,"you set Address is error"); 
        _mint(Account, Amount);

    }
    function burn(address Account, uint256 Amount) external {
        require(msg.sender == LockAddress || msg.sender == exchangePoolAddress,"you set Address is error"); 
        _burn(Account, Amount);

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
