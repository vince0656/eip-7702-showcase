// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {NoETHAccount} from "@contracts/Example2-NoETHAccount/NoETHAccount.sol";
import {MockWETH} from "@test/mocks/MockWETH.sol";
import {Transactions} from "@contracts/Transactions.sol";
import {IWETH} from "@contracts/Example2-NoETHAccount/IWETH.sol";

contract NoETHAccountTest is Test {
    NoETHAccount public noEthAccount;
    MockWETH public weth;
    address public treasury;
    uint256 public constant MAX_WETH = 1 ether;

    function setUp() public {
        // Setup treasury with some ETH
        treasury = makeAddr("treasury");
        vm.deal(treasury, 10 ether);
        
        // Deploy WETH and NoETHAccount
        weth = new MockWETH();
        noEthAccount = new NoETHAccount(
            treasury,
            weth,
            MAX_WETH,
            false // Don't allow transactions with value
        );

        // Setup treasury with WETH
        vm.startPrank(treasury);
        weth.deposit{value: 5 ether}();
        weth.approve(address(noEthAccount), type(uint256).max);
        vm.stopPrank();
    }

    function test_RevertIf_ZeroTreasury() public {
        vm.expectRevert(NoETHAccount.ZeroAddress.selector);
        new NoETHAccount(
            address(0),
            weth,
            MAX_WETH,
            false
        );
    }

    function test_RevertIf_ZeroWETH() public {
        vm.expectRevert(NoETHAccount.ZeroAddress.selector);
        new NoETHAccount(
            treasury,
            IWETH(address(0)),
            MAX_WETH,
            false
        );
    }

    function test_RevertIf_ZeroMaxWETH() public {
        vm.expectRevert(NoETHAccount.ZeroBudget.selector);
        new NoETHAccount(
            treasury,
            weth,
            0,
            false
        );
    }

    function test_ExecuteOpsWithNoETH_SingleTransaction() public {
        // Create a target contract to call
        address target = makeAddr("target");
        vm.deal(target, 0);
        
        // Prepare transaction data
        Transactions.Transaction[] memory transactions = new Transactions.Transaction[](1);
        transactions[0] = Transactions.Transaction({
            target: target,
            value: 0,
            callData: ""
        });

        // Execute transaction
        noEthAccount.executeOpsWithNoETH(transactions);
        
        // Verify WETH was transferred and unwrapped
        assertEq(weth.balanceOf(treasury), 5 ether);
        assertEq(weth.balanceOf(address(noEthAccount)), 0);
        assertEq(address(noEthAccount).balance, 0); // All ETH should be returned
    }

    function test_RevertIf_TransactionWithValueNotAllowed() public {
        address target = makeAddr("target");
        
        Transactions.Transaction[] memory transactions = new Transactions.Transaction[](1);
        transactions[0] = Transactions.Transaction({
            target: target,
            value: 0.1 ether,
            callData: ""
        });

        vm.expectRevert(Transactions.MsgValueNotZero.selector);
        noEthAccount.executeOpsWithNoETH{value: 0.1 ether}(transactions);
    }

    function test_AllowTransactionsWithValue() public {
        // Deploy new contract that allows value transfers
        NoETHAccount valueAccount = new NoETHAccount(
            treasury,
            weth,
            MAX_WETH,
            true
        );

        // Setup approval
        vm.prank(treasury);
        weth.approve(address(valueAccount), type(uint256).max);

        address target = makeAddr("target");
        uint256 transferAmount = 0.1 ether;
        
        Transactions.Transaction[] memory transactions = new Transactions.Transaction[](1);
        transactions[0] = Transactions.Transaction({
            target: target,
            value: transferAmount,
            callData: ""
        });

        // Execute transaction
        valueAccount.executeOpsWithNoETH(transactions);
        
        // Verify target received ETH
        assertEq(target.balance, transferAmount);
    }

    function test_RevertIf_ReentrancyAttempted() public {
        // Create a malicious contract that attempts reentrancy
        MaliciousContract malicious = new MaliciousContract(noEthAccount);
        
        Transactions.Transaction[] memory transactions = new Transactions.Transaction[](1);
        transactions[0] = Transactions.Transaction({
            target: address(malicious),
            value: 0,
            callData: abi.encodeWithSignature("attack()")
        });

        vm.expectRevert(Transactions.FailedToExecuteTransaction.selector);
        noEthAccount.executeOpsWithNoETH(transactions);
    }
}

contract MaliciousContract {
    NoETHAccount public noEthAccount;
    
    constructor(NoETHAccount _noEthAccount) {
        noEthAccount = _noEthAccount;
    }
    
    function attack() external {
        Transactions.Transaction[] memory transactions = new Transactions.Transaction[](1);
        transactions[0] = Transactions.Transaction({
            target: msg.sender,
            value: 0,
            callData: ""
        });
        
        noEthAccount.executeOpsWithNoETH(transactions);
    }

    receive() external payable {}
}
