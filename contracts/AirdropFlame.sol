//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract airdropFlm is Ownable {
    struct whiteListInfo{
    
        address user;
        uint256 amount;
        string introduction;

    }
    uint256 private id;
    address public flm;
    using EnumerableSet for EnumerableSet.AddressSet;
    whiteListInfo[] public whiteListInfos;
    EnumerableSet.AddressSet private adminsLevelTwo;
    EnumerableSet.AddressSet private whiteList;
    mapping(address => uint256) public userTotalClaim;
    mapping(address => address) public fromLevelTwo;
    mapping(address => address[]) public levelTwoAdds;
    event ClaimRecord(uint256 id,address user, uint256 amount);

    modifier onlyAdminTwo {
        require(checkIsNotAdminsLevelTwo(msg.sender),'you are not admin level two');
        _;

    }
    modifier onlyWhiteListUser{
        require(checkIsNotWhiteListUser(msg.sender),'you are not whitelist user');
        _;
    }
    constructor(address _token) {
        flm = _token;
    }

    function setAdminsLevelTwo(address[] memory _addr) public onlyOwner{
        for(uint256 i = 0 ; i < _addr.length ; i ++){
            adminsLevelTwo.add(_addr[i]);
        }
    }   
    function checkIsNotWhiteListUser(address _address) internal view returns(bool){
        return whiteList.contains(_address);
    }
    function checkIsNotAdminsLevelTwo(address _address) internal view returns (bool) {
        return adminsLevelTwo.contains(_address);
    }
    
    function checkUserCanClaim(address _addr) public view returns(uint256) {
        uint256 total = 0 ;
        for(uint256 i =0 ; i< whiteListInfos.length ; i++){
            if(_addr == whiteListInfos[i].user){
                total = whiteListInfos[i].amount;
            }
        }
        return total;
    }
  
    function removeAdminsLevelTwo(address[] memory _addr) public onlyOwner {
           for(uint256 i = 0 ; i < _addr.length ; i ++){
               require(checkIsNotAdminsLevelTwo(_addr[i]), 'the address is not admin level two');
            adminsLevelTwo.remove(_addr[i]);
        }
    }
    function checkUserId(address _addr) internal view returns(uint256) {
        uint256 _id = 0;

        for(uint256 i = 0 ; i < whiteListInfos.length ;i++) {
            if(_addr == whiteListInfos[i].user){
               _id = i;
            }
        }
        return _id;
    }
    function addWhiteList(address[] memory _addr, uint256[] memory _amount, string[] memory _info) public onlyAdminTwo{
        for(uint256 i = 0; i< _addr.length ; i++){
            if(checkIsNotWhiteListUser(_addr[i])){
                whiteListInfos[checkUserId(_addr[i])].amount += _amount[i];
                return;
            }
            fromLevelTwo[_addr[i]] = msg.sender;
            levelTwoAdds[msg.sender].push(_addr[i]);
            whiteList.add(_addr[i]);
            whiteListInfo memory info = whiteListInfo({user:_addr[i], amount:_amount[i],introduction:_info[i] });
            whiteListInfos.push(info);
            emit ClaimRecord(id, _addr[i], _amount[i]);
            id++;
        }
    }
    function reomove(address _addr) internal {
        for(uint256 i = 0 ; i < whiteListInfos.length; i++){
            if(_addr == whiteListInfos[i].user){
                whiteListInfos[i] = whiteListInfos[whiteListInfos.length -1 ];
                whiteListInfos.pop();
                break;
            }
        }
    }
    function reduceAmount(address _addr,uint256 _amount) internal {
            for(uint256 i = 0 ; i < whiteListInfos.length; i++){
            if(_addr == whiteListInfos[i].user){
                whiteListInfos[i].amount -= _amount;
                break;
            }
        }
    }
    function removeWhiteList( address[] memory _addr) public onlyAdminTwo {
         for(uint256 i = 0; i< _addr.length ; i++){
             require(checkIsNotWhiteListUser(_addr[i]),'the address is not whitelist user');
            whiteList.remove(_addr[i]);
            reomove(_addr[i]);
        }
    }
    function backToken(address _token , uint256 _amount) public onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }
    function Claim(uint256 _amount) public onlyWhiteListUser{
        require(checkUserCanClaim(msg.sender) >= _amount, "Insufficient quantity available for extraction");
        IERC20(flm).transfer(msg.sender, _amount);
        reduceAmount(msg.sender,_amount);
        userTotalClaim[msg.sender] += _amount;
    }
    function getAdminsLevelTwoList() external view returns(address[] memory){
        return adminsLevelTwo.values();
    }
    function getWhiteList() external view returns(address[] memory) {
        return whiteList.values();
    }
   function getAdminsLevelTwoLength() external view returns (uint256) {
        return adminsLevelTwo.length();
    }
    function getWhiteListLength() external view returns(uint256) {
        return whiteList.length();
    }
    function getAdminAddsLength(address _user) external view returns(uint256) {
        return levelTwoAdds[_user].length;
    }
} 