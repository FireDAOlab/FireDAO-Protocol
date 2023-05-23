// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CityNodeTreasury  {
    IERC20 public WETH;
    address[] public AllocationFundAddress;
    uint256[] public rate;
    address payable public admin;
    address public cityNode;
    bool public DestructStatus;
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    
    constructor(address payable _admin, address _cityNode) {
        admin = _admin;
        cityNode = _cityNode;
    }
    function setToken(IERC20 _weth) public onlyAdmin {
        WETH = _weth;
    }
    function transferOwner(address _admin ,address payable _to) external  {
        require(msg.sender == cityNode && admin == _admin,"no access");
        admin = _to;
    }
    function addRate(uint _rate) public onlyAdmin{
        rate.push(_rate);
    }
    function addAddress(address assigned) public onlyAdmin {
        AllocationFundAddress.push(assigned);
    }
    function setAddress(uint256 num , address _add)public onlyAdmin{
        AllocationFundAddress[num] = _add;
    }
    function setRate(uint256 num , uint256 _rate) public onlyAdmin {
        rate[num] = _rate;
    }
    function AllocationAmount() public {
        for(uint i = 0 ; i < AllocationFundAddress.length;i++){
            WETH.transfer(AllocationFundAddress[i],rate[i]);
        }
    }
    function transferAmount(address _to,uint256 amount) public onlyAdmin {
        require(getBalanceOfWeth()>0,"no amount");
        WETH.transfer(_to, amount);
    }


    function getDestructStatus() external view returns(bool) {
        return DestructStatus;
    }
    function getBalanceOfWeth() public view returns(uint256) {
        return WETH.balanceOf(address(this));
    }

}