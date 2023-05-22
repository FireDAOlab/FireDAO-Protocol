// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./lib/SafeMath.sol";
import "./interface/IUniswapV2Router02.sol";
import "./interface/IFireSeed.sol";
import "./interface/IFireSoul.sol";
import "./interface/IUniswapV2Pair.sol";
import "./interface/IUniswapV2Factory.sol";
import "./interface/GetWarp.sol";
import "./interface/ITreasuryDistributionContract.sol";
import "./interface/ICityNode.sol";


contract FireDaoToken is ERC20 ,Ownable{
    using SafeMath for uint256;

    address public  uniswapV2Pair;
    address _tokenOwner;
    address public fireSoul;
    address public  TreasuryDistributionContract;
    address public cityNode;
    IUniswapV2Router02 public uniswapV2Router;
    address public fireSeed;
    IERC20 public WETH;
    IERC20 public pair;
    GetWarp public warp;
    bool private swapping;
    uint256 public swapTokensAtAmount;
    uint256 _destroyMaxAmount;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public allowAddLPList;
    mapping(address => uint256) private LPAmount;
    bool public swapAndLiquifyEnabled = true;
    bool public openTrade;
    uint256 public startTime;
    uint256[3] public distributeRates = [70, 20, 10];
    uint256 private currentTime;
    uint256 public proportion;
    uint8  _tax ;
    uint256  _currentSupply;
    address public _bnbPool;
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    //compound
    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }
    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;
    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;
    /// @notice A record of each accounts delegate
    mapping (address => address) public delegates;
    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);
    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    //0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 pancake
    //0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D uniswap
    // fireSeed ,fireSoul, MinistryOfFinance, CityNode, Warp
    constructor(address tokenOwner) ERC20("Fire Dao Token", "FDT") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());
        _approve(address(this), address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D), 10**34);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        _bnbPool = _uniswapV2Pair;
        _tokenOwner = tokenOwner;
        excludeFromFees(tokenOwner, true);
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        whiteListOfAddLP(tokenOwner, true);
        whiteListOfAddLP(owner(), true);
        WETH = IERC20(_uniswapV2Router.WETH());
        pair = IERC20(_uniswapV2Pair);
        uint256 total = 10**28;
        swapTokensAtAmount = 5 * 10**19;
        _mint(tokenOwner, total);
        _addDelegates(tokenOwner, safe96(total,"erc20: vote amount underflows"));
        _currentSupply = total;
        currentTime = block.timestamp;
        _tax = 5;
        setProportion(5);
    }

    receive() external payable {}

    function currentSupply() public view virtual returns (uint256) {
        return _currentSupply;
    }
    //onlyOwner
    function setProportion(uint256 _proportion) public onlyOwner{
        proportion = _proportion;
    }
    function setCityNode(address _cityNode) public onlyOwner{
        cityNode = _cityNode;
    }
    function whiteListOfAddLP(address usr, bool enable) public onlyOwner {
        allowAddLPList[usr] = enable;
    }
    function setTax(uint8 tax) public onlyOwner {
        require(tax <=5 , 'tax too big');
        _tax = tax;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function rescueToken(address tokenAddress, uint256 tokens)
    public
    onlyOwner
    returns (bool success)
    {
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function feewhiteList(address[] calldata accounts, bool excluded) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }
    function lpWhiteList(address[] calldata accounts, bool status) public onlyOwner{
        for(uint256 i = 0; i<accounts.length; i++){
            allowAddLPList[accounts[i]] =  status;
        }
    }

     function setSwapTokensAtAmount(uint256 _swapTokensAtAmount) public onlyOwner {
        swapTokensAtAmount = _swapTokensAtAmount;
    }
	
	function changeSwapWarp(GetWarp _warp) public onlyOwner {
        warp = _warp;
    }
    function setFireSeed(address _fireSeed) public onlyOwner{
        fireSeed = _fireSeed;
    }
    function setOpenTrade(bool _enabled) public onlyOwner{
        openTrade = _enabled;
    }
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }
    function setfireSoul(address _fireSoul) public onlyOwner {
        fireSoul = _fireSoul;
    }

    function setMinistryOfFinance(address _TreasuryDistributionContract ) public onlyOwner{
        TreasuryDistributionContract = _TreasuryDistributionContract;
    }
    //main
    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }
    
    function burn(uint256 burnAmount) external {
        _burn(msg.sender, burnAmount);
    }
    


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount>0);
        uint96 amount96 = safe96(amount,"");

		if(from == address(this) || to == address(this)){
            super._transfer(from, to, amount);
            return;
        }
          bool takeFee  = !swapping;
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }else{
            takeFee = true;
            }
        if (takeFee) {
                super._transfer(from, address(this), amount.div(100).mul(_tax));//fee 5%
                amount = amount.div(100).mul(100-_tax);//95%
            }
        
           if(balanceOf(address(this)) > 0 && block.timestamp >= currentTime && startTime != 0){
            if (
                !swapping &&
                _tokenOwner != from &&
                _tokenOwner != to &&
                from != uniswapV2Pair &&
                swapAndLiquifyEnabled
            ) {
                swapping = true;
                currentTime = block.timestamp;//更新时间
                uint256 tokenAmount = balanceOf(address(this));
                swapAndLiquifyV3(tokenAmount);
                swapping = false;
            }
        }
     
        if(from == uniswapV2Pair || to == uniswapV2Pair){
            require(openTrade ||  allowAddLPList[from] && to == uniswapV2Pair);
            if(WETH.balanceOf(address(this))>0){
            _splitOtherTokenSecond(WETH.balanceOf(address(this))/10*proportion);
            if(from != uniswapV2Pair){
                if(IcityNode(cityNode).checkIsCityNode(to, WETH.balanceOf(address(this))/10*(10-proportion))){
                WETH.transfer(cityNode, WETH.balanceOf(address(this))/10*(10-proportion));
                }else{
                WETH.transfer(TreasuryDistributionContract, WETH.balanceOf(address(this))/10*(10-proportion));
                ITreasuryDistributionContract(TreasuryDistributionContract).setSourceOfIncome(1,1,WETH.balanceOf(address(this))/10*(10-proportion));
                }
            }else if(to != uniswapV2Pair){
                if(IcityNode(cityNode).checkIsCityNode(from, WETH.balanceOf(address(this))/10*(10-proportion))){
                WETH.transfer(cityNode, WETH.balanceOf(address(this))/10*(10-proportion));
                }else{
                WETH.transfer(TreasuryDistributionContract, WETH.balanceOf(address(this))/10*(10-proportion));
                ITreasuryDistributionContract(TreasuryDistributionContract).setSourceOfIncome(1, 1,WETH.balanceOf(address(this))/10*(10-proportion));
                }
            }
        }
        }else{
               if(WETH.balanceOf(address(this))>0){
                _splitOtherTokenSecond(WETH.balanceOf(address(this))/10*proportion);
                if(IcityNode(cityNode).checkIsCityNode(from, WETH.balanceOf(address(this))/10*(10-proportion))){
                WETH.transfer(cityNode, WETH.balanceOf(address(this))/10*(10-proportion));
                }else{
                WETH.transfer(TreasuryDistributionContract, WETH.balanceOf(address(this))/10*(10-proportion));
                ITreasuryDistributionContract(TreasuryDistributionContract).setSourceOfIncome(1,1,WETH.balanceOf(address(this))/10*(10-proportion));
                }
            }
        }

        if(startTime == 0 && balanceOf(uniswapV2Pair) == 0 && to == uniswapV2Pair){
            startTime = block.timestamp;
        }
      
         super._transfer(from, to, amount);
         _moveDelegates(from, to, amount96);
    }
     

    function swapTokensForOther(uint256 tokenAmount) private {
		address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(warp),
            block.timestamp
        );
        warp.withdraw();
    }

     function swapAndLiquifyV3(uint256 contractTokenBalance) public {
        swapTokensForOther(contractTokenBalance);
    }

    function _splitOtherTokenSecond(uint256 thisAmount) internal {
	    address[] memory user = new address[](3);
        user[0] = IFireSeed(fireSeed).upclass(msg.sender);
        user[1] = IFireSeed(fireSeed).upclass(user[0]);
        user[2] = IFireSeed(fireSeed).upclass(user[1]);
        if(user[1] == address(0) || user[2] == address(0)){
        }else if(IFireSoul(fireSoul).checkFID(msg.sender) && 
                    IFireSoul(fireSoul).checkFID(user[0]) &&
                    IFireSoul(fireSoul).checkFID(user[1]) &&
                    IFireSoul(fireSoul).checkFID(user[2])  )
                     {
                    for(uint256 i = 0; i < distributeRates.length; i++){
                        WETH.transfer(user[i], thisAmount.mul(distributeRates[i]).div(100));
                        }
                     }else{
                        uint total = 0;
                    for(uint256 i = 0; i < distributeRates.length; i++){
                         WETH.transfer(TreasuryDistributionContract,thisAmount.mul(distributeRates[i]).div(100));
                         total += thisAmount.mul(distributeRates[i]).div(100);
                    }
                    ITreasuryDistributionContract(TreasuryDistributionContract).setSourceOfIncome(1,1, total);
        }
    }

//compound 
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, "Comp::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }


function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }


    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = safe96(balanceOf(delegator),"");
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }


    function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "Comp::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "Comp::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }


   function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "Comp::_writeCheckpoint: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }
    function _addDelegates(address dstRep, uint96 amount) internal {
          
        uint32 dstRepNum = numCheckpoints[dstRep];
        uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
        uint96 dstRepNew = add96(dstRepOld, amount, "vote: vote amount overflows");
        _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
        
    }
   

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }
}