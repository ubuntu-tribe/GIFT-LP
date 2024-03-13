// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Whitelist is Ownable {
    mapping(address => bool) public whitelistedAddresses;

    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    function addToWhitelist(address _address) external onlyOwner {
        whitelistedAddresses[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function removeFromWhitelist(address _address) external onlyOwner {
        whitelistedAddresses[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function isWhitelisted(address _address) external view returns (bool) {
        return whitelistedAddresses[_address];
    }
}