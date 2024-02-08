// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {Box} from "../src/Box.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {DeployBox} from "./DeployBox.s.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {DeployGovornor} from "./DeployGovernor.s.sol";

contract DeployBox is Script {
    HelperConfig helperConfig;
    uint256 public privatekey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    function run() public returns (Box) {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("DeployGovornor", block.chainid);
        DeployGovornor deployGovernor = DeployGovornor(mostRecentlyDeployed);
        (, helperConfig) = deployGovernor.run();
        (,,, address payable timeLock) = helperConfig.config();
        vm.startBroadcast(privatekey);
        console.log("in deploy box", msg.sender);
        Box box = new Box(timeLock);
        vm.stopBroadcast();
        return (box);
    }
}
