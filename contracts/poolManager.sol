pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IUniswapV2Router02.sol";
import "./lib/TransferHelper.sol";


interface Pool{
     function setUniswapV2Router(IUniswapV2Router02 _uniswapV2Router) external ;
     function setReputationAmount(uint256 _amount) external;
     function setStatus() external ;
     function setIntervals(uint256 _time) external ;
     function setContractIntervals(uint256 _time) external;
     function setTokenAmount(uint256 _amount) external; 
     function setAwardRatio(uint256 _ratio) external;
}


contract poolManager is Ownable {
    address public weth;
    address public normalPool;
    address public emergencyPool;
    uint256 immutable public FEE_RATIO = 100;
    uint256 public NORMAL_POOL_RATIO;
    uint256 public EMERGENCY_POOL_RATIO;
    constructor(address _weth) {
      
        weth = _weth;
        NORMAL_POOL_RATIO = 50;
        EMERGENCY_POOL_RATIO = 50;
    }
    function init(address _normalPool, address _emergencyPool) public onlyOwner {
        require(_normalPool != address(0) && _emergencyPool != address(0), "address error");
        normalPool = _normalPool;
        emergencyPool = _emergencyPool;
    }
    function _setStatus() public onlyOwner {
        Pool(normalPool).setStatus();
        Pool(emergencyPool).setStatus();
    }
    function _setReputationAmount(uint256 _amount) public onlyOwner {
        Pool(normalPool).setReputationAmount(_amount);
        Pool(emergencyPool).setReputationAmount(_amount);
    }
    function setNORMAL_POOL_RATIO(uint256 _ratio) public onlyOwner {
        NORMAL_POOL_RATIO = _ratio;
    }
    function setEMERGENCY_POOL_RATIO(uint256 _ratio) public onlyOwner {
        EMERGENCY_POOL_RATIO = _ratio;
    }
    function _setUniswapV2Router(IUniswapV2Router02 _uniswapV2Router) public onlyOwner {
        Pool(normalPool).setUniswapV2Router(_uniswapV2Router);
        Pool(emergencyPool).setUniswapV2Router(_uniswapV2Router);
    }
    function fundAllocation() public onlyOwner {
        require(NORMAL_POOL_RATIO + EMERGENCY_POOL_RATIO == 100, "allocation ration is error");
        require(getContractBalance() > 0 , "contract balance is error");
        uint256 wethAmount  = getContractBalance();
        TransferHelper.safeTransfer(weth, normalPool, wethAmount * NORMAL_POOL_RATIO / FEE_RATIO);
        TransferHelper.safeTransfer(weth, emergencyPool, wethAmount * EMERGENCY_POOL_RATIO / FEE_RATIO);
         

    }
    function getContractBalance() public view returns(uint256) {
        return IERC20(weth).balanceOf(address(this));
    }
    //Live Reop Pool 
    function setQuota(uint256 _amount) public onlyOwner {
        Pool(normalPool).setTokenAmount(_amount);
    }
    function setReward(uint256 _ratio) public onlyOwner {
        Pool(normalPool).setAwardRatio(_ratio);
    } 
    function setTimeFrequency(uint256 _time) public onlyOwner {
        Pool(normalPool).setContractIntervals(_time);
    }
    function setAddressFrequency(uint256 _time) public onlyOwner {
        Pool(normalPool).setIntervals(_time);
    }
    //Emergency Reop Pool 
    function _setQuota(uint256 _amount) public onlyOwner {
        Pool(emergencyPool).setTokenAmount(_amount);
    }
    function _setReward(uint256 _ratio) public onlyOwner {
        Pool(emergencyPool).setAwardRatio(_ratio);
    } 
    function _setTimeFrequency(uint256 _time) public onlyOwner {
        Pool(emergencyPool).setContractIntervals(_time);
    }
    function _setAddressFrequency(uint256 _time) public onlyOwner {
        Pool(emergencyPool).setIntervals(_time);
    }
}