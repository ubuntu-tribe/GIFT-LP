// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title KYC
 * @dev Contract for managing KYC (Know Your Customer) levels and assigning them to user addresses.
 */
contract KYC is Initializable, AccessControlUpgradeable {
    // Role identifier for KYC accountants who can assign KYC levels to user addresses
    bytes32 public constant KYC_ACCOUNTANT_ROLE = keccak256("KYC_ACCOUNTANT_ROLE");
    // Struct representing a KYC level with a name and swap limit
    struct KYCLevel {
        string name;
        uint256 swapLimit;
    }

    // Array to store all KYC levels
    KYCLevel[] public kycLevels;
    // Mapping to store the assigned KYC level ID for each user address
    mapping(address => uint256) public addressToKYCLevel;

    // Events emitted when KYC levels are added, modified, removed, or assigned to user addresses
    event KYCLevelAdded(uint256 indexed levelId, string name, uint256 swapLimit);
    event KYCLevelModified(uint256 indexed levelId, string name, uint256 swapLimit);
    event KYCLevelRemoved(uint256 indexed levelId);
    event KYCLevelAssigned(address indexed account, uint256 indexed levelId);

    /**
     * @dev Constructor function that grants the DEFAULT_ADMIN_ROLE to the contract deployer.
     */
    function initialize() public initializer {
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /**
    * @dev Grants the KYC_ACCOUNTANT_ROLE to an address.
    * @param _account The address to grant the KYC accountant role to.
    * Can only be called by accounts with the DEFAULT_ADMIN_ROLE.
    */
    function grantKYCAccountantRole(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(KYC_ACCOUNTANT_ROLE, _account);
    }

    /**
    * @dev Updates the address holding the KYC_ACCOUNTANT_ROLE.
    * @param _currentAccountant The current address holding the KYC accountant role.
    * @param _newAccountant The new address to grant the KYC accountant role to.
    * Can only be called by accounts with the DEFAULT_ADMIN_ROLE.
    */
    function updateKYCAccountantRole(address _currentAccountant, address _newAccountant) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(hasRole(KYC_ACCOUNTANT_ROLE, _currentAccountant), "Current address does not have KYC accountant role");
        revokeRole(KYC_ACCOUNTANT_ROLE, _currentAccountant);
        grantRole(KYC_ACCOUNTANT_ROLE, _newAccountant);
    }

    /**
     * @dev Adds a new KYC level with the given name and swap limit.
     * @param _name The name of the KYC level.
     * @param _swapLimit The swap limit associated with the KYC level.
     * Can only be called by accounts with the DEFAULT_ADMIN_ROLE.
     */
    function addKYCLevel(string memory _name, uint256 _swapLimit) external onlyRole(DEFAULT_ADMIN_ROLE) {
        kycLevels.push(KYCLevel(_name, _swapLimit));
        uint256 levelId = kycLevels.length - 1;
        emit KYCLevelAdded(levelId, _name, _swapLimit);
    }

    /**
     * @dev Modifies an existing KYC level with the given level ID, name, and swap limit.
     * @param _levelId The ID of the KYC level to modify.
     * @param _name The new name of the KYC level.
     * @param _swapLimit The new swap limit associated with the KYC level.
     * Can only be called by accounts with the DEFAULT_ADMIN_ROLE.
     */
    function modifyKYCLevel(uint256 _levelId, string memory _name, uint256 _swapLimit) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_levelId < kycLevels.length, "Invalid KYC level ID");
        kycLevels[_levelId].name = _name;
        kycLevels[_levelId].swapLimit = _swapLimit;
        emit KYCLevelModified(_levelId, _name, _swapLimit);
    }

    /**
     * @dev Removes an existing KYC level with the given level ID.
     * @param _levelId The ID of the KYC level to remove.
     * Can only be called by accounts with the DEFAULT_ADMIN_ROLE.
     */
    function removeKYCLevel(uint256 _levelId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_levelId < kycLevels.length, "Invalid KYC level ID");
        // Remove the KYC level from the array by shifting elements
        for (uint256 i = _levelId; i < kycLevels.length - 1; i++) {
            kycLevels[i] = kycLevels[i + 1];
        }
        kycLevels.pop();
        emit KYCLevelRemoved(_levelId);
    }

    /**
     * @dev Assigns a KYC level to a user address.
     * @param _account The address of the user to assign the KYC level to.
     * @param _levelId The ID of the KYC level to assign.
     * Can only be called by accounts with the KYC_ACCOUNTANT_ROLE.
     */
    function assignKYCLevel(address _account, uint256 _levelId) external onlyRole(KYC_ACCOUNTANT_ROLE) {
        require(_levelId < kycLevels.length, "Invalid KYC level ID");
        addressToKYCLevel[_account] = _levelId;
        emit KYCLevelAssigned(_account, _levelId);
    }

    /**
     * @dev Retrieves the assigned KYC level ID for a user address.
     * @param _account The address of the user to retrieve the KYC level for.
     * @return The ID of the assigned KYC level.
     * Can only be called by accounts with the DEFAULT_ADMIN_ROLE or KYC_ACCOUNTANT_ROLE.
     */

    function getKYCLevel(address _account) external view returns (uint256) {
        return addressToKYCLevel[_account];
    }

    /**
    * @dev Retrieves all KYC levels.
    * @return An array of KYCLevel structs representing all KYC levels.
    */
     function getKYCLevels() external view returns (KYCLevel[] memory) {
        return kycLevels;
    }

    function AdmingetKYCLevels() external view returns (KYCLevel[] memory) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not an admin");   
        return kycLevels;
    }
}
