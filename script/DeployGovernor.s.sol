// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {MyGovernor} from "../src/ MyGovernor.sol";
import {MyToken} from "../src/ MyToken.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract DeployGovornor is Script {
    uint256 public privatekey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    HelperConfig helperConfig;
    address token;
    uint48 initialVotingDelay;
    uint32 initialVotingPeriod;
    address payable timelock;

    function run() public returns (MyGovernor, HelperConfig) {
        //deploy govonor
        // IVotes _token,
        // uint48 initialVotingDelay,
        //  uint32 initialVotingPeriod,
        //   TimelockController _timelock

        vm.startBroadcast(privatekey);
        console.log("in deploy govonor", msg.sender);
        helperConfig = new HelperConfig();
        (token, initialVotingDelay, initialVotingPeriod, timelock) = helperConfig.config();
        MyGovernor governor =
            new MyGovernor(MyToken(token), initialVotingDelay, initialVotingPeriod, (TimelockController(timelock)));
        vm.stopBroadcast();
        return (governor, helperConfig);
    }
}
