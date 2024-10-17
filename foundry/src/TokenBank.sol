// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract TokenBank {

    IERC20 public token;
    mapping (address => uint256) public balances;

    constructor (IERC20 _token) {
        token = _token;
    }

    // deposit tokens into token bank
    function deposit(uint256 amount) public {
        require(amount>0, "Amount must be greater than zero");
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");
        balances[msg.sender] += amount;
    }

    function withdraw(uint256 value) public {
        require(value<=balances[msg.sender], "Insufficient balance");
        bool success = token.transfer(msg.sender, value);
        require(success, "Token transfer failed");
        balances[msg.sender] -= value;
    } 
}