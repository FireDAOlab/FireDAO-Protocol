// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./AirdropERC1155.sol";

contract AirdropFactory is Ownable {
    address[] public airdrop1155List;
    constructor(){
    }
    function createAirdropFor1155(IERC1155 token,uint256 tokenId ,address passport ,uint256 startTime,uint256 endTime) public {
        address airdrop = address(new AirdropERC1155(token,tokenId, passport, owner(),startTime,endTime));
        airdrop1155List.push(airdrop);
    }
    function getListLength() public view returns(uint256) {
        return airdrop1155List.length;
    }
}