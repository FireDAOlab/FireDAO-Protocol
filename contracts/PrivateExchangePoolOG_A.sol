
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
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interface/IFirePassport.sol";


contract PrivateExchangePoolOG is Ownable,Pausable {
    using SafeMath for uint256;

    uint256 constant private FEE_AMOUNT = 100000000000000000; // 0.1 ETH
    uint256 constant private MAX_BUY_AMOUNT = 2000000000000000000; // 2 ETH
    uint256 constant private DECIMALS = 10 ** 18;

	ERC20 fdt;
    struct whiteList{
        uint256 Pid;
        string name;
        address user;
    }

	address public weth;
    address public firePassport;
	uint256 private salePrice;
    uint256 private max;
    uint256 public inviteRate;
    uint256 public buyId;
    uint256 public totalDonate;
	bool public feeOn;
    address[] public assignAddress;
    address[] public admins;
    uint256[] public rate;
    whiteList[] public ShowWhiteList;
    mapping(address => whiteList[]) public adminInviter;
    mapping(address => bool) public admin;
    mapping(address => bool) public WhiteListUser;
    mapping(address => bool) public isRecommender;
    mapping(address => address) public recommender;
    mapping(address => address[]) public recommenderInfo;
	mapping(address => uint256) private userTotalBuy;

	AggregatorV3Interface internal priceFeed;
    event AllRecord(uint256 no, uint256 pid, string name, address addr,uint256 ethAmount,uint256 usdtAmount,uint256 rate,uint256 fdtAmount,uint256 time);
	/**
		* NetWork: Goerli
		* Aggregator: ETH/USD
		* Address:0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        * Arb goerli:0x62CAe0FA2da220f43a51F86Db2EDb36DcA9A5A08
	*/
	constructor(ERC20 _fdt,  address _weth, address _firepassport) {
		priceFeed = AggregatorV3Interface(0x62CAe0FA2da220f43a51F86Db2EDb36DcA9A5A08);
		fdt = _fdt;
		weth = _weth;
		salePrice = 10;
        firePassport = _firepassport;
        max = 30;
		feeOn = true;
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
    function setWhiteMax(uint256 _max) public onlyOwner{
        max = _max;
    }
    function setAdmin(address[] memory _addr ) public onlyOwner{
        for(uint i = 0; i < _addr.length;i++){
            if(IFirePassport(firePassport).hasPID(_addr[i]) && admin[_addr[i]] == false){
            admin[_addr[i]] = true;
            admins.push(_addr[i]);
            }
        }
    }
    function removeAdmin(address _addr) public onlyOwner{
        uint _id;
        for(uint i = 0 ; i<admins.length;i++){
            if(admins[i] == _addr){
             _id = i;
             break;
            }
        }
        require(_id < admins.length, "the address does not exist");
        admins[_id] = admins[admins.length - 1];
        admins.pop();
        admin[_addr] = false;

    }
    function addWhiteList(address[] memory _addr) public{
        require(admin[msg.sender],"you don't have permission");
        require(adminInviter[msg.sender].length <= max,"Exceeded the set total");
        for(uint i=0;i<_addr.length;i++){
           if (recommender[_addr[i]] == address(0) &&  recommender[msg.sender] != _addr[i] && !isRecommender[_addr[i]]) {
             recommender[_addr[i]] = msg.sender;
             recommenderInfo[msg.sender].push(_addr[i]);
             isRecommender[_addr[i]] = true;
        }
        whiteList memory wlist = whiteList({Pid:getPid(_addr[i]),name:getName(_addr[i]),user:_addr[i]});
        adminInviter[msg.sender].push(wlist);
        ShowWhiteList.push(wlist);
        WhiteListUser[_addr[i]] = true;
        }
    }
    function removeWhiteList(address _addr) public{
        require(admin[msg.sender],"you don't have permission");
        uint _id;

        for(uint i = 0; i<adminInviter[msg.sender].length; i++){
            if(adminInviter[msg.sender][i].user == _addr){
                _id = i;
                break;
            }
        }
        require(_id < adminInviter[msg.sender].length , "the address does not exist");
        adminInviter[msg.sender][_id] = adminInviter[msg.sender][adminInviter[msg.sender].length -1];
        adminInviter[msg.sender].pop();
        WhiteListUser[_addr] = false;
        removeWhiteListTotal(_addr);
    }
    function removeWhiteListTotal(address _addr) internal {
        uint _id;
        for(uint i = 0; i<ShowWhiteList.length;i++){
            if(ShowWhiteList[i].user == _addr){
                _id = i;
                break;
            }
        }
        require(_id < ShowWhiteList.length , "the address does not exist");
        ShowWhiteList[_id] = ShowWhiteList[ShowWhiteList.length - 1];
        ShowWhiteList.pop();
    }
    function SetassignAddress(address[] memory _addr) public onlyOwner{
        for(uint i = 0 ; i < _addr.length; i++) {
            assignAddress.push(_addr[i]);
        }
    }
    function removeAssiginAddress(address _addr) public onlyOwner{
        uint256 _id;
        for(uint256 i = 0; i<assignAddress.length ; i++){
            if(assignAddress[i] == _addr) {
                _id = i;
                break;
            }
        }
        require(_id < assignAddress.length, "the address does not exist");
        assignAddress[_id] = assignAddress[assignAddress.length - 1];
        assignAddress.pop();
    }
    function setRate(uint256[] memory _rate ,uint256 _invite) public onlyOwner{
        inviteRate = _invite;
        for(uint i = 0 ; i< _rate.length ;i++){
            rate.push(_rate[i]);
        }
    }
    function removeRate(uint256 _rate) public onlyOwner {
        uint256 _id;
        for(uint256 i =0; i< rate.length ;i++){
            if(rate[i] == _rate){
                _id = i ;
                break;
            }
        }
        require(_id < rate.length,"the address does not exist");
        rate[_id] = rate[rate.length -1] ;
        rate.pop();
    }
    function getRate() public view returns(uint256){
        uint256 total;
        for(uint i = 0; i<rate.length; i++){
            total+= rate[i];
        }
        return total + inviteRate;
    }
    function withdraw() public onlyOwner{
        fdt.transfer(msg.sender, getBalanceOfFDT());
    }
	
	//main
 function exchangeFdt(uint256 fee) external payable whenNotPaused {
        require(WhiteListUser[msg.sender] && IFirePassport(firePassport).hasPID(msg.sender), "Not a whitelist user or PID not casted");
        require(getRate() == 100, "rate error");
        require(fee == getValidFeeAmount(), "Please send the correct number of amount");
        require(fdtAmount(fee) < getBalanceOfFDT(), "the contract FDT balance is not enough");
        require(userTotalBuy[msg.sender].add(fee) <= MAX_BUY_AMOUNT, "fireDao ID only buy 2 ETH");

        if (feeOn) {
            require(msg.value == fee, "provide the error number on ETH");
            IWETH(weth).deposit{value: fee}();
            for (uint256 i = 0; i < assignAddress.length; i++) {
                TransferHelper.safeTransferFrom(weth, msg.sender, assignAddress[i], fee.mul(rate[i]).div(100));
            }
            TransferHelper.safeTransferFrom(weth, msg.sender, recommender[msg.sender], fee.mul(inviteRate).div(100));
        }

        uint256 amount = fdtAmount(fee);
        fdt.transfer(msg.sender, amount);

        userTotalBuy[msg.sender] = userTotalBuy[msg.sender].add(fee);
        totalDonate = totalDonate.add(fee);

        emit AllRecord(buyId, getPid(msg.sender), getName(msg.sender), msg.sender, fee, usdtAmount(fee), salePrice, amount, block.timestamp);
        buyId++;
    }

  function fdtAmount(uint256 fee) private view returns (uint256) {
        return fee.mul(getLatesPrice()).div(DECIMALS).div(salePrice);
    }

    function usdtAmount(uint256 fee) private view returns (uint256) {
        return fee.mul(getLatesPrice()).div(DECIMALS);
    }

    function getValidFeeAmount() private view returns (uint256) {
        for (uint256 i = 1; i <= 10; i++) {
            if (FEE_AMOUNT.mul(i) == msg.value) {
                return FEE_AMOUNT.mul(i);
            }
        }
        revert("Please send the correct number of amount");
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
    function getName(address _user) public view returns(string memory){
        return IFirePassport(firePassport).getUserInfo(_user).username;
    }
    function getPid(address _user) public view returns(uint) {
        return IFirePassport(firePassport).getUserInfo(_user).PID;
    }
    function getAdminWhiteListLength() public view returns(uint256) {
       return adminInviter[msg.sender].length;
    }
    function getWhiteListLength() public view returns(uint256) {
        return ShowWhiteList.length;
    }
    function getfdtAmount(uint256 fee) public view returns(uint256) {
	return (fee*getLatesPrice()/10**5)/salePrice;
    }
    function getValue() public view returns(uint256) {
        return getBalanceOfFDT()*(salePrice/1000);
    }

    receive() external payable {}


     /**
     * @dev Pause staking.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Resume staking.
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}

