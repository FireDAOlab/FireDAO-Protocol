// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IUniswapV2Router02.sol";
import "./interface/IReputation.sol";
contract EcologicalIncomeDividend is Ownable {
    bool public status;
    address public CityNodeAddress;
    address public pauseControlAddress;
    address public FDSBT001Address;
    uint256 public intervalTime;
    address public Reputation;
    IUniswapV2Router02 public uniswapV2Router;
    constructor(address roter){
      IUniswapV2Router02  _uniswapV2Router = IUniswapV2Router02(roter);
        uniswapV2Router = _uniswapV2Router;
    }
    //onlyOwner
    function setReputation(address _Reputation) public onlyOwner{
        Reputation =_Reputation;
    }
    function setFDSBT001Address(address _FDSBT001Address) public onlyOwner{
        FDSBT001Address = _FDSBT001Address;
    }
    function setPauseControlAddress(address _pauseControlAddress) public onlyOwner{
        pauseControlAddress = _pauseControlAddress;
    }
    //main
    function setContractStatus() external {
        require(msg.sender == pauseControlAddress);
        status = !status;
    }
    function Dividend(address user) public {
        require(IReputation(Reputation).checkReputation(msg.sender) > 100000*10*18,"you reputation point not enough");
        require(IERC20(FDSBT001Address).balanceOf(msg.sender) > 10000 *10 **18 , "you balance not enough");
        require(block.timestamp - intervalTime > 86400, "interval 24 hours");
        intervalTime = block.timestamp;
        IERC20(uniswapV2Router.WETH()).transfer(user, IERC20(FDSBT001Address).balanceOf(msg.sender)/IERC20(FDSBT001Address).totalSupply());
    }
}