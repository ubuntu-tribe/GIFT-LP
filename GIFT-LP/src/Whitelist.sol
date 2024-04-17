// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing OpenZeppelin's AccessControl for robust role-based access control.
import "@openzeppelin/contracts/access/AccessControl.sol";

// The Whitelist contract extends AccessControl to manage whitelisted addresses.
contract Whitelist is AccessControl {
    // Declaring a role for users who can modify the whitelist.
    bytes32 public constant WHITELISTER_ROLE = keccak256("WHITELISTER_ROLE");
    // Mapping to track which addresses are whitelisted.
    mapping(address => bool) public whitelistedAddresses;

    // Events for logging changes to the whitelist.
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    // Constructor that assigns the deploying address as the default admin.
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Function to add a new address with the ability to modify the whitelist.
    function addWhitelister(address _account) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only admin can add whitelisters");
        grantRole(WHITELISTER_ROLE, _account);
    }

    // Function to remove an address's ability to modify the whitelist.
    function removeWhitelister(address _account) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only admin can remove whitelisters");
        revokeRole(WHITELISTER_ROLE, _account);
    }

    // Function to add an address to the whitelist. Requires WHITELISTER_ROLE or DEFAULT_ADMIN_ROLE.
    function addToWhitelist(address _address) external {
        require(hasRole(WHITELISTER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only whitelisters or admin can add to whitelist");
        whitelistedAddresses[_address] = true;
        emit AddedToWhitelist(_address); // Emitting an event upon adding to the whitelist.
    }

    // Function to remove an address from the whitelist. Similar role requirements as addToWhitelist.
    function removeFromWhitelist(address _address) external {
        require(hasRole(WHITELISTER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only whitelisters or admin can remove from whitelist");
        whitelistedAddresses[_address] = false;
        emit RemovedFromWhitelist(_address); // Emitting an event upon removal from the whitelist.
    }

    // View function to check if an address is whitelisted.
    function isWhitelisted(address _address) external view returns (bool) {
        return whitelistedAddresses[_address];
    }
}
