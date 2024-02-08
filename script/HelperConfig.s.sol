// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {MyToken} from "../src/ MyToken.sol";
import {TimeLock} from "../src/TimeLock.sol";

contract HelperConfig is Script {
    uint256 public privatekey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    struct Config {
        address token;
        uint48 initialVotingDelay;
        uint32 initialVotingPeriod;
        address payable timelock;
    }

    Config public config;

    constructor() {
        if (block.chainid == 31337) {
            config = anvilConfig();
        }
    }

    function anvilConfig() public returns (Config memory) {
        //deploying token
        address[] memory proposers;
        address[] memory executors;
        // vm.startBroadcast(privatekey);
        console.log("in helper config", msg.sender);
        TimeLock timeLock = new TimeLock(3600, proposers, executors, msg.sender);
        MyToken token = new MyToken();

        // vm.stopBroadcast();
        return Config({
            token: address(token),
            initialVotingDelay: 1,
            initialVotingPeriod: 50400,
            timelock: (payable(address(timeLock)))
        });
    }
}
