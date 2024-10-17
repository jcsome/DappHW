// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract BaseERC20 is IERC20{
    // Public state variables
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    // Mapping for balances and allowances
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    // Events for Transfer and Approval
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        // Setting token name, symbol, decimals, and total supply
        name = "BaseERC20";
        symbol = "BERC20";
        decimals = 18;
        totalSupply = 100000000 * (10 ** uint256(decimals));  // 100,000,000 tokens with 18 decimals

        // Assign the total supply to the contract deployer (owner)
        balances[msg.sender] = totalSupply;
    }

    // Function to check balance of a specific address
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    // Function to transfer tokens from the caller to another address
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "ERC20: transfer amount exceeds balance");

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // Function to transfer tokens on behalf of another address (using allowance)
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value, "ERC20: transfer amount exceeds balance");
        require(allowances[_from][msg.sender] >= _value, "ERC20: cant transfer balance to own");

        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    // Function to approve another address to spend tokens on behalf of the caller
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // Function to check the remaining allowance for a spender
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }
}
