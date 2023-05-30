// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
    struct User{
        uint id;
        address account;
        string username;
        string information;
//        string bio;
//        string email;
//        string twitter;
//        string telegram;
//        string website;
        uint joinTime;
    }

interface IUsers {
    function usernameExists(string memory username) external returns(bool);
    function getUserCount() external view  returns(uint);
}
