// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interface/IFirePassport.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./interface/IWETH.sol";
import "./interface/ITreasuryDistributionContract.sol";
import "./lib/TransferHelper.sol";

contract FirePassport is IFirePassport,ERC721URIStorage {
   mapping(address => User) public userInfo;
   mapping(string => bool) public override usernameExists;
   string public baseURI;
   string public baseExtension = ".json";
   User[] public users;
   address public owner;
   event Register(uint  pid,string  username, address  account,string email,uint joinTime,string information);
   bool public feeOn;
   uint public fee;
   uint public minUsernameLength = 4;
   uint public maxUsernameLength = 30;
   address public firekun = 0x59af07FC784261c6c17790aB8FcEB15d52C8fBF0;
   address public weth;
   address public feeReceiver;
   address public treasuryDistributionContract;
   bool public useTreasuryDistributionContract;
   bool public pause;
   constructor(address  _feeReceiver,address _weth,string memory baseURI_) ERC721("Fire Passport", "FIREPP") {
      owner = msg.sender;
      feeReceiver = _feeReceiver;
      weth = _weth;
      User memory user = User({PID:1,account:firekun,username:"FireKun",information:"",joinTime:block.timestamp});
      users.push(user);
      userInfo[firekun] = user;
      usernameExists["firekun"] = true;
      baseURI = baseURI_;
      _mint(firekun, 1);
   }
 
   modifier checkUsername(string memory username) {
      bytes memory bStr = bytes(username);
      require(bStr.length >=minUsernameLength && bStr.length < maxUsernameLength ,"Username length exceeds limit");
      require(((uint8(bStr[0]) >= 97) && (uint8(bStr[0]) <= 122)) || ((uint8(bStr[0]) >= 65) && (uint8(bStr[0]) <= 90)),"Username begins with a letter"); 
         for (uint i = 0; i < bStr.length; i++) {
            require(((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) || ((uint8(bStr[i]) >= 48) && (uint8(bStr[i]) <= 57)) || ((uint8(bStr[i]) >= 97) && (uint8(bStr[i]) <= 122)) ||(uint8(bStr[i]) == 95),"The username contains illegal characters");
         }
    
      _;
   }
   modifier isOwner() {
      require(msg.sender == owner,"access denied");
      _;
   }
   modifier allowRegister() {
      require(pause == false,"Registration has been suspended");
      _;
   }
   function register(string memory username,string memory email,string memory information) payable external allowRegister checkUsername(username) {
      string memory trueUsername = username;
      username = _toLower(username);
      require(usernameExists[username] == false,"This username has already been taken");
      require(userInfo[msg.sender].joinTime == 0,"This username has already been taken");
      if(feeOn){
          if(msg.value == 0) {
              TransferHelper.safeTransferFrom(weth,msg.sender,feeReceiver,fee);
          } else {
              require(msg.value == fee,"provide the error number on ETH");
              IWETH(weth).deposit{value: fee}();
              IWETH(weth).transfer(feeReceiver,fee);
          }
      }
      uint id = users.length + 1;
      User memory user = User({PID:id,account:msg.sender,username:username,information:information,joinTime:block.timestamp});
      users.push(user);
      userInfo[msg.sender] = user;
      usernameExists[username] = true;
      _mint(msg.sender, id);
      if(useTreasuryDistributionContract) {
         ITreasuryDistributionContract(treasuryDistributionContract).setSourceOfIncome(1,msg.sender,fee);
      }
      emit Register(id,trueUsername,msg.sender,email,block.timestamp,information);
   }
   function setBaseURI(string memory baseURI_) isOwner external {
      baseURI = baseURI_;
   }
   function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
   }
   function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), baseExtension))
        : "";
  }
   function changeUserInfo(string memory information) external {
      require(userInfo[msg.sender].PID != 0,'This user does not exist');
      User storage user = userInfo[msg.sender];
      user.information = information;
      users[user.PID - 1].information = information;
   }
   function getUserCount() external view override returns(uint) {
      return users.length;
   }
    function hasPID(address user) external override view returns(bool){
        return userInfo[user].PID !=0;
    }
    function getUserInfo(address user) external override view returns(User memory){
        return userInfo[user];
    }
   function setFee(uint fees) isOwner public {
      require(fees <= 100000000000000000,'The maximum fee is 0.1ETH');
      fee = fees;
   }
   function pauseRegister(bool set) isOwner external {
      pause = set;
   }
   function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

   function setFeeOn(bool set) isOwner public {
     feeOn = set;
   }

   function setTreasuryDistributionContractOn(bool set) isOwner external {
      useTreasuryDistributionContract = set;
   }

   function setUsernameLimitLength(uint min,uint max)  isOwner public {
      minUsernameLength = min;
      maxUsernameLength = max;
   }

   function changeFeeReceiver(address  receiver) isOwner external {
      feeReceiver = receiver;
   }

   function setTreasuryDistributionContract(address _treasuryDistributionContract) isOwner external {
      require(_treasuryDistributionContract != address(0),"contract is the zero address");
      treasuryDistributionContract = _treasuryDistributionContract;
   }

   function changeOwner(address account) isOwner public {
      require(account != address(0),"account is the zero address");
      owner = account;
   }

   function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override  {
       from;
       to;
       tokenId;
       revert("ERC721:transfer declined");
    }
     receive() external payable {}
}
