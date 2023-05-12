// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/IFireSoul.sol";

contract Reputation is Ownable {
    using SafeERC20 for IERC20;

    mapping(address => uint256) public coefficient;
    address[] public sbt;
    address public fireSoul;

    constructor() {}

    function initialize() external onlyOwner {
        require(sbt.length == 0, "Already initialized");

        sbt.push(address(0x43387c942d7dd16aEa3134c9c9Dc7687C41005B4));
        sbt.push(address(0xb3CDC058F8910D95dADC1456F898E8a8458C053d));

        coefficient[sbt[0]] = 1;
        coefficient[sbt[1]] = 2;
    }

    function addSBTAddress(address _sbt, uint256 _coefficient) external onlyOwner {
        require(_sbt != address(0), "Invalid SBT address");
        require(coefficient[_sbt] == 0, "SBT address already added");

        sbt.push(_sbt);
        coefficient[_sbt] = _coefficient;
    }

    function setCoefficient(address _sbt, uint256 _coefficient) external onlyOwner {
        require(_sbt != address(0), "Invalid SBT address");
        require(coefficient[_sbt] > 0, "SBT address not added yet");

        coefficient[_sbt] = _coefficient;
    }

    function setFireSoulAddress(address _fireSoul) external onlyOwner {
        require(_fireSoul != address(0), "Invalid FireSoul address");

        fireSoul = _fireSoul;
    }

    function checkReputation(address _user) external view returns (uint256) {
        uint256 reputationPoints;

        for (uint256 i = 0; i < sbt.length; i++) {
            uint256 balance = IERC20(sbt[i]).balanceOf(IFireSoul(fireSoul).getSoulAccount(_user));
            uint256 weightedBalance = balance * coefficient[sbt[i]];
            reputationPoints += weightedBalance;
        }

        return reputationPoints;
    }

    function getSbtLength() external view returns (uint256) {
        return sbt.length;
    }
}
