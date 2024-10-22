// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/MyToken.sol";
import "forge-std/Script.sol";

contract DeployMyToken is Script {
    function run() external {
        // Start broadcast transaction
        vm.startBroadcast();

        // Deploy MyToken contract
        MyToken myToken = new MyToken("MyToken", "MTK");

        // Stop broadcast transaction
        vm.stopBroadcast();

        // Print contract address
        console.log("My Token deployed at: %s", address(myToken));
    }
}