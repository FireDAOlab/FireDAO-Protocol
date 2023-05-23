// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./interface/IFirePassport.sol";


contract AirdropERC1155 is ERC1155Holder{
    IERC1155 public token;
    IERC20 public tokenERC20;
    IERC721 public tokenERC721;
    address public passport;
    address public admin;
    uint public rounds;
    uint256 public baseUserAmount;
    uint256 public totalReceive;
    uint256 public numberOfIntervals;
    uint256 public id;
    uint256 public oneday = 86400;
    uint256 public endTime;
    uint256 public startTime;
    uint public num;
    mapping(address => bool) public Claimed;
    address[] public ClaimedList;
    constructor(IERC1155 _token,uint256 _tokenId, address _passport, address _admin, uint256 _startTime,uint _endTime){
        token = _token;
        id = _tokenId;
        passport = _passport;
        admin = _admin;
        startTime = _startTime;
        endTime = _endTime;
    }
    modifier onlyAdmin {
        require(msg.sender == admin ,"no access");
        _;
    }
    function changeAdmin(address _to) public onlyAdmin{
        admin = _to;
    }
    function remaining(uint256 _id) public onlyAdmin{
        token.safeTransferFrom(address(this), msg.sender,_id,get1155Balance(_id),"fire");
    }
    function setId(uint256 _id) public onlyAdmin{
        id = _id;
    }
    function addNum(uint _num) public onlyAdmin{
        num = _num;
    }
    function addDayTime(uint256 _time) public onlyAdmin {
        endTime += _time*oneday;
    }
    function getCurrentTimeStamp() public view returns(uint256) {
        return block.timestamp;
    }

    function Claim() public {
        require(IERC721(passport).balanceOf(msg.sender) !=0 ,"Insufficient balance for lock");
        require(!Claimed[msg.sender],"Insufficient balance for Claim");
        require(block.timestamp < endTime , "Insufficient time");
        require(block.timestamp > startTime, "Airdrop not started");

        if(getPid(msg.sender) > 0 &&  getPid(msg.sender) < baseUserAmount + 1){
            if(get1155Balance(id) < totalReceive && get1155Balance(id + num) > 0) {
            uint amount = get1155Balance(id);
            token.safeTransferFrom(address(this), msg.sender,id,amount,"fire");
            token.safeTransferFrom(address(this), msg.sender,id + num ,totalReceive - amount,"fire");
            }else{
            token.safeTransferFrom(address(this), msg.sender,id,totalReceive,"fire");
            }
        }else if(getPid(msg.sender) > baseUserAmount && getPid(msg.sender) <2*baseUserAmount + 1){
            if(get1155Balance(id) < totalReceive - numberOfIntervals && get1155Balance(id) > 0) {
            uint amount = get1155Balance(id);
            token.safeTransferFrom(address(this), msg.sender,id,amount,"fire");
            token.safeTransferFrom(address(this), msg.sender,id + num ,totalReceive - numberOfIntervals - amount,"fire");
            }else{
            token.safeTransferFrom(address(this), msg.sender,id,totalReceive - numberOfIntervals,"fire");
            }
        }else if(getPid(msg.sender) > 2*baseUserAmount && getPid(msg.sender) <3* baseUserAmount+1){
            if(get1155Balance(id) < totalReceive - 2*numberOfIntervals && get1155Balance(id) > 0) {
            uint amount = get1155Balance(id);
            token.safeTransferFrom(address(this), msg.sender,id,amount,"fire");
            token.safeTransferFrom(address(this), msg.sender,id + num ,totalReceive - 2*numberOfIntervals - amount,"fire");
            }else{
            token.safeTransferFrom(address(this), msg.sender,id,totalReceive - 2*numberOfIntervals,"fire");
            }
        }else if(getPid(msg.sender) > 3*baseUserAmount && getPid(msg.sender) < 4*baseUserAmount+1){
            if(get1155Balance(id) < totalReceive - 3*numberOfIntervals && get1155Balance(id) > 0) {
            uint amount = get1155Balance(id);
            token.safeTransferFrom(address(this), msg.sender,id,amount,"fire");
            token.safeTransferFrom(address(this), msg.sender,id + num ,totalReceive - 3*numberOfIntervals - amount,"fire");
            }else{
            token.safeTransferFrom(address(this), msg.sender,id,totalReceive - 3*numberOfIntervals,"fire");
            }
        }else if(getPid(msg.sender) > 4*baseUserAmount && getPid(msg.sender) <5*baseUserAmount+1) {
           if(get1155Balance(id) < totalReceive - 4*numberOfIntervals && get1155Balance(id) > 0) {
            uint amount = get1155Balance(id);
            token.safeTransferFrom(address(this), msg.sender,id,amount,"fire");
            token.safeTransferFrom(address(this), msg.sender,id + num ,totalReceive - 4*numberOfIntervals - amount,"fire");
            }else{           
            token.safeTransferFrom(address(this), msg.sender,id,totalReceive - 4*numberOfIntervals,"fire");
            }
        }else if(getPid(msg.sender) > 5*baseUserAmount && getPid(msg.sender) <6*baseUserAmount+1) {
            if(get1155Balance(id) < totalReceive - 5*numberOfIntervals && get1155Balance(id) > 0) {
            uint amount = get1155Balance(id);
            token.safeTransferFrom(address(this), msg.sender,id,amount,"fire");
            token.safeTransferFrom(address(this), msg.sender,id + num ,totalReceive - 5*numberOfIntervals - amount,"fire");
            }else{           
            token.safeTransferFrom(address(this), msg.sender,id,totalReceive - 5*numberOfIntervals,"fire");
            }
        } else if(getPid(msg.sender) > 6*baseUserAmount && getPid(msg.sender) < 7*baseUserAmount+1 ){
            if(get1155Balance(id) < totalReceive - 6*numberOfIntervals && get1155Balance(id) > 0) {
            uint amount = get1155Balance(id);
            token.safeTransferFrom(address(this), msg.sender,id,amount,"fire");
            token.safeTransferFrom(address(this), msg.sender,id + num ,totalReceive - 6*numberOfIntervals - amount,"fire");
            }else{           
            token.safeTransferFrom(address(this), msg.sender,id,totalReceive - 6*numberOfIntervals,"fire");
            }
        }else if(getPid(msg.sender) > 7*baseUserAmount && getPid(msg.sender) < 8*baseUserAmount+1){
            if(get1155Balance(id) < totalReceive - 7*numberOfIntervals && get1155Balance(id) > 0) {
            uint amount = get1155Balance(id);
            token.safeTransferFrom(address(this), msg.sender,id,amount,"fire");
            token.safeTransferFrom(address(this), msg.sender,id + num ,totalReceive - 7*numberOfIntervals - amount,"fire");
            }else{
            token.safeTransferFrom(address(this), msg.sender,id,totalReceive - 7*numberOfIntervals,"fire");
            }   
        }else if(getPid(msg.sender) > 8*baseUserAmount && getPid (msg.sender) < 9*baseUserAmount+1){
            if(get1155Balance(id) < totalReceive - 8*numberOfIntervals && get1155Balance(id) > 0) {
            uint amount = get1155Balance(id);
            token.safeTransferFrom(address(this), msg.sender,id,amount,"fire");
            token.safeTransferFrom(address(this), msg.sender,id + num ,totalReceive - 8*numberOfIntervals - amount,"fire");
            }else{
            token.safeTransferFrom(address(this), msg.sender,id,totalReceive - 8*numberOfIntervals,"fire");
            }
        }else if(getPid(msg.sender) > 9*baseUserAmount && getPid(msg.sender) < 10*baseUserAmount+1){
            token.safeTransferFrom(address(this), msg.sender,id,totalReceive - 9*numberOfIntervals,"fire");
        }else{
           return; 
        }
    Claimed[msg.sender] = true;
    ClaimedList.push(msg.sender);
    }
    function get1155Balance(uint256 _id) public view returns(uint256) {
        return token.balanceOf(address(this),_id);
    }
    function getPid(address _user) public view returns(uint){
        return IFirePassport(passport).getUserInfo(_user).PID;
    }
}
