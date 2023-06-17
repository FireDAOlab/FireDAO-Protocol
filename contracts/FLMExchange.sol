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
    event AddWhiteList(address indexed _operator,address[] indexed _user,uint[] _amount);
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
    function withdraw(address _token,address _to,uint _amount) external onlyOwner{
        IERC20(_token).transfer(_to,_amount);
    }
    function addWhiteList(address[] memory _users,uint[] memory _amounts)  external {
        require(managers.contains(msg.sender) == true,"No permission to operate");
        require(_users.length == _amounts.length,"Parameter input error");
        for(uint i = 0; i < _users.length;i++){
            userStores[_users[i]].storeAmount += _amounts[i];
        }

        emit AddWhiteList(msg.sender,_users,_amounts);
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
