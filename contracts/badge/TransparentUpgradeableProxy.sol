// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
contract ProxyAdmin is Ownable {

    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }


    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    function upgradeAndCall(
        TransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

contract TransparentUpgradeableProxy is ERC1967Proxy {

    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _changeAdmin(admin_);
    }

    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}