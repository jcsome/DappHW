// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "../BaseERC20.sol";

interface ITokenReceiver {
    function tokenReceived(address from, uint256 value, bytes calldata data) external;
}

interface IERC20WithCallback {
    function transferWithCallback(address _to, uint256 _value, bytes calldata data) external returns (bool);
}

contract ERC20WithCallback is BaseERC20, IERC20WithCallback{
    
    using Address for address;
    function transferWithCallback(address _to, uint256 _value, bytes calldata data) external returns (bool) {
        transfer(_to, _value);
        if(isContract(_to)) {
            ITokenReceiver(_to).tokenReceived(msg.sender, _value, data);
        }
        return true;
    }

    function isContract(address account) public view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}