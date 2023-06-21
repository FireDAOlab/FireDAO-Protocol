// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./lib/SafeMath.sol";
import "./interface/IUniswapV2Router02.sol";
import "./interface/IUniswapV2Pair.sol";
import "./interface/IUniswapV2Factory.sol";

contract flame is ERC20 , ERC20Permit, ERC20Votes,Ownable{
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    EnumerableSet.AddressSet private routers;
    EnumerableSet.AddressSet private pairs;

    address public feeReceive;
    address public  _tokenOwner;
    bool private swapping;
    bool public status;
    bool public swapAndLiquifyEnabled = true;
    bool public openTrade;
    uint256 public startTime;
    uint256 public startBlockNumber;
    uint256 private currentTime;
    uint8   public  _tax ;
    uint256 public StartBlock;
    uint256 _destroyMaxAmount;

    address[] public whiteListUser;
    address[] public allowAddLPListUser;
    address[] public blackListUser;

    mapping(address => bool) public _isExcludedFromFees;
    mapping(address => bool) public allowAddLPList;
    mapping(address => bool) public blackList;
    mapping(address => uint256) public LPAmount;
    mapping(address => address) public wethAddress;
    mapping(address => address) public routerAddress;
  
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    

    
    constructor(address tokenOwner,address[] memory _routers) ERC20("Flame", "FLM")ERC20Permit("FLM") {

    for(uint256 i = 0 ; i<_routers.length; i++){
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_routers[i]);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());
        _approve(address(this), address(_routers[i]), 10**34);
        wethAddress[_uniswapV2Pair] = _uniswapV2Router.WETH();
        routerAddress[_uniswapV2Pair] = _routers[i];
        routers.add(_routers[i]);
        pairs.add(_uniswapV2Pair);
       }
        _tokenOwner = tokenOwner;
        excludeFromFees(tokenOwner, true);
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        whiteListOfAddLP(tokenOwner, true);
        whiteListOfAddLP(owner(), true);
        feeReceive = owner();

        // WETH = IERC20(_uniswapV2Router.WETH());
        // pair = IERC20(_uniswapV2Pair);
        
        uint256 total = 100000000000 * 10**18;

        _mint(tokenOwner, total);
        currentTime = block.timestamp;
        _tax = 5;
    }

    receive() external payable {}
    function addRouter(address _router) public {
        require(routers.contains(_router) == true,"This router does not exist");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());
        wethAddress[_uniswapV2Pair] = _uniswapV2Router.WETH();
        routerAddress[_uniswapV2Pair] = _router;
        routers.add(_router);
        pairs.add(_uniswapV2Pair);
    }
    function removeRouter(address _router) external onlyOwner{
        require(routers.contains(_router) == true,"This router does not exist");
         IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .getPair(address(this), _uniswapV2Router.WETH());
        delete wethAddress[_uniswapV2Pair];
        delete routerAddress[_uniswapV2Pair];
        routers.remove(_router);
        pairs.remove(_uniswapV2Pair);
    }
    function containsInPair(address _element) public view returns (bool) {
        return pairs.contains(_element);
    }
    function getRouterLength() public view returns (uint256) {
        return routers.length();
    }
    function getPairLength() public view returns(uint256) {
        return pairs.length();
    }
    function routersList() external view returns(address[] memory) {
       return routers.values();
    }
    function pairsList() external view returns(address[] memory ){
        return pairs.values();
    }
    function _burn(address account, uint256 amount) internal virtual override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
       function _mint(address to, uint256 amount) internal  override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function setReceiver(address _user) public onlyOwner {
        feeReceive = _user;
    }
    function setstatus() public onlyOwner{
        status = !status;
    }
    function getwhiteListUserLength() public view returns(uint256) {
        return whiteListUser.length;
    }
    function getallowAddLPListUserLength() public view returns(uint256) {
        return allowAddLPListUser.length;
    } 
    function getblackListUserLenght() public view returns(uint256) {
        return blackListUser.length;
    }

    //onlyOwner
    function setStartBlock(uint256 _num) public onlyOwner{
        StartBlock = _num;
    }
    function setBlackListUser(address[] memory _to) public onlyOwner{
        for(uint256 i = 0 ;i < _to.length ; i++ ){
            checkRepaetBlackList(_to[i]);
            blackListUser.push(_to[i]);
            blackList[_to[i]] = true;
        }
    }
    function checkRepaetBlackList(address _addr ) internal view {
        for(uint256 i = 0; i <blackListUser.length;i++){
        if(_addr == blackListUser[i]) {
            require(false, "the address is repaet");
        }
        }

    }
    function deleteBlackListUser(address[] memory _to) public onlyOwner{
        for(uint256 i = 0 ; i< _to.length;i++){
            delete blackList[_to[i]];
            deleteBlackListUserList(_to[i]);
        }
    }
    function deleteBlackListUserList(address _to) internal {
        for(uint256 i = 0;  i< blackListUser.length ;i ++){
            if(_to == blackListUser[i]){
                blackListUser[i] = blackListUser[blackListUser.length-1];
                blackListUser.pop();
            }
        }
    }

    function whiteListOfAddLP(address usr, bool enable) public onlyOwner {
        allowAddLPList[usr] = enable;
    }

    function setTax(uint8 tax) public onlyOwner {
        require(tax <=5 , 'tax too big');
        _tax = tax;
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

    function feewhiteList(address[] calldata accounts) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            checkRepaetWhiteListUser(accounts[i]);
            _isExcludedFromFees[accounts[i]] = true;
            whiteListUser.push(accounts[i]);
        }
        emit ExcludeMultipleAccountsFromFees(accounts, true);
    }
    function checkRepaetWhiteListUser(address _addr) internal view{
        for(uint256 i =0 ; i < whiteListUser.length ;i++){
            if(_addr == whiteListUser[i]){
        require(false, "the address already added");

            }
        }
    } 
    function deletefeewhiteList(address[] calldata accounts) public onlyOwner{
        for (uint256 i = 0; i < accounts.length; i++) {
            require(_isExcludedFromFees[accounts[i]] ,"the address is not white list");
          delete  _isExcludedFromFees[accounts[i]] ;
            deletewList(accounts[i] );
        }
    }
    function deletewList(address _user) internal{
       for(uint256 i=0 ; i < whiteListUser.length ;i ++)  {
           if(_user == whiteListUser[i]){
               whiteListUser[i] = whiteListUser[whiteListUser.length -1];
               whiteListUser.pop();
           }
       }
    }
    function lpWhiteList(address[] calldata accounts) public onlyOwner{
        for(uint256 i = 0; i<accounts.length; i++){
            checkRepaetlpWhiteList(accounts[i]);
            allowAddLPList[accounts[i]] =  true;
            allowAddLPListUser.push(accounts[i]);
        }
    }  
    function checkRepaetlpWhiteList(address _addr) internal view{
        for(uint256 i = 0 ; i< allowAddLPListUser.length ; i++){
            if(_addr == allowAddLPListUser[i]){
                require(false,"the address is repaet");
            }
        }
    }
    function deleteLpwhiteList(address[] calldata accounts) public onlyOwner{
        for (uint256 i = 0; i < accounts.length; i++) {
          delete allowAddLPList[accounts[i]]  ;
            deleteLpwList(accounts[i]);
        }
    }
    function deleteLpwList(address _user) internal{
       for(uint256 i=0 ; i < allowAddLPListUser.length ;i ++)  {
           if(_user == allowAddLPListUser[i]){
               allowAddLPListUser[i] = allowAddLPListUser[allowAddLPListUser.length -1];
               allowAddLPListUser.pop();
           }
       }
    }
    function setOpenTrade(bool _enabled) public onlyOwner{
        openTrade = _enabled;
    }
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }
 
  
    //main
    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }
    
    function burn(uint256 burnAmount) external {
        _burn(msg.sender, burnAmount);
    }
    
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Votes) {
        
        super._afterTokenTransfer(from, to, amount);
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!status , "the contract is pause");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount>0);
        address _pair;

		if(from == address(this) || to == address(this)){
            super._transfer(from, to, amount);
            return;
        }

        if(containsInPair(from)) {
            _pair = from;
        }else if(containsInPair(to)){
            _pair = to;
        }

        bool takeFee  = !swapping;

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }else{
            takeFee = true;
        }
        
           if(balanceOf(address(this)) > 0 && block.timestamp >= currentTime && startTime != 0){
            if (
                !swapping &&
                _tokenOwner != from &&
                _tokenOwner != to &&
                from != _pair &&
                swapAndLiquifyEnabled
            ) {
                swapping = true;
                currentTime = block.timestamp;//更新时间
                uint256 tokenAmount = balanceOf(address(this));
                swapAndLiquifyV3(tokenAmount,routerAddress[_pair]);
                swapping = false;
            }
        }

         if(startTime == 0 && balanceOf(_pair) == 0 && to == _pair){
            startTime = block.timestamp;
            startBlockNumber = block.number;
        }
     
        if(containsInPair(from) || containsInPair(to)){
            require(openTrade ||  allowAddLPList[from]);

            if (takeFee) {
                super._transfer(from, address(this), amount.div(100).mul(_tax));//fee 5%
                amount = amount.div(100).mul(100-_tax);//95%
            }
            if(containsInPair(from)){
                
                if(block.number < startBlockNumber + StartBlock){
                    _burn(from,amount);
                }
                if(IERC20(wethAddress[from]).balanceOf(address(this)) > 0){
                uint256  balanceWETH =  IERC20(wethAddress[from]).balanceOf(address(this));
                IERC20(wethAddress[from]).transfer(feeReceive, balanceWETH);
            }
            }else if(containsInPair(to)){
                uint256  balanceWETH =  IERC20(wethAddress[to]).balanceOf(address(this));
                if(IERC20(wethAddress[to]).balanceOf(address(this)) > 0){
                IERC20(wethAddress[to]).transfer(feeReceive, balanceWETH);
            }
        }         
    }
         super._transfer(from, to, amount);

}

    function swapTokensForOther(uint256 tokenAmount,address router) private {
		address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = IUniswapV2Router02(router).WETH();
        IUniswapV2Router02(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

     function swapAndLiquifyV3(uint256 contractTokenBalance,address router) public {
        swapTokensForOther(contractTokenBalance,router);
    }

}