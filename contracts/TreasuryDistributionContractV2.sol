// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./TreasuryDistributionContract.sol";
contract TreasuryDistributionContractV2 is TreasuryDistributionContract{
    mapping(uint256 => address) public setAddr;
    // must add virtual
    function setAddress(uint256 num, address _addr) public virtual {
        setAddr[num] = _addr;
    }
    function newWithdraw() public virtual onlyRole(DEFAULT_ADMIN_ROLE){
        require(IERC20(uniswapV2Router.WETH()).balanceOf(address(this))>0,"no weth to withdraw");
        IERC20(uniswapV2Router.WETH()).transfer(msg.sender , getWETHBalance());
    }
    function getVersion() public pure virtual returns (string memory) {
        return "2.0.0";
    }
}