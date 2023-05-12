// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IUniswapV2Router02.sol";

contract FireDaoTreasury is Ownable {

    IUniswapV2Router02 public uniswapV2Router;
    mapping(uint256 => mapping(uint256 => string))public proposal;
    mapping(uint256 => uint256 ) public tokenAmount;
    mapping(uint256 => address) public proposalOwner;
    address public allowAddress;

    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Router = _uniswapV2Router;
    }

    function setallowAddress(address _allowAddress) public onlyOwner{
        allowAddress =_allowAddress;
    }
    function CreateAProposal (string memory txt, uint256 amount ) public {
        uint256 id;
        proposal[id][amount] = txt ;
        tokenAmount[id] = amount;
        proposalOwner[id] = msg.sender;
        id++; 

    }
    function CreateAProposalExternal (string memory txt, uint256 amount ) external {
        require(msg.sender == allowAddress, " the address is not allow");
        uint256 id;
        proposal[id][amount] = txt ;
        tokenAmount[id] = amount;
        proposalOwner[id] = msg.sender;
        id++; 

    }
    function Execute(uint256 proposalId) public onlyOwner {
        IERC20(uniswapV2Router.WETH()).transfer(proposalOwner[proposalId], tokenAmount[proposalId]);
    }

    function ExecuteExternal(uint256 proposalId) external {
        require(msg.sender == allowAddress , "the Address is not allow ");
        IERC20(uniswapV2Router.WETH()).transfer(proposalOwner[proposalId], tokenAmount[proposalId]);
    }
}
