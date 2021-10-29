const SkillMeToken = artifacts.require("SkillMeToken");
const AuctionFactory = artifacts.require("./AuctionFactory.sol");
const Auction = artifacts.require("./Auction.sol");

contract("AuctionFactory", function (accounts) {
    let tokenInstance, auctionFactoryInstance;
    let fromAccount = accounts[2];
    let toAccount = accounts[3];
    let spendingAccount = accounts[4];
    let auctionContract, auctionContract2, auctionInstance, auctionInstance2;
    let blockNumber, startBlock, endBlock, endBlock2;

    // This is to check that the token contract is deployed with the rigth set of value
    // since they are hard coded and initialized upon deployment
    it(" ... check token contract initialization values", function () {
        return SkillMeToken.deployed()
            .then(function (instance) {
                tokenInstance = instance;
                return tokenInstance.name();
            })
            .then(function (name) {
                assert.equal(name, "SkillMeToken", "contract has wrong name");
                return tokenInstance.symbol();
            })
            .then(function (symbol) {
                assert.equal(symbol, "SMT", "contract has wrong symbol");
                return tokenInstance.decimals();
            })
            .then(function (decimals) {
                assert.equal(decimals, 18, "contract has wrong decimals");
            });
    });

    // This carefully checks the token contract has the right amount of total supply after
    // it has been deployed.
    it(" ... allocate totalSupply at deployment", function () {
        return SkillMeToken.deployed()
            .then(function (instance) {
                tokenInstance = instance;
                return tokenInstance.totalSupply();
            })
            .then(function (totalSupply) {
                const val = totalSupply.toString();
                assert.equal(val, "1000000", "the total supply of 1,000,000");

                return tokenInstance.balanceOf(accounts[0]);
            })
            .then(function (adminBalance) {
                assert.equal(
                    adminBalance.toString(),
                    1000000,
                    "allocation is initialised to the admin account"
                );
            });
    });

    // The transfer function is checked to assert that it cannot transfer more than it has,
    // and that it transfers the right ammount and returns true if successful.
    it(" ... transfer(_to, -val): transfers token ownership", function () {
        return SkillMeToken.deployed()
            .then(function (instance) {
                tokenInstance = instance;
                // Test `require` statement first by transferring something larger than the sender's balance
                return tokenInstance.transfer.call(
                    accounts[1],
                    "999999999"
                );
            })
            .then(assert.fail)
            .catch(function (error) {
                assert(error.message, "error message");
                return tokenInstance.transfer.call(
                    accounts[1],
                    "250",
                    {
                        from: accounts[0],
                    }
                );
            })
            .then(function (success) {
                assert.equal(success, true, "This should return true");
                return tokenInstance.transfer(accounts[1], "250", {
                    from: accounts[0],
                });
            })
            .then(function (receipt) {
                assert.equal(receipt.logs.length, 1, "It triggers a 'Transfer' event");
                assert.equal(
                    receipt.logs[0].event,
                    "Transfer",
                    'should emit the "Transfer" event'
                );
                assert.equal(
                    receipt.logs[0].args.from,
                    accounts[0],
                    "should log the account the tokens were transferred from"
                );
                assert.equal(
                    receipt.logs[0].args.to,
                    accounts[1],
                    "should logs the account the tokens are transferred to"
                );
                assert.equal(
                    receipt.logs[0].args.value,
                    "250",
                    "should logs the transfer amount"
                );
                return tokenInstance.balanceOf(accounts[1]);
            })
            .then(function (balance) {
                assert.equal(
                    balance.toString(),
                    "250",
                    "should add the amount to the receiving account"
                );
                return tokenInstance.balanceOf(accounts[0]);
            })
            .then(function (balance) {
                assert.equal(
                    balance.toString(),
                    "999750",
                    "should deducts the amount from the sending account"
                );
            });
    });

    // This is to show that the right spender has the given permission to spend the stated amount
    it(" ... approves(_from, _spender, _val): approves tokens for delegated transfer", function () {
        return SkillMeToken.deployed()
            .then(function (instance) {
                tokenInstance = instance;
                return tokenInstance.approve.call(accounts[1], 100);
            })
            .then(function (success) {
                assert.equal(success, true, "should returns true");
                return tokenInstance.approve(accounts[1], 100, { from: accounts[0] });
            })
            .then(function (receipt) {
                assert.equal(receipt.logs.length, 1, "should triggers an event");
                assert.equal(
                    receipt.logs[0].event,
                    "Approval",
                    'should be the "Approval" event'
                );
                assert.equal(
                    receipt.logs[0].args.owner,
                    accounts[0],
                    " should log the account the tokens are authorized by"
                );
                assert.equal(
                    receipt.logs[0].args.spender,
                    accounts[1],
                    "should logs the account the tokens are authorized to"
                );
                assert.equal(
                    receipt.logs[0].args.value,
                    100,
                    " should logs the transfer amount"
                );
                return tokenInstance.allowance(accounts[0], accounts[1]);
            })
            .then(function (allowance) {
                assert.equal(
                    allowance.toNumber(),
                    100,
                    "should stores the allowance for delegated trasnfer"
                );
            });
    });

    // This test for the delegating Token transfer between accounts.
    it(" ... transferFrom(): handles delegated token transfers", function () {
        return SkillMeToken.deployed()
            .then(function (instance) {
                tokenInstance = instance;
                fromAccount = accounts[2];
                toAccount = accounts[3];
                spendingAccount = accounts[4];
                // Transfer some tokens to fromAccount
                return tokenInstance.transfer(fromAccount, 100, { from: accounts[0] });
            })
            .then(function (receipt) {
                // Approve spendingAccount to spend 10 tokens form fromAccount
                return tokenInstance.approve(spendingAccount, 10, {
                    from: fromAccount,
                });
            })
            .then(function (receipt) {
                // Try transferring something larger than the sender's balance
                return tokenInstance.transferFrom(fromAccount, toAccount, 9999, {
                    from: spendingAccount,
                });
            })
            .then(assert.fail)
            .catch(function (error) {
                assert(
                    error.message.indexOf("revert") >= 0,
                    "cannot transfer value larger than balance"
                );
                // Try transferring something larger than the approved amount
                return tokenInstance.transferFrom(fromAccount, toAccount, 20, {
                    from: spendingAccount,
                });
            })
            .then(assert.fail)
            .catch(function (error) {
                assert(
                    error.message,
                    "cannot transfer value larger than approved amount"
                );
                return tokenInstance.transferFrom.call(fromAccount, toAccount, 10, {
                    from: spendingAccount,
                });
            })
            .then(function (success) {
                assert.equal(success, true);
                return tokenInstance.transferFrom(fromAccount, toAccount, 10, {
                    from: spendingAccount,
                });
            })
            .then(function (receipt) {
                assert.equal(receipt.logs.length, 1, "triggers one event");
                assert.equal(
                    receipt.logs[0].event,
                    "Transfer",
                    'should be the "Transfer" event'
                );
                assert.equal(
                    receipt.logs[0].args.from,
                    fromAccount,
                    "logs the account the tokens are transferred from"
                );
                assert.equal(
                    receipt.logs[0].args.to,
                    toAccount,
                    "logs the account the tokens are transferred to"
                );
                assert.equal(
                    receipt.logs[0].args.value,
                    10,
                    "logs the transfer amount"
                );
                return tokenInstance.balanceOf(fromAccount);
            })
            .then(function (balance) {
                assert.equal(
                    balance.toNumber(),
                    90,
                    "deducts the amount from the sending account"
                );
                return tokenInstance.balanceOf(toAccount);
            })
            .then(function (balance) {
                assert.equal(
                    balance.toNumber(),
                    10,
                    "adds the amount from the receiving account"
                );
                return tokenInstance.allowance(fromAccount, spendingAccount);
            })
            .then(function (allowance) {
                assert.equal(
                    allowance.toNumber(),
                    0,
                    "deducts the amount from the allowance"
                );
            });
    });

    it(" ... create and initialization a non blind Auction", function () {
        return AuctionFactory.deployed()
            .then(async function (instance) {
                auctionFactoryInstance = instance;
                blockNumber = await web3.eth.getBlockNumber()
                startBlock = blockNumber;
                endBlock = startBlock + 4;
                endBlock2 = startBlock + 8;

                return auctionFactoryInstance.createAuction(startBlock, endBlock, false, { from: accounts[0] })
            })
            .then(async function (receipt) {

                assert.equal(receipt.logs.length, 1, "It triggers a 'AuctionCreated' event");

                assert.equal(
                    receipt.logs[0].event,
                    "AuctionCreated",
                    'should emit the "AuctionCreated" event'
                );

                auctionContract =
                    receipt.logs[0].args.auctionContract;

                assert.equal(
                    receipt.logs[0].args.owner,
                    accounts[0],
                    "should log the Auction owner account"
                );

                assert.equal(
                    receipt.logs[0].args.duration,
                    (endBlock - startBlock),
                    "should log the correct duration of the auction"
                );

                assert.equal(
                    receipt.logs[0].args.blindAuction,
                    false,
                    "should not be a blind auction"
                );

                auctionInstance = await Auction.at(auctionContract)
                tokenInstance.approve(auctionContract, 100, { from: accounts[1] });

                return auctionInstance.placeBid(1, { from: accounts[1] });
            })
            .then(function (success) {
                assert.equal(
                    success.receipt.status,
                    true,
                    "did not place a sucessfull bid"
                );

                return auctionInstance.getBidderFunds(accounts[1]);
            })
            .then(function (balance) {
                assert.equal(
                    balance.toString(),
                    "1",
                    "open bidding should have the right amount of funds"
                );
                return auctionInstance.getHighestBidderDetails();
            })
            .then(async function (values) {
                assert.equal(
                    values[1],
                    "1",
                    "open bidding should have some details"
                );
            })
    });

    it(" ... create and initialization a blind Auction", function () {
        return AuctionFactory.deployed()
            .then(async function (instance) {
                return auctionFactoryInstance.createAuction(startBlock, endBlock2, true, { from: accounts[2] })
            })
            .then(async function (receipt) {

                assert.equal(receipt.logs.length, 1, "It triggers a 'AuctionCreated' event");

                assert.equal(
                    receipt.logs[0].event,
                    "AuctionCreated",
                    'should emit the "AuctionCreated" event'
                );

                auctionContract2 =
                    receipt.logs[0].args.auctionContract;

                assert.equal(
                    receipt.logs[0].args.owner,
                    accounts[2],
                    "should log the Auction owner account"
                );

                assert.equal(
                    receipt.logs[0].args.duration,
                    (endBlock2 - startBlock),
                    "should log the correct duration of the auction"
                );

                assert.equal(
                    receipt.logs[0].args.blindAuction,
                    true,
                    "should not be a blind auction"
                );

                auctionInstance2 = await Auction.at(auctionContract2)
                tokenInstance.approve(auctionContract2, 100, { from: accounts[1] });

                return auctionInstance2.placeBid(1, { from: accounts[1] });
            })
            .then(async function (success) {
                assert.equal(
                    success.receipt.status,
                    true,
                    "did not place a blind bid sucessfully"
                );

                return auctionInstance2.getBidderFunds(accounts[1]);
            })
            .then(assert.fail)
            .catch(function (error) {
                assert(error.message, "error message");
                return auctionInstance2.getHighestBidderDetails.call();
            }).then(assert.fail)
            .catch(function (error) {
                assert(error.message, "error message");
            })
    });

    it(" ... withdraw bid at Auction End", async function () {
        const success = await auctionInstance.withdraw({ from: accounts[1] })

        assert.equal(
            success.receipt.status,
            true,
            "funds withdrawal failure"
        );
        let bal = await tokenInstance.balanceOf(auctionContract);

        assert.equal(
            bal.toString(),
            0,
            "auction contract funds not withdrawn"
        );
    })
});

