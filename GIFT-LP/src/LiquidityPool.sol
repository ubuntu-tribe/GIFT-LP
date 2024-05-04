// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

// Importing necessary OpenZeppelin contracts for security and utility functions.
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./PriceManager.sol";
import "./Whitelist.sol";

// Declaring the main contract, inheriting AccessControl for role management and ReentrancyGuard for security against reentrancy attacks.
contract LiquidityPool is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20; // Using SafeERC20 for safer token interactions.

    // Defining a structure for handling premium percentages and associated permissions.
    struct Premium {
        uint256 percentage;
        address permissionAddress;
    }

    // Token addresses and related state variables.
    address public giftToken;
    address public usdcToken;
    address public usdtToken;
    address[] public otherSwappableTokens; // Dynamic array to store additional swappable tokens.
    mapping(address => uint256) public liquidity; // Tracks liquidity amount for each token.
    mapping(address => uint256) public liquidityThresholds; // Stores minimum liquidity thresholds.
    uint256 public giftPrice; // Stores the current price of GIFT tokens.
    Premium[] public premiums; // Dynamic array to store premium structures.

    // Role identifiers for managing permissions.
    bytes32 public constant LIQUIDITY_PROVIDER_ROLE = keccak256("LIQUIDITY_PROVIDER_ROLE");
    bytes32 public constant PREMIUM_MANAGER_ROLE = keccak256("PREMIUM_MANAGER_ROLE");

    // External contracts for price management and whitelisting.
    PriceManager public priceManager;
    Whitelist public whitelist;

    // Event declarations for logging significant actions.
    event LiquidityAdded(address indexed provider, address indexed token, uint256 amount);
    event LiquidityRemoved(address indexed provider, address indexed token, uint256 amount);
    event GiftPriceChanged(uint256 newPrice);
    event StablecoinsWithdrawn(uint256 amount);
    event LiquidityThresholdAlert(address indexed token, uint256 threshold);

    // Constructor to initialize contract with required addresses.
    constructor(
        address _giftToken,
        address _usdcToken,
        address _usdtToken,
        address _priceManager,
        address _whitelist
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Granting the deployer admin rights.
        giftToken = _giftToken; // Setting GIFT token address.
        usdcToken = _usdcToken; // Setting USDC token address.
        usdtToken = _usdtToken; // Setting USDT token address.
        priceManager = PriceManager(_priceManager); // Initializing PriceManager contract.
        whitelist = Whitelist(_whitelist); // Initializing Whitelist contract.
    }

    // Function to add liquidity to the pool. Restricted to whitelisted liquidity providers.
    function addLiquidity(address _token, uint256 _amount) external nonReentrant {
        require(whitelist.isWhitelisted(msg.sender), "Not whitelisted"); // Check if sender is whitelisted.
        require(hasRole(LIQUIDITY_PROVIDER_ROLE, msg.sender), "Not a liquidity provider"); // Check if sender has liquidity provider role.
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount); // Safely transfer tokens from sender to contract.
        liquidity[_token] += _amount; // Update liquidity mapping.

        emit LiquidityAdded(msg.sender, _token, _amount); // Emit event for liquidity addition.
    }

    // Function to remove liquidity from the pool. Similar restrictions as addLiquidity.
    function removeLiquidity(address _token, uint256 _amount) external nonReentrant {
        require(whitelist.isWhitelisted(msg.sender), "Not whitelisted");
        require(hasRole(LIQUIDITY_PROVIDER_ROLE, msg.sender), "Not a liquidity provider");
        require(liquidity[_token] >= _amount, "Insufficient liquidity");

        IERC20(_token).safeTransfer(msg.sender, _amount); // Safely return tokens to the sender.
        liquidity[_token] -= _amount; // Update liquidity mapping.

        emit LiquidityRemoved(msg.sender, _token, _amount); // Emit event for liquidity removal.
        checkLiquidityThreshold(_token); // Check if liquidity falls below threshold.
    }
    
    // Function to transfer Ownership.
    function transferAdminRole(address newAdmin) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only admin can transfer admin role");
        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    
    }

    // Function to withdraw stablecoins from the liquidity pool. Restricted to admin.
    function withdrawStablecoins(uint256 _amount) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not an admin");
        require(liquidity[usdcToken] + liquidity[usdtToken] >= _amount, "Insufficient stablecoins");

        uint256 usdcAmount = _amount / 2; // Splitting the amount evenly between USDC and USDT.
        uint256 usdtAmount = _amount - usdcAmount; // Ensuring the full amount is accounted for.

        IERC20(usdcToken).safeTransfer(msg.sender, usdcAmount); // Withdraw USDC to the admin.
        IERC20(usdtToken).safeTransfer(msg.sender, usdtAmount); // Withdraw USDT to the admin.

        liquidity[usdcToken] -= usdcAmount; // Update liquidity mappings.
        liquidity[usdtToken] -= usdtAmount;

        emit StablecoinsWithdrawn(_amount); // Emit event for stablecoin withdrawal.
    }

    // Function to check if liquidity for a specific token falls below a set threshold.
    function checkLiquidityThreshold(address _token, uint256 _threshold) external {
        if (liquidity[_token] < _threshold) {
            emit LiquidityThresholdAlert(_token, _threshold); // Emit alert if threshold is breached.
        }
    }
    
    // Function to set a liquidity threshold for a specific token. Restricted to admin.
    function setLiquidityThreshold(address _token, uint256 _threshold) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not an admin");
        liquidityThresholds[_token] = _threshold; // Update threshold mapping.
    }


    // Internal utility function to check liquidity thresholds. Used by removeLiquidity.
    function checkLiquidityThreshold(address _token) internal {
        uint256 threshold = liquidityThresholds[_token]; // Retrieve set threshold.
        if (threshold > 0 && liquidity[_token] < threshold) {
            emit LiquidityThresholdAlert(_token, threshold); // Emit alert if threshold is breached.
        }
    }

    // Function to update the PriceManager contract address. Restricted to admin.
    function setPriceManager(address _priceManager) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not an admin");
        priceManager = PriceManager(_priceManager);
    }

    // Function to update the Whitelist contract address. Restricted to admin.
    function setWhitelist(address _whitelist) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not an admin");
        whitelist = Whitelist(_whitelist);
    }
}
