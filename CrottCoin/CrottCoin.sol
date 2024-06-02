// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.2/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.2/contracts/access/Ownable.sol";

contract CrottCoin is ERC20, Ownable {
    // Define ithe total distributed tokens
    uint256 public totalDistributedTokens;

    // Solidity only handles integers so an exchange rate of 1E-3 will be scaled so that we
    // can have an integer.
    uint256 public constant EXCHANGE_RATE_SCALE = 1_000_000; // Scale to handle fractional rates

    // The total number of tokens is supplied right at the beginning
    uint256 public constant INITIAL_TOKEN_SUPPLY = 5_000_000;

    // Definition of the different exchange rates (points => CROT)
    uint256 public constant INITIAL_EXCHANGE_RATE = 1;
    uint256 public constant EXCHANGE_RATE_1 = 10;
    uint256 public constant EXCHANGE_RATE_2 = 100;
    uint256 public constant EXCHANGE_RATE_3 = 10_000;

    // Event emitted when tokens are distributed
    event TokensDistributed(
        address indexed recipient,
        uint256 gamePoints,
        uint256 tokens
    );

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor() ERC20("CrottCoin", "CROT") Ownable(msg.sender) {
        _mint(msg.sender, INITIAL_TOKEN_SUPPLY * (10**decimals()));
    }

    // Function to distribute tokens based on game points
    function distributeTokens(address recipient, uint256 gamePoints)
        external
        onlyOwner
    {
        // Calculate the number of tokens to distribute based on game points and current exchange rate
        // Please note : remember that getCurrentExchangeRate returns the actual exchange rate scaled by 1E6.
        // So we have to divide by the scale.
        uint256 tokensToDistribute = (gamePoints * (10**decimals()) * getCurrentExchangeRateScaled()) / EXCHANGE_RATE_SCALE;

        require(
            tokensToDistribute > 0,
            "Tokens to distribute must be greater than 0"
        );

        // Update total distributed tokens
        totalDistributedTokens += tokensToDistribute;

        // Transfer tokens to the recipient
        transfer(recipient, tokensToDistribute);

        // Emit an event
        emit TokensDistributed(recipient, gamePoints, tokensToDistribute);
    }

    /**
     * @dev Returns the current exchange rate based on total distributed tokens.
     * The exchange rate decreases over time depending on predefined thresholds.
     *
     * Exchange rates are scaled to handle fractional values by multiplying by 1e6 (EXCHANGE_RATE_SCALE).
     * - Below 1/3 of total supply distributed: 1 point = 1 token
     * - Between 1/3 and 1/2 of total supply distributed: 1 point = 0.1 tokens
     * - Between 1/2 and 17/18 of total supply distributed: 1 point = 0.01 tokens
     * - Beyond 17/18 of total supply distributed: 1 point = 0.0001 tokens
     *
     * @return The current exchange rate scaled by EXCHANGE_RATE_SCALE.
     */
    function getCurrentExchangeRateScaled() public view returns (uint256) {
        // Define exchange rate reduction thresholds and corresponding multipliers
        uint256[] memory thresholds = new uint256[](3);
        thresholds[0] = totalSupply() / 3;
        thresholds[1] = totalSupply() / 2;
        thresholds[2] = (totalSupply() * 17) / 18;

        uint256[] memory dividers = new uint256[](3);
        dividers[0] = INITIAL_EXCHANGE_RATE;
        dividers[1] = EXCHANGE_RATE_1;
        dividers[2] = EXCHANGE_RATE_2;
        // Iterate through thresholds to find the applicable exchange rate multiplier
        for (uint256 i = 0; i < thresholds.length; i++) {
            if (totalDistributedTokens < thresholds[i]) {
                return EXCHANGE_RATE_SCALE / dividers[i];
            }
        }

        // If total distributed tokens exceed all thresholds, apply a divider of 1000
        return EXCHANGE_RATE_SCALE / EXCHANGE_RATE_3;
    }
}
