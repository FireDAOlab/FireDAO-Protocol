// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AirdropERC20 {
    IERC20 public token;
    address public admin;
    uint256 public perAmount;
    address[] public userList;
    mapping(address => bool) public claimed;
    modifier onlyAdmin {
        require(msg.sender == admin,"no access");
        _;
    }
    constructor(IERC20 _token,address _admin, address[] memory _userList,uint256 _perAmount ){
        token = _token;
        admin = _admin;
        userList = _userList;
        perAmount = _perAmount;
    }
    
    function Claim() public {
        for(uint i =0; i<userList.length;i++){
            if(msg.sender == userList[i]){
                token.transfer(msg.sender, perAmount);
            }
        }
    }

    function remaining() public onlyAdmin {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}