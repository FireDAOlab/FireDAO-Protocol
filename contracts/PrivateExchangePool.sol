
// File: contracts/interface/IWETH.sol
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


// File: contracts/libraries/TransferHelper.sol

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interface/IFireSeed.sol";
import "./interface/IFireSoul.sol";
import "./interface/ISbt001.sol";
import "./interface/ILockForPrivateExchangePool.sol";

contract PrivateExchangePool is Ownable {
	
	struct userLock{
		uint256 amount;
		uint256 startBlock;
		uint256 endBlock;
	}
	uint256 private lockBlock = 2628000;
	ERC20 fdt;
	address public weth;
	address public feeReceiver;
	address public rainbowCityFundation;
	address public devAndOperation;
	address public sbt001;	
	address public fireSoul;
	address public fireSeed;
	address public lock;
	uint256 private salePrice;
	bool public feeOn;
	mapping(address => userLock[]) public userLocks;
	mapping(address => uint256) public userTotalBuy;
	AggregatorV3Interface internal priceFeed;
	/**
		* NetWork: Goerli
		* Aggregator: ETH/USD
		* Address:0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
	*/
	constructor(ERC20 _fdt, address _sbt001, address _weth) {
		priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
		fdt = _fdt;
		sbt001 = _sbt001;
		weth = _weth;
		salePrice = 5;
		feeReceiver = address(0xAAC5d9D97d062554b54D0b4ebab15324860D515F);
		rainbowCityFundation = address(0x077fD28B28Af5ebf105b5Ce7A60c3178C7F1A25e);
		devAndOperation = address(0x785f3408B475AE89c8347789Ece3777797CF3EDF);
		feeOn = true;
		lock = address(0xF1090556f013Ff5a01bEa597e0cbEC02C674B121);
		fireSeed = address(0xC8888776b3C542AD398FBA6a9500AA07d4214b69);
		fireSoul = address(0xF29EfF2289A49D68AAc1264Ce8aDA5D09DB3C94C);
	}
	//onlyOwner
	function setFeeStatus() public onlyOwner{
      	feeOn = !feeOn;
   	}
	function setFDTAddress(ERC20 _fdt) public onlyOwner {
		fdt = _fdt;
	}
	function setSalePrice(uint256 _salePrice) public onlyOwner {
		salePrice = _salePrice;
	}
	function changeFeeReceiver(address payable receiver) external onlyOwner {
      	feeReceiver = receiver;
    }
	function changeRainbowCityFundation(address payable _rainbowCityFundation) public onlyOwner {
		rainbowCityFundation = _rainbowCityFundation;
	}
	function changeDevAndOperation(address payable _devAndOperation) public onlyOwner {
		devAndOperation = _devAndOperation;
	}
    function setSbt001Address(address _sbt001) public onlyOwner {
		sbt001 = _sbt001;
	}
	function setLockForPrivateExchangePool(address _lock) public onlyOwner {
		lock = _lock;
	}
	function setFireSeed(address _fireSeed) public onlyOwner {
		fireSeed = _fireSeed;
	}
	function setFireSoul(address _fireSoul) public onlyOwner {
		fireSoul = _fireSoul;
	}
	//main
	function exchangeFdt(uint256 fee) public payable {
		uint256 fdtAmount = (fee*getLatesPrice()/10**5)/salePrice;
		address accountDown = IFireSeed(fireSeed).upclass(msg.sender);//1
		address account = IFireSeed(fireSeed).upclass(accountDown);//2
		address accountUp = IFireSeed(fireSeed).upclass(account);//3
		uint256 _fee = 100000000000000000;
		require(fdtAmount < getBalanceOfFDT(), "the contract FDT balance is not enough");
		require(IFireSoul(fireSoul).checkFID(msg.sender), "you haven't FID,plz do this first");
		require(userTotalBuy[msg.sender] + fee <= 5000000000000000000,"fireDao ID only buy 5 ETH");
		require(
			fee == _fee ||
			fee == 2*_fee ||
			fee == 3*_fee ||
			fee == 4*_fee ||
			fee == 5*_fee ||
			fee == 6*_fee ||
			fee == 7*_fee ||
			fee == 8*_fee ||
			fee == 9*_fee ||
			fee == 10*_fee ,"Please send the correct number of amount"

		);
		  if(feeOn){
          if(msg.value == 0) {
              TransferHelper.safeTransferFrom(weth,msg.sender,feeReceiver,fee*3/10);
              TransferHelper.safeTransferFrom(weth,msg.sender,feeReceiver,fee*3/10);
              TransferHelper.safeTransferFrom(weth,msg.sender,feeReceiver,fee*3/10);
			if(accountUp != address(0)){
            TransferHelper.safeTransferFrom(weth,msg.sender,accountDown,fee*5/100);
            TransferHelper.safeTransferFrom(weth,msg.sender,account,fee*3/100);
			TransferHelper.safeTransferFrom(weth,msg.sender,accountUp,fee*2/100);
			}else{
            TransferHelper.safeTransferFrom(weth,msg.sender,feeReceiver,fee/10);
			  }
          } else {
              require(msg.value == fee,"provide the error number on ETH");
               	IWETH(weth).deposit{value:fee}();
                IWETH(weth).transfer(feeReceiver,fee*3/10);
                IWETH(weth).transfer(rainbowCityFundation,fee*3/10);
                IWETH(weth).transfer(devAndOperation,fee*3/10);
			if(accountUp != address(0)){
				IWETH(weth).transfer(accountDown,fee*5/100);
				IWETH(weth).transfer(account,fee*3/100);
				IWETH(weth).transfer(accountUp,fee*2/100);

			}else{
                IWETH(weth).transfer(feeReceiver,fee/10);
			}
          }
      }
		fdt.transfer(msg.sender, fdtAmount*3/10);
		fdt.transfer(lock, fdtAmount*7/10);
		userLock memory info = userLock({amount: fdtAmount*7/10, startBlock:block.number, endBlock:block.number + lockBlock});
		userLocks[msg.sender].push(info);
		userTotalBuy[msg.sender] += fee;
		ISbt001(sbt001).mint(msg.sender, fdtAmount*7/10);
	}

	function withDrawLock(uint256 id_,address user_, uint256 amount_) public {
		require(amount_ <= this.getUserExtractable(user_,id_), "you must check getUserExtractable()");
		require(userLocks[user_][id_].amount != 0,"no amount to withDraw");
		ILockForPrivateExchangePool(lock).withDraw(user_, amount_);
		ISbt001(sbt001).burn(msg.sender, amount_);
		userLocks[user_][id_].startBlock = block.number;
		userLocks[user_][id_].amount -=  amount_;
	}
	function getUserBuyLength(address _user) external view returns(uint256) {
		return userLocks[_user].length;
	}
	function getUserLockEndBlock(address _user, uint256 lockId) external view returns(uint256) {
		return userLocks[_user][lockId].endBlock;
	}
	function getUserLockStartBlock(address _user, uint256 lockId) external view returns(uint256) {
		return userLocks[_user][lockId].startBlock;
	}
	function getUserExtractable(address _user, uint256 lockId) external view returns(uint256) {
		return userLocks[_user][lockId].amount * (block.number - userLocks[_user][lockId].startBlock)/lockBlock;
	}
	function getLatesPrice() public view returns (uint256) {
		(
			,
			int price,
			,
			,
			
		) = priceFeed.latestRoundData();

		return uint256(price);
	}
	function getBalanceOfFDT() public view returns(uint256) {
		return fdt.balanceOf(address(this));
	}
    receive() external payable {}
}

