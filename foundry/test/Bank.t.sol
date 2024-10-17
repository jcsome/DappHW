// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Bank} from "src/Bank.sol";

contract BankTest is Test {
    Bank public bank;
    address public user = address(0x1234);

    function setUp() public {
        bank = new Bank();
    }

    function testDepositETH() public {
        // Define deposit amount 
        uint256 depositAmount = 1 ether;

        // Cheatcode: ensure sender has sufficient token
        vm.deal(user, depositAmount);

        // Deposit event
        vm.expectEmit(true, true, false, true);
        emit Bank.Deposit(user, depositAmount);

        // deposit
        vm.prank(user);
        bank.depositETH{value: depositAmount}();

        // assert token saved in bank equal to deposit amount 
        assertEq(bank.balanceOf(user), depositAmount);
    }
} 
