// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
contract FLMExchange is Ownable,ReentrancyGuard {
    struct storageDetails {
        uint claimedAmount;
        uint storeAmount;
    }
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;
    EnumerableSet.AddressSet private managers;
    IERC20 public FLM;
    mapping(address => storageDetails) public userStores;
    event AddWhiteList(address indexed _operator,address indexed _user,uint _amount);
    event Claim(address indexed _user,uint _amount);
    constructor(IERC20 _FLM) {
        FLM = _FLM;
    }
    function setManager(address _manager) external onlyOwner{
        require(managers.contains(_manager) == false,"This user already exists");
        managers.add(_manager);
    }
    function removeManager(address _manager) external onlyOwner{
        require(managers.contains(msg.sender) == true,"This manager does not exist");
        managers.remove(_manager);
    }
    function addWhiteList(address _user,uint _amount)  external {
        require(managers.contains(msg.sender) == true,"No permission to operate");
        userStores[_user].storeAmount += _amount;
        emit AddWhiteList(msg.sender,_user,_amount);
    }
    function claim(uint _amount) external nonReentrant  {
        require(userStores[msg.sender].storeAmount >= _amount,"Not enough quantity");
        userStores[msg.sender].storeAmount = userStores[msg.sender].storeAmount.sub(_amount);
        userStores[msg.sender].claimedAmount += _amount;
        FLM.transfer(msg.sender, _amount);
        emit Claim(msg.sender,_amount);
    }
    function managerList() external view returns(address[] memory) {
       return managers.values();
    }

}