// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
contract SeedDonation is Ownable,Pausable{
    using SafeMath for uint256;
    AggregatorV3Interface internal priceFeed; //matic test 0x0715A7794a1dc8e42615F059dD6e406A6594651A
    IERC20 public FDT;
    uint public round = 1;
    uint public currentPrice = 10000; 
    uint public currentRemaining = 5000000e18;
    constructor(IERC20 _FDT,address _priceFeed){
        FDT = _FDT;
        priceFeed = AggregatorV3Interface(
            _priceFeed
        );
    }
    function withdraw(address _to,uint _amount) external onlyOwner {
        FDT.transfer(_to,_amount);
    }
    function donation() payable external  {
        _checkDonationAmount(msg.value); 
        uint 
    }
    function getLastPrice() public view returns(int){
          (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }
    function _checkDonationAmount(uint _amount) internal pure{
        require(_amount>=1e17 && _amount <= 2e18,"The quantity does not meet the requirements");
        bool allow = false;
        for (uint i = 1e17;i<=2e18;i=i+1e17){
            if (_amount == i) {
                allow = true;
            }
        }
        require(allow,"The quantity can only be a multiple of 0.1");
    }
    receive() external payable {}
}
