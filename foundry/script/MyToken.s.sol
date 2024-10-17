// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/MyToken.sol";
import "forge-std/Script.sol";

contract DeployMyToken is Script {
    function run() external {
        vm.startBroadcast();
        MyToken myToken = new MyToken("MyToken", "MT");
        vm.stopBroadcast();
    }
}