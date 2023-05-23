// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File:@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol;

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


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

//File:contracts/struct/User.sol
pragma solidity ^0.8.0;

    struct User{
        uint PID;
        address account;
        string username;
        string information;
        uint joinTime;
    }
// File:contracts/interface/IFirePassport.sol
pragma solidity ^0.8.0;
interface IFirePassport {
    function usernameExists(string memory username) external returns(bool);
    function getUserCount() external view  returns(uint);
    function hasPID(address user) external view returns(bool);
    function getUserInfo(address user) external view returns(User memory);
    }



//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PrivateExchangePoolOG is Ownable,Pausable {

    struct whiteList{
        uint256 Pid;
        string name;
        address user;
    }

	ERC20 public fdt;
	bool public feeOn;
    bool public pidStatusForAdmin;
    bool public pidStatusForUser;
	address public weth;
    address public firePassport_;
	uint256 public salePrice;
    uint256 public adminLevelTwoMax;
    uint256 public adminLevelThreeMax;
    uint256 public maxTwo;
    uint256 public maxThree;
    uint256 public userBuyMax;
    uint256[] public inviteRate;
    uint256 public buyId;
    uint256 public totalDonate;
    uint256[] public validNumbers =
    [
        250000000000000000,
        500000000000000000,
        750000000000000000,
        1000000000000000000,
        1250000000000000000,
        1500000000000000000,
        1750000000000000000,
        2000000000000000000
    ];
    address[] public assignAddress;
    address[] public adminsLevelTwo;
    address[] public adminsLevelThree;
    uint256[] public rate;
    whiteList[] public ShowWhiteList;
    mapping(address => whiteList[]) public adminInviter;
    mapping(address => bool) public IsAdminLevelTwo;
    mapping(address => bool) public IsAdminLevelThree;
    mapping(address => bool) public WhiteListUser;
	mapping(address => uint256) public userTotalBuy;
    mapping(address => bool) public isRecommender;
    mapping(address => address) public recommender;
    mapping(address => address[]) public recommenderInfo;
    mapping(address => address[]) public setAdminsForTwo;
    mapping(address => address[]) public userSetAdminsForThree;
	AggregatorV3Interface internal priceFeed;
    event AllRecord(uint256 no,uint256 pid, string name,  address addr,uint256 ethAmount,uint256 usdtAmount,uint256 rate,uint256 fdtAmount,uint256 time);
    event AllWhiteList(uint256 pid, string name, address user);
    event AllRemoveWList(uint256 pid , string name, address user);
    event adminLevelTwo(uint256 pid , string name , address user);
    event reAdminLevelTwo(uint256 pid , string name , address user);
    event adminLevelThree(uint256 pid , string name , address user);
    event reAdminLevelThree(uint256 pid , string name , address user);

	/**
		* NetWork: Goerli
		* Aggregator: ETH/USD
		* Address:0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        * Arb goerli:0x62CAe0FA2da220f43a51F86Db2EDb36DcA9A5A08
        * Arb One:0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612
        * ETH Address :0x5D0C84105D44919Dee994d729f74f8EcD05c30fB
	*/
	constructor(ERC20 _fdt,  address _weth, address _firePassport) {
		priceFeed = AggregatorV3Interface(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);//arb one 
		// priceFeed = AggregatorV3Interface(0x62CAe0FA2da220f43a51F86Db2EDb36DcA9A5A08);//arb goerli
		fdt = _fdt;
		weth = _weth;
		salePrice = 10;
        adminLevelTwoMax = 10;
        adminLevelThreeMax = 10;
        maxTwo = 50;
        maxThree = 50;
		feeOn = true;
        userBuyMax = 2000000000000000000;
        firePassport_ = _firePassport;
	}

    function isValidNumber(uint256 number) private view returns (bool) {
        for (uint i = 0; i < validNumbers.length; i++) {
            if (validNumbers[i] == number) {
                return true;
            }
        }
        return false;
    }
	//onlyOwner
   function setAdminLevelThreeMax(uint256 _amount) public onlyOwner{
       adminLevelThreeMax = _amount;
   }
   function setAdminLevelTwoMax(uint256 _amount) public onlyOwner{
       adminLevelTwoMax = _amount;
   }
    function setWeth(address _weth) public onlyOwner {
        weth = _weth;
    }
    function setPidStatusForAdmin() public onlyOwner{
        pidStatusForAdmin = !pidStatusForAdmin;
    }
    function setPidStatusForUser() public onlyOwner {
        pidStatusForUser = !pidStatusForUser;
    }
	function setFeeStatus() public onlyOwner{
      	feeOn = !feeOn;
   	}
    function setUserBuyMax(uint256 _amount) public onlyOwner{
        userBuyMax = _amount;
    }
	function setFDTAddress(ERC20 _fdt) public onlyOwner {
		fdt = _fdt;
	}
	function setSalePrice(uint256 _salePrice) public onlyOwner {
        require(_salePrice >= 1 ,"The minimum set conversion ratio is 0.001");
		salePrice = _salePrice;
	}
     function setWhiteMaxForTwo(uint256 _max) public onlyOwner{
        maxTwo = _max;
    }
    function setWhiteMaxForThree(uint256 _max) public onlyOwner {
        maxThree = _max;
    }
    function checkAddrForAdminLevelTwo(address _user) internal view returns(bool) {
        for(uint256 i = 0 ; i < adminsLevelTwo.length; i ++){
            if(_user == adminsLevelTwo[i]){
                return false;
            }
        }
        return true;
    }
    function checkAddrForAdminLevelThree(address _user) internal view returns(bool){
        for(uint256 i=0; i<adminsLevelThree.length;i++){
            if(_user == adminsLevelThree[i]){
                return false;
            }
        }
        return true;
    }
    function setAdminLevelTwo(address[] memory _addr ) public onlyOwner{
        require(setAdminsForTwo[msg.sender].length < adminLevelTwoMax, "You cannot exceed the maximum limit");
        for(uint i = 0; i < _addr.length;i++){
            if(pidStatusForAdmin){
                require(IFirePassport(firePassport_).hasPID(_addr[i]),"address has no pid");
            }
            require(checkAddrForAdminLevelTwo(_addr[i]),"This address is already an administrator for level two");
            require(!isRecommender[_addr[i]],"This address has already been invited");
           if (recommender[_addr[i]] == address(0) &&  recommender[msg.sender] != _addr[i] && !isRecommender[_addr[i]]) {
             recommender[_addr[i]] = msg.sender;
             recommenderInfo[msg.sender].push(_addr[i]);
             isRecommender[_addr[i]] = true;
        }
            IsAdminLevelTwo[_addr[i]] = true;
            adminsLevelTwo.push(_addr[i]);
            setAdminsForTwo[msg.sender].push(_addr[i]);
            emit adminLevelTwo(getPid(_addr[i]), getName(_addr[i]), _addr[i]);
        }
    }
    function setAdminLevelThree(address[] memory _addr) public {
        require(IsAdminLevelTwo[msg.sender], "Address is not an  level two administrator");
        require(userSetAdminsForThree[msg.sender].length < adminLevelThreeMax, "You cannot exceed the maximum limit");

        for(uint256 i = 0; i < _addr.length; i++){
            if(pidStatusForAdmin){
                require(IFirePassport(firePassport_).hasPID(_addr[i]),"address has no pid");
            }
            require(checkAddrForAdminLevelThree(_addr[i]),"This address is already an administrator for level three");
            require(!isRecommender[_addr[i]],"This address has already been added");
           if (recommender[_addr[i]] == address(0) &&  recommender[msg.sender] != _addr[i] && !isRecommender[_addr[i]]) {
             recommender[_addr[i]] = msg.sender;
             recommenderInfo[msg.sender].push(_addr[i]);
             isRecommender[_addr[i]] = true;
        }
            IsAdminLevelThree[_addr[i]] = true;
            adminsLevelThree.push(_addr[i]);
            userSetAdminsForThree[msg.sender].push( _addr[i]);
            emit adminLevelThree(getPid(_addr[i]), getName(_addr[i]), _addr[i]);
        }

    }

    function removeAdminLevelTwo(address _addr) public onlyOwner{
        require(IsAdminLevelTwo[_addr], "Address is not an  level two administrator");
        uint _id;
        for(uint i = 0 ; i<adminsLevelTwo.length;i++){
            if(adminsLevelTwo[i] == _addr){
            _id = i;
            break; 
            }
        }
        adminsLevelTwo[_id] = adminsLevelTwo[adminsLevelTwo.length - 1];
        adminsLevelTwo.pop();
        IsAdminLevelTwo[_addr] = false;
        emit reAdminLevelTwo(getPid(_addr), getName(_addr), _addr);
    }

    function removeAdminLevelThree(address _addr) public {
        require(IsAdminLevelTwo[msg.sender] && IsAdminLevelThree[_addr],"you are not an level two administrator");
        uint _id;
        for(uint i = 0 ; i<adminsLevelThree.length;i++){
            if(adminsLevelThree[i] == _addr){
            _id = i;
            break; 
            }
        }
        adminsLevelThree[_id] = adminsLevelThree[adminsLevelThree.length - 1];
        adminsLevelThree.pop();
        IsAdminLevelThree[_addr] = false;
        emit reAdminLevelThree(getPid(_addr), getName(_addr), _addr);
    }

    function checkAddr(address _user, address _admin) internal view returns(bool) {
        for(uint256 i = 0 ; i < adminInviter[_admin].length; i ++){
            if(_user == adminInviter[_admin][i].user){
                return false;
            }
        }
        return true;
    }
  function getMax(address _user) internal view returns(uint256) {
        if(IsAdminLevelTwo[_user]){
            return maxTwo;
        }else if(IsAdminLevelThree[_user]) {
            return maxThree;
        }
        return 0;
    }
    function addWhiteList(address[] memory _addr) public{
        require(IsAdminLevelTwo[msg.sender] || IsAdminLevelThree[msg.sender],"you don't have permission");
        require(adminInviter[msg.sender].length <= getMax(msg.sender),"Exceeded the set total");
        for(uint i=0;i<_addr.length;i++){
            if(pidStatusForUser){
                require(IFirePassport(firePassport_).hasPID(_addr[i]),"address has no pid");
            }
        require(checkAddr(_addr[i], msg.sender)  && !isRecommender[_addr[i]],"This address has already been added");
           if (recommender[_addr[i]] == address(0) &&  recommender[msg.sender] != _addr[i] && !isRecommender[_addr[i]]) {
             recommender[_addr[i]] = msg.sender;
             recommenderInfo[msg.sender].push(_addr[i]);
             isRecommender[_addr[i]] = true;
        }
        whiteList memory wlist = whiteList({Pid:getPid(_addr[i]),name:getName(_addr[i]),user:_addr[i]});
        adminInviter[msg.sender].push(wlist);
        ShowWhiteList.push(wlist);
        WhiteListUser[_addr[i]] = true;
        emit AllWhiteList(getPid(_addr[i]),getName(_addr[i]),_addr[i]);
        }
    }
    
    function removeWhiteListBatch(address[] memory _addr) public {
        require(IsAdminLevelTwo[msg.sender] || IsAdminLevelThree[msg.sender],"you don't have permission");
        for(uint256 i = 0; i < _addr.length ; i++) {
            removeWhiteList(_addr[i]);
        }
    }
  

    function removeWhiteList(address _addr) internal{
        for(uint i = 0; i<adminInviter[msg.sender].length; i++){
            if(adminInviter[msg.sender][i].user == _addr){
                adminInviter[msg.sender][i] = adminInviter[msg.sender][adminInviter[msg.sender].length -1];
                adminInviter[msg.sender].pop();
                WhiteListUser[_addr] = false;
                removeWhiteListTotal(_addr);
                isRecommender[_addr] = false;
                emit AllRemoveWList(getPid(_addr),getName(_addr),_addr);
                return;
            }
        }
        require(false,"The address doesn't exist");
    }
    function removeWhiteListTotal(address _addr) internal {
        uint _id;
        for(uint i = 0; i<ShowWhiteList.length;i++){
            if(ShowWhiteList[i].user == _addr){
                _id = i;
                break;
            }
        }
        ShowWhiteList[_id] = ShowWhiteList[ShowWhiteList.length - 1];
        ShowWhiteList.pop();
    }
    function addAssignAddress(address[] memory _addr) public onlyOwner{
        for(uint i = 0 ; i < _addr.length; i++) {
            assignAddress.push(_addr[i]);
        }
    }
    function addRate(uint256[] memory _rate) public onlyOwner{
        require(getRate() <= 100,"The rate must be within one hundred");
        for(uint i = 0 ; i< _rate.length ;i++){
            rate.push(_rate[i]);
        }
    }
    function setAssignAddress(uint256 _id, address _addr) public onlyOwner{
        require(_id < assignAddress.length, "The address doesn't exist");
        assignAddress[_id] = _addr;
    }
    function setRate(uint256 _id, uint256 _rate) public onlyOwner{
        require(_id < rate.length,"The rate doesn't exist");
        rate[_id] = _rate;
    }
    function addInviteRate(uint256[] memory _rate) public onlyOwner{
        require(getRate() <= 100,"The rate must be within one hundred");
        require(_rate.length == 2 || inviteRate.length == 2 , "input error");
        for(uint256 i = 0; i < _rate.length; i++) {
            inviteRate.push(_rate[i]);
        }
    }
    function setInviteRate(uint256 _id , uint256 _rate) public onlyOwner{
        inviteRate[_id] = _rate;
    }
    function removeAssiginAddress(address _addr) public onlyOwner{
        for(uint256 i = 0; i<assignAddress.length ; i++){
            if(assignAddress[i] == _addr) {
                assignAddress[i] = assignAddress[assignAddress.length - 1];
                assignAddress.pop();
                return;
            }
        }
        require(false, "The address you removed does not exist");
    }

    function removeRate(uint256 _id) public onlyOwner {
            rate[_id] = rate[rate.length - 1];
            rate.pop();
    }
    function getRate() public view returns(uint256){
        uint256 total;
        uint256 _inviteRate;
        for(uint i = 0; i<rate.length; i++){
        
            total+= rate[i];
        }
        for(uint i = 0 ; i< inviteRate.length ; i ++ ){
                _inviteRate += inviteRate[i];
        }
        return total + _inviteRate;
    }
    function withdraw(uint256 _amount) public onlyOwner{
        fdt.transfer(msg.sender, _amount);
    }
    function Claim(address tokenAddress, uint256 tokens)
    public
    onlyOwner
    returns (bool success)
    {
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function setValidNumbers(uint256 _id, uint256 _num) public onlyOwner {
        require( _id < validNumbers.length, "input error");
        validNumbers[_id] = _num;
    }
    function addValidNumbers(uint256 _num) public onlyOwner{
        validNumbers.push(_num);
    }
    function removeValidNumbers() public onlyOwner{
        validNumbers.pop();
    }

	function donate(uint256 fee) external payable whenNotPaused {
        
    require(WhiteListUser[msg.sender], "Not a whitelist user");
    require(getRate() == 100, "rate error");
        if(pidStatusForUser){
            require(IFirePassport(firePassport_).hasPID(msg.sender),"address has no pid");
        }
    uint256 fdtAmount = (fee * getLatesPrice()) / (10**5 * salePrice);
    uint256 usdtAmount = fee * getLatesPrice() / (10**8);
    address downAddr = recommender[msg.sender];
    address upAddr =  recommender[downAddr];

    require(fdtAmount <= getBalanceOfFDT(), "the contract FDT balance is not enough");
    require(userTotalBuy[msg.sender] + fee <= userBuyMax, "over limit");
 
    require(isValidNumber(fee), "invalid input");


    if (feeOn) {
        if (msg.value == 0) {
            for (uint256 i = 0; i < assignAddress.length; i++) {
                TransferHelper.safeTransferFrom(weth, msg.sender, assignAddress[i], fee * rate[i] / 100);
            }
            TransferHelper.safeTransferFrom(weth, msg.sender, downAddr, fee * inviteRate[0] / 100);
            TransferHelper.safeTransferFrom(weth, msg.sender, upAddr, fee * inviteRate[1] / 100);

        } else {
            require(msg.value == fee, "provide the correct amount of ETH");
            IWETH(weth).deposit{value:fee}();
            for (uint256 i = 0; i < assignAddress.length; i++) {
                IWETH(weth).transfer(assignAddress[i], fee * rate[i] / 100);
            }
            IWETH(weth).transfer(downAddr, fee * inviteRate[0] / 100);
            IWETH(weth).transfer(upAddr, fee * inviteRate[1] / 100);
        }
        fdt.transfer(msg.sender, fdtAmount);
        userTotalBuy[msg.sender] += fee;
        totalDonate += fee;
        emit AllRecord(buyId,getPid(msg.sender), getName(msg.sender), msg.sender, fee, usdtAmount, salePrice, fdtAmount, block.timestamp);
        buyId++;
    }
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
    function getName(address _user) public view returns(string memory){
        if(IFirePassport(firePassport_).hasPID(_user)){

        return IFirePassport(firePassport_).getUserInfo(_user).username;
        }
        return "anonymous";
    }
    function getPid(address _user) public view returns(uint) {
        if(IFirePassport(firePassport_).hasPID(_user)){
        return IFirePassport(firePassport_).getUserInfo(_user).PID;
        }
        return 0;
    }
	function getBalanceOfFDT() public view returns(uint256) {
		return fdt.balanceOf(address(this));
	}

    function getInviteRate() public view returns(uint256) {
        return inviteRate.length;
    }

    function getAdminWhiteListLength() public view returns(uint256) {
       return adminInviter[msg.sender].length;
    }
    function getWhiteListLength() public view returns(uint256) {
        return ShowWhiteList.length;
    }
    function getAssignAddresslength() public view returns(uint256) {
        return assignAddress.length;
    }
    function getAdminsLevelTwoLength() public view returns(uint256) {
        return adminsLevelTwo.length;
    }
      function getAdminsLevelThreeLength() public view returns(uint256) {
        return adminsLevelThree.length;
    }
    function getInviteLength() public view returns(uint256) {
        return recommenderInfo[msg.sender].length;
    }
    function getRateLength() public view returns(uint256){
        return rate.length;
    }
    function getfdtAmount(uint256 fee) public view returns(uint256) {
	return (fee*getLatesPrice()/10**5)/salePrice;
    }
    function getValue() public view returns(uint256) {
        return getBalanceOfFDT()*(salePrice/1000);
    }
    function getValidNumbers() public view returns(uint256) {
        return validNumbers.length;
    }
    function getUserSetAdminsLevelThree() public view returns(uint256) {
       return userSetAdminsForThree[msg.sender].length;
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

