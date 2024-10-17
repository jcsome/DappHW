// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../TokenBank.sol";
import "../HookERC20/ExtendERC20.sol";

contract TokenBankV2 is TokenBank, ITokenReceiver {
    
    constructor(IERC20 _token) TokenBank(_token) {

    }

    function tokenReceived(address from, uint256 value, bytes memory data) external{
        require(msg.sender==address(token), "TokenBankV2: token received not ERC20 token");
        balances[from] += value;
    }
}