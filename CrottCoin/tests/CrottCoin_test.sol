// SPDX-License-Identifier: GPL-3.0

//pragma solidity >=0.4.22 <0.9.0;
pragma solidity ^0.8.20;

// This import is automatically injected by Remix
import "remix_tests.sol";

// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin
// import "remix_accounts.sol";
import "../contracts/CrottCoin.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract CrottCoinTest {
    CrottCoin crottCoin;
    address owner;
    address recipient = address(0x123);

    // Define events for logging
    //event LogExpectedTokens(uint256 expectedTokens);
    //event LogNewBalance(uint256 newBalance);

    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeAll() public {
        owner = msg.sender;
    }

    function beforeEach() public {
        // Deploy the CrottCoin contract before each test so that
        // all states are reset
        // 1 game point = 1 token initially
        crottCoin = new CrottCoin();
    }

    function checkInitialSupply() public {
        // Check initial supply
        uint256 expectedSupply = crottCoin.INITIAL_TOKEN_SUPPLY() *
            (10**crottCoin.decimals());
        Assert.equal(
            crottCoin.totalSupply(),
            expectedSupply,
            "Initial supply should match"
        );
    }

    function checkGetCurrentExchangeRateScaledInitially() public {
        // Check initial exchange rate
        uint256 expectedRateScaled = 1 * 1e6;
        Assert.equal(
            crottCoin.getCurrentExchangeRateScaled(),
            expectedRateScaled,
            "Initial exchange rate should match"
        );
    }

    function checkGetCurrentExchangeRateScaledAfterFirstThreshold() public {
        /**
         * First threshold is one third of total supply @1 CROT
         * (we add one to accomodate rounding issues)
         */
        uint256 gamePoints = crottCoin.INITIAL_TOKEN_SUPPLY() / 3 + 1;
        crottCoin.distributeTokens(recipient, gamePoints);

        // Now the exchange rate should change to 1/10
        uint256 expectedRateScaled = 1e6 / 10;
        uint256 actualRateScaled = crottCoin.getCurrentExchangeRateScaled();

        Assert.equal(
            actualRateScaled,
            expectedRateScaled,
            "Exchange rate after first threshold should match"
        );
    }

    function checkGetCurrentExchangeRateScaledAfterSecondThreshold() public {
        // We first reach the first threshold
        uint256 gamePoints = crottCoin.INITIAL_TOKEN_SUPPLY() / 3 + 1;
        crottCoin.distributeTokens(recipient, gamePoints);

        /**
         * The second threshold is (total supply)/6 TOKENS later.
         * But 1 point is now worth 1/10 token.
         * So we need 10 times more points to reach that threshold
         * (we add one to accomodate rounding issues)
         */
        gamePoints = 10 * (crottCoin.INITIAL_TOKEN_SUPPLY() / 6 + 1);
        crottCoin.distributeTokens(recipient, gamePoints);

        // Now the exchange rate should change to 1/100
        uint256 expectedRateScaled = 1e6 / 100;
        uint256 actualRateScaled = crottCoin.getCurrentExchangeRateScaled();

        Assert.equal(
            actualRateScaled,
            expectedRateScaled,
            "Exchange rate after second threshold should match"
        );
    }

    function checkGetCurrentExchangeRateScaledAfterThirdThreshold() public {
        // We first reach the first threshold
        uint256 gamePoints = crottCoin.INITIAL_TOKEN_SUPPLY() / 3 + 1;
        crottCoin.distributeTokens(recipient, gamePoints);

        // Then the second one
        gamePoints = 10 * (crottCoin.INITIAL_TOKEN_SUPPLY() / 6 + 1);
        crottCoin.distributeTokens(recipient, gamePoints);

        /**
         * The third threshold is (total supply) * 4 / 9 TOKENS later.
         * But 1 point is now worth 1/100 token.
         * So we need 100 times more points to reach that threshold
                  * (we add one to accomodate rounding issues)

         */
        gamePoints = 100 * (crottCoin.INITIAL_TOKEN_SUPPLY() * 4 / 9 + 1);
        crottCoin.distributeTokens(recipient, gamePoints);

        // Now the exchange rate should change to 1/10000
        uint256 expectedRateScaled = 1e6 / 10000;
        uint256 actualRateScaled = crottCoin.getCurrentExchangeRateScaled();

        Assert.equal(
            actualRateScaled,
            expectedRateScaled,
            "Exchange rate after third threshold should match"
        );
    }

    function checkDistributeTokensInitially() public {
        // Distribute 100 game points
        uint256 gamePoints = 100;
        // Exchange rate is scaled by 1e6 so 1 <=> 1e6
        uint256 expectedExchangeRateScaled = 1 *
            crottCoin.EXCHANGE_RATE_SCALE();
        uint256 initialBalance = crottCoin.balanceOf(recipient);

        // Call distributeTokens function
        crottCoin.distributeTokens(recipient, gamePoints);

        // Calculate expected token distribution
        uint256 expectedTokens = (gamePoints *
            expectedExchangeRateScaled *
            (10**crottCoin.decimals())) / crottCoin.EXCHANGE_RATE_SCALE();

        // Check recipient balance
        uint256 newBalance = crottCoin.balanceOf(recipient);
        Assert.equal(
            newBalance,
            initialBalance + expectedTokens,
            "Recipient should receive correct amount of tokens"
        );
    }

    function checkDistributeTokensAfterFirstThreshold() public {
        // We first reach the first threshold
        /**
         * First threshold is one third of total supply @1 CROT
         * (we add one to accomodate rounding issues)
         */
        uint256 gamePoints = crottCoin.INITIAL_TOKEN_SUPPLY() / 3 + 1;
        crottCoin.distributeTokens(recipient, gamePoints);

        // Now exchange rate is 1/10
        uint256 expectedExchangeRateScaled = crottCoin.EXCHANGE_RATE_SCALE() /
            10;
        gamePoints = 1;

        // Calculate expected token distribution
        uint256 expectedTokens = (gamePoints *
            expectedExchangeRateScaled *
            (10**crottCoin.decimals())) / crottCoin.EXCHANGE_RATE_SCALE();

        uint256 initialBalance = crottCoin.balanceOf(recipient);

        // Call distributeTokens function
        crottCoin.distributeTokens(recipient, gamePoints);

        // Check recipient balance
        uint256 newBalance = crottCoin.balanceOf(recipient);
        Assert.equal(
            newBalance,
            initialBalance + expectedTokens,
            "Recipient should receive correct amount of tokens after first threshold"
        );
    }

    function checkDistributeTokensAfterSecondThreshold() public {
        // We first reach the first threshold
        /**
         * First threshold is one third of total supply @1 CROT
         * (we add one to accomodate rounding issues)
         */
        uint256 gamePoints = crottCoin.INITIAL_TOKEN_SUPPLY() / 3 + 1;
        crottCoin.distributeTokens(recipient, gamePoints);

        // Then the second one
        gamePoints = 10 * (crottCoin.INITIAL_TOKEN_SUPPLY() / 6 + 1);
        crottCoin.distributeTokens(recipient, gamePoints);

        // Now exchange rate is 1/100
        uint256 expectedExchangeRateScaled = crottCoin.EXCHANGE_RATE_SCALE() /
            100;
        gamePoints = 1;

        // Calculate expected token distribution
        uint256 expectedTokens = (gamePoints *
            expectedExchangeRateScaled *
            (10**crottCoin.decimals())) / crottCoin.EXCHANGE_RATE_SCALE();

        uint256 initialBalance = crottCoin.balanceOf(recipient);

        // Call distributeTokens function
        crottCoin.distributeTokens(recipient, gamePoints);

        // Check recipient balance
        uint256 newBalance = crottCoin.balanceOf(recipient);
        Assert.equal(
            newBalance,
            initialBalance + expectedTokens,
            "Recipient should receive correct amount of tokens after second threshold"
        );
    }

    function checkDistributeTokensAfterThirdThreshold() public {
        // We first reach the first threshold
        /**
         * First threshold is one third of total supply @1 CROT
         * (we add one to accomodate rounding issues)
         */
        uint256 gamePoints = crottCoin.INITIAL_TOKEN_SUPPLY() / 3 + 1;
        crottCoin.distributeTokens(recipient, gamePoints);

        // Then the second one
        gamePoints = 10 * (crottCoin.INITIAL_TOKEN_SUPPLY() / 6 + 1);
        crottCoin.distributeTokens(recipient, gamePoints);

        // Then the third one
        gamePoints = 100 * (crottCoin.INITIAL_TOKEN_SUPPLY() * 4 / 9 + 1);
        crottCoin.distributeTokens(recipient, gamePoints);

        // Now exchange rate is 1/10000
        uint256 expectedExchangeRateScaled = crottCoin.EXCHANGE_RATE_SCALE() /
            10000;
        gamePoints = 1;

        // Calculate expected token distribution
        uint256 expectedTokens = (gamePoints *
            expectedExchangeRateScaled *
            (10**crottCoin.decimals())) / crottCoin.EXCHANGE_RATE_SCALE();

        uint256 initialBalance = crottCoin.balanceOf(recipient);

        // Call distributeTokens function
        crottCoin.distributeTokens(recipient, gamePoints);

        // Check recipient balance
        uint256 newBalance = crottCoin.balanceOf(recipient);
        Assert.equal(
            newBalance,
            initialBalance + expectedTokens,
            "Recipient should receive correct amount of tokens after third threshold"
        );
    }
}
