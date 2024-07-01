// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./LiquidityPool.sol";
import "./PriceManager.sol";
import "./Whitelist.sol";
import "./KYC.sol";

/**
 * @title TokenSwap
 * @dev Contract for swapping tokens, including support for KYC levels, whitelists and premium rates.
 */
contract TokenSwap is
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    //mapping swappable tokens
    mapping(address => bool) public swappableTokens;
    //mapping premium rates
    mapping(address => uint256) public premiumRates;
    //mapping swap balance for non kyc
    mapping(address => uint256) public noKycSwapBalances;

    /**
     *Trusted addresses(automated system interactions,
     *backend services that are trusted to bypass
     *kyc and whitelist checks)
     */
    mapping(address => bool) public trustedAddresses;

    LiquidityPool public liquidityPool;
    PriceManager public priceManager;
    Whitelist public whitelist;
    KYC public kycPermissions;
    address public premiumWallet; //state variable to store the premium wallet

    event TokensSwapped(
        address indexed user,
        address indexed fromToken,
        address indexed toToken,
        uint256 amountIn,
        uint256 amountOut
    );
    event PremiumRateUpdated(address indexed account, uint256 newRate);

    function initialize(
        address _liquidityPool,
        address _priceManager,
        address _whitelist,
        address _kycPermissions
    ) public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        liquidityPool = LiquidityPool(_liquidityPool);
        priceManager = PriceManager(_priceManager);
        whitelist = Whitelist(_whitelist);
        kycPermissions = KYC(_kycPermissions);
    }

    /**
     * @dev Make sure that the `giftPrice` variable in the `PriceManager` contract is updated
     * correctly to reflect the price of GIFT tokens in cents with 18 decimal places.
     * For example, if the price is 0.072 cents per milligram, the `giftPrice` should be
     * set to `72000000000000000` (0.072 * 1e18).
     */
    function setPremiumWallet(address _newPremiumWallet) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Only admin can set admin wallet"
        );
        premiumWallet = _newPremiumWallet;
    }

    // Function for setting premium per address
    function setPremiumRate(address _address, uint256 _rate) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Only admin can set premium rates"
        );
        require(_rate <= 5, "Rate must be 5% or less");
        premiumRates[_address] = _rate;
        emit PremiumRateUpdated(_address, _rate);
    }

    // Function for updating premium
    function updatePremiumRate(address _address, uint256 _newRate) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Only admin can update premium rates"
        );
        require(_newRate <= 5, "Rate must be 5% or less");
        premiumRates[_address] = _newRate;
        emit PremiumRateUpdated(_address, _newRate);
    }

    //Function to add trusted addresses
    function addTrustedAddress(address _address) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Only admin can add trusted addresses"
        );
        trustedAddresses[_address] = true;
    }

    //Function to remove trusted addresses
    function removeTrustedAddress(address _address) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Only admin can remove trusted addresses"
        );
        trustedAddresses[_address] = false;
    }

    function swapTokens(
        address _token,
        uint256 _amountIn,
        address _recipient
    ) external nonReentrant {
        require(_recipient == msg.sender, "Recipient must be the sender");
        require(swappableTokens[_token], "Token not swappable");
        if (!trustedAddresses[msg.sender]) {
            require(whitelist.isWhitelisted(msg.sender), "Not whitelisted");
            uint256 kycLevelId = kycPermissions.getKYCLevel(msg.sender);
            if (kycLevelId < kycPermissions.getKYCLevels().length) {
                // No KYC level set, use the noKycSwapBalances
                uint256 currentBalance = noKycSwapBalances[msg.sender];
                require(
                    currentBalance + _amountIn <= 1000 * 1e6,
                    "Swap amount exceeds lifetime limit for non-KYC users"
                );
                noKycSwapBalances[msg.sender] = currentBalance + _amountIn;
            } else {
                // KYC level set, use the normal KYC limit
                uint256 allowedSwapLimit = kycPermissions
                .getKYCLevels()[kycLevelId].swapLimit;
                require(
                    _amountIn <= allowedSwapLimit,
                    "Swap amount exceeds KYC limit"
                );
            }
        }
        IERC20Upgradeable(_token).safeTransferFrom(
            msg.sender,
            address(liquidityPool),
            _amountIn
        );

        //main swap calculations
        uint256 giftPrice = priceManager.giftPrice();
        uint256 amountOut = ((_amountIn * 10**12) / giftPrice) * 1e18;

        // Determine the fee percentage
        uint256 feePercentage = premiumRates[msg.sender] == 0
            ? 5
            : premiumRates[msg.sender]; // Default to 5% if no specific rate is set
        uint256 feeAmount = (amountOut * feePercentage) / 100; // Calculate the fee amount

        // Adjust the amountOut by subtracting the fee
        uint256 finalAmountOut = amountOut - feeAmount;

        // Check if there is enough liquidity before removing
        require(
            liquidityPool.liquidity(address(liquidityPool.giftToken())) >=
                finalAmountOut + feeAmount,
            "Insufficient liquidity"
        );

        // Remove liquidity from the pool
        liquidityPool.removeLiquidity(
            address(liquidityPool.giftToken()),
            finalAmountOut + feeAmount
        );

        // Transfer the GIFT tokens from the liquidity pool to the TokenSwap contract
        IERC20Upgradeable(liquidityPool.giftToken()).safeTransfer(
            address(this),
            finalAmountOut + feeAmount
        );

        // Transfer the final amount to the recipient
        IERC20Upgradeable(liquidityPool.giftToken()).safeTransfer(
            _recipient,
            finalAmountOut
        );

        // Send the fee to the premium wallet
        IERC20Upgradeable(liquidityPool.giftToken()).safeTransfer(
            premiumWallet,
            feeAmount
        );

        emit TokensSwapped(
            msg.sender,
            _token,
            liquidityPool.giftToken(),
            _amountIn,
            finalAmountOut
        );
    }

    function swapGiftToOtherTokens(
        address _token,
        uint256 _amountIn,
        address _recipient
    ) external nonReentrant {
        require(swappableTokens[_token], "Token not swappable");
        if (!trustedAddresses[msg.sender]) {
            require(whitelist.isWhitelisted(msg.sender), "Not whitelisted");
        }
        IERC20Upgradeable(liquidityPool.giftToken()).safeTransferFrom(
            msg.sender,
            address(liquidityPool),
            _amountIn
        );

        // main swap calculations
        uint256 giftPrice = priceManager.giftPrice();
        uint256 amountOut = (_amountIn * giftPrice) / 1e30;

        // Determine the fee percentage
        uint256 feePercentage = premiumRates[msg.sender] == 0
            ? 5
            : premiumRates[msg.sender]; // Default to 5% if no specific rate is set
        uint256 feeAmount = (amountOut * feePercentage) / 100; // Calculate the fee amount

        // Adjust the amountOut by subtracting the fee
        uint256 finalAmountOut = amountOut - feeAmount;
        if (!trustedAddresses[msg.sender]) {
            uint256 kycLevelId = kycPermissions.getKYCLevel(msg.sender);
            if (kycLevelId < kycPermissions.getKYCLevels().length) {
                // No KYC level set, use the noKycSwapBalances
                uint256 currentBalance = noKycSwapBalances[msg.sender];
                require(
                    currentBalance + _amountIn <= 1000 * 1e6,
                    "Swap amount exceeds lifetime limit for non-KYC users"
                );
                noKycSwapBalances[msg.sender] = currentBalance + _amountIn;
            } else {
                // KYC level set, use the normal KYC limit
                uint256 allowedSwapLimit = kycPermissions
                .getKYCLevels()[kycLevelId].swapLimit;
                require(
                    finalAmountOut <= allowedSwapLimit,
                    "Swap amount exceeds KYC limit"
                );
            }
        }
        // Check if there is enough liquidity before removing
        require(
            liquidityPool.liquidity(_token) >= finalAmountOut + feeAmount,
            "Insufficient liquidity"
        );

        // Remove liquidity from the pool
        liquidityPool.removeLiquidity(_token, finalAmountOut + feeAmount);

        // Transfer the swapped tokens from the liquidity pool to the TokenSwap contract
        IERC20Upgradeable(_token).safeTransfer(
            address(this),
            finalAmountOut + feeAmount
        );

        // Transfer the final amount to the recipient
        IERC20Upgradeable(_token).safeTransfer(_recipient, finalAmountOut);

        // Send the fee to the premium wallet
        IERC20Upgradeable(_token).safeTransfer(premiumWallet, feeAmount);

        emit TokensSwapped(
            msg.sender,
            liquidityPool.giftToken(),
            _token,
            _amountIn,
            finalAmountOut
        );
    }

    /**
     * @dev Swaps `_amountIn` of `_tokenIn` to GIFT and sends to `_recipient`.
     * Only callable by whitelisted addresses.
     * `_recipient` is the address to receive GIFT tokens.
     */

    function swapTokensforrecipient(
        address _token,
        uint256 _amountIn,
        address _recipient
    ) external nonReentrant {
        require(swappableTokens[_token], "Token not swappable");
        if (!trustedAddresses[msg.sender]) {
            require(whitelist.isWhitelisted(msg.sender), "Not whitelisted");

            uint256 kycLevelId = kycPermissions.getKYCLevel(msg.sender);
            if (kycLevelId < kycPermissions.getKYCLevels().length) {
                // No KYC level set, use the noKycSwapBalances
                uint256 currentBalance = noKycSwapBalances[msg.sender];
                require(
                    currentBalance + _amountIn <= 1000 * 1e6,
                    "Swap amount exceeds lifetime limit for non-KYC users"
                );
                noKycSwapBalances[msg.sender] = currentBalance + _amountIn;
            } else {
                // KYC level set, use the normal KYC limit
                uint256 allowedSwapLimit = kycPermissions
                .getKYCLevels()[kycLevelId].swapLimit;
                require(
                    _amountIn <= allowedSwapLimit,
                    "Swap amount exceeds KYC limit"
                );
            }
        }
        IERC20Upgradeable(_token).safeTransferFrom(
            msg.sender,
            address(liquidityPool),
            _amountIn
        );

        //main swap calculations
        uint256 giftPrice = priceManager.giftPrice();
        uint256 amountOut = ((_amountIn * 10**12) / giftPrice) * 1e18;

        // Determine the fee percentage
        uint256 feePercentage = premiumRates[msg.sender] == 0
            ? 5
            : premiumRates[msg.sender]; // Default to 5% if no specific rate is set
        uint256 feeAmount = (amountOut * feePercentage) / 100; // Calculate the fee amount

        // Adjust the amountOut by subtracting the fee
        uint256 finalAmountOut = amountOut - feeAmount;

        // Check if there is enough liquidity before removing
        require(
            liquidityPool.liquidity(address(liquidityPool.giftToken())) >=
                finalAmountOut + feeAmount,
            "Insufficient liquidity"
        );

        // Remove liquidity from the pool
        liquidityPool.removeLiquidity(
            address(liquidityPool.giftToken()),
            finalAmountOut + feeAmount
        );

        // Transfer the GIFT tokens from the liquidity pool to the TokenSwap contract
        IERC20Upgradeable(liquidityPool.giftToken()).safeTransfer(
            address(this),
            finalAmountOut + feeAmount
        );

        // Transfer the final amount to the recipient
        IERC20Upgradeable(liquidityPool.giftToken()).safeTransfer(
            _recipient,
            finalAmountOut
        );

        // Send the fee to the premium wallet
        IERC20Upgradeable(liquidityPool.giftToken()).safeTransfer(
            premiumWallet,
            feeAmount
        );

        emit TokensSwapped(
            msg.sender,
            _token,
            liquidityPool.giftToken(),
            _amountIn,
            finalAmountOut
        );
    }

    function swapGift(
        address _token,
        uint256 _amountIn,
        address _recipient
    ) external nonReentrant {
        require(_recipient == msg.sender, "Recipient must be the sender");
        require(swappableTokens[_token], "Token not swappable");
        if (!trustedAddresses[msg.sender]) {
            require(whitelist.isWhitelisted(msg.sender), "Not whitelisted");
        }
        IERC20Upgradeable(liquidityPool.giftToken()).safeTransferFrom(
            msg.sender,
            address(liquidityPool),
            _amountIn
        );

        // main swap calculations
        uint256 giftPrice = priceManager.giftPrice();
        uint256 amountOut = (_amountIn * giftPrice) / 1e30;

        // Determine the fee percentage
        uint256 feePercentage = premiumRates[msg.sender] == 0
            ? 5
            : premiumRates[msg.sender]; // Default to 5% if no specific rate is set
        uint256 feeAmount = (amountOut * feePercentage) / 100; // Calculate the fee amount

        // Adjust the amountOut by subtracting the fee
        uint256 finalAmountOut = amountOut - feeAmount;

        if (!trustedAddresses[msg.sender]) {
            uint256 kycLevelId = kycPermissions.getKYCLevel(msg.sender);
            if (kycLevelId >= kycPermissions.getKYCLevels().length) {
                // No KYC level set, use the noKycSwapBalances
                uint256 currentBalance = noKycSwapBalances[msg.sender];
                require(
                    currentBalance + finalAmountOut <= 1000 * 1e6,
                    "Swap amount exceeds lifetime limit for non-KYC users"
                );
                noKycSwapBalances[msg.sender] = currentBalance + finalAmountOut;
            } else {
                // KYC level set, use the normal KYC limit
                uint256 allowedSwapLimit = kycPermissions
                .getKYCLevels()[kycLevelId].swapLimit;
                require(
                    finalAmountOut <= allowedSwapLimit,
                    "Swap amount exceeds KYC limit"
                );
            }
        }

        // Check if there is enough liquidity before removing
        require(
            liquidityPool.liquidity(_token) >= finalAmountOut + feeAmount,
            "Insufficient liquidity"
        );

        // Remove liquidity from the pool
        liquidityPool.removeLiquidity(_token, finalAmountOut + feeAmount);

        // Transfer the swapped tokens from the liquidity pool to the TokenSwap contract
        IERC20Upgradeable(_token).safeTransfer(
            address(this),
            finalAmountOut + feeAmount
        );

        // Transfer the final amount to the recipient
        IERC20Upgradeable(_token).safeTransfer(_recipient, finalAmountOut);

        // Send the fee to the premium wallet
        IERC20Upgradeable(_token).safeTransfer(premiumWallet, feeAmount);

        emit TokensSwapped(
            msg.sender,
            liquidityPool.giftToken(),
            _token,
            _amountIn,
            finalAmountOut
        );
    }

    function addSwappableToken(address _token) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not an admin");
        swappableTokens[_token] = true;
    }

    function removeSwappableToken(address _token) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not an admin");
        swappableTokens[_token] = false;
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

    // Function to update the LiquidityPool contract address. Restricted to admin.
    function setLiquidityPool(address _LiquidityPool) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not an admin");
        liquidityPool = LiquidityPool(_LiquidityPool);
    }

    // Function to update the LiquidityPool contract address. Restricted to admin.
    function setKYC(address _KycPermissions) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not an admin");
        kycPermissions = KYC(_KycPermissions);
    }

    // Function to transfer the admin role to a new address. Restricted to the current admin.
    function transferAdminRole(address newAdmin) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Only admin can transfer admin role"
        );
        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
