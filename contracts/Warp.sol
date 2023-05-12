// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IUniswapV2Router02.sol";
import "./interface/IMinistryOfFinance.sol";

contract warp {
    IERC20 public WETH;
    address public owner;
    address public ministryOfFinance;
    address public cityNode;
    address public fireSeedAddress;
    uint256 public proportion;
    //0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 pancake
    //0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D uniswap
    constructor () {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        owner = msg.sender;
        WETH = IERC20(_uniswapV2Router.WETH());
        setProportion(8);
    }
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    //onlyOwner
    function setProportion(uint256 _proportion) public onlyOwner{
        proportion = _proportion;
    }
    function setMinistryOFinance(address _ministryOfFinance) public onlyOwner {
        ministryOfFinance = _ministryOfFinance;
    }
    function setCityNode(address cNode) public onlyOwner{
        cityNode = cNode;
    }
    function setFireSeedAddress(address fSeed) public onlyOwner{
        fireSeedAddress = fSeed;
    }
    //main
    function withdraw() external  {
        WETH.transfer(msg.sender, balance()/10*(10-proportion));
        WETH.transfer(ministryOfFinance, balance()/10*proportion);
        IMinistryOfFinance(ministryOfFinance).setSourceOfIncome(1, balance()/10*proportion);
    }
    function balance() public view returns(uint256){
        return WETH.balanceOf(address(this));
    }
    function withdrawAll() public onlyOwner{
        WETH.transfer(msg.sender,balance());
    }
}
