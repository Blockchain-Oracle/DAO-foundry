// SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {MyToken} from "../src/ MyToken.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {MyGovernor} from "../src/ MyGovernor.sol";
import {DeployBox} from "./DeployBox.s.sol";
import {DeployGovornor} from "./DeployGovernor.s.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";
import {Vm} from "../lib/forge-std/src/Vm.sol";
import {Box} from "../src/Box.sol";

contract Interactions is Script {
    uint256 public privatekey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    address token;
    uint48 initialVotingDelay;
    uint32 initialVotingPeriod;
    address payable timelock;
    HelperConfig helperConfig;
    MyGovernor governor;

    //MAKING MY CONTRACTS DECENTRALIZED
    //MAKING EXECTUTORS AS NULL AND PROPOSERS AS GOVONOR CONTRACT
    //MAKING ADMIN AS NULL
    //Meaning nobody can execute the transaction and only govonor can propose the transaction
    function run() public {
        // address boxAddress = DevOpsTools.get_most_recent_deployment("Box", block.chainid);

        DeployGovornor deployGovernor = new DeployGovornor();
        DeployBox deployBox = new DeployBox();
        Box box = deployBox.run();
        address boxAddress = address(box);
        (governor, helperConfig) = deployGovernor.run();
        (token, initialVotingDelay, initialVotingPeriod, timelock) = helperConfig.config();

        vm.startBroadcast(privatekey);
        console.log("in interactions", msg.sender);
        console.log(
            "does msg.semder has admin role",
            TimeLock(timelock).hasRole(TimeLock(timelock).DEFAULT_ADMIN_ROLE(), msg.sender)
        );
        TimeLock(timelock).grantRole(TimeLock(timelock).PROPOSER_ROLE(), address(governor));
        TimeLock(timelock).grantRole(TimeLock(timelock).EXECUTOR_ROLE(), address(0));
        TimeLock(timelock).revokeRole(TimeLock(timelock).DEFAULT_ADMIN_ROLE(), msg.sender);
        console.log(
            "does msg.semder has admin role after revoke",
            TimeLock(timelock).hasRole(TimeLock(timelock).DEFAULT_ADMIN_ROLE(), msg.sender)
        );
        MyToken(token).mint(msg.sender, 1000e33);
        MyToken(token).delegate(msg.sender);
        console.log("token balance.....................", MyToken(token).balanceOf(msg.sender));

        vm.stopBroadcast();

        console.log("All the contracts are now decentralized.");
        console.log("Admin is %s", uint256(TimeLock(timelock).DEFAULT_ADMIN_ROLE()));
        console.log("Proposer is %s", uint256(TimeLock(timelock).PROPOSER_ROLE()));
        console.log("Executor is %s", uint256(TimeLock(timelock).EXECUTOR_ROLE()));
        //propose
        // box.push(boxAddress);
        bytes memory calldatas = (abi.encodeWithSignature("setValue(uint256)", 77));
        string memory despcription = "update box";
        uint256 proposaId = propose(governor, boxAddress, calldatas, despcription);
        //vote
        uint8 support = 1; //1== vote 0= not vote
        string memory reason = "i like to do the cha cha";
        vote(governor, proposaId, support, reason);
        //queue/execute
        queueAndExecute(governor, boxAddress, calldatas, despcription, proposaId);
        // govonor.
    }

    function propose(MyGovernor, address _box, bytes memory calldatas, string memory desscription)
        public
        returns (uint256)
    {
        address[] memory box = new address[](1);
        bytes[] memory _calldatas = new bytes[](1);
        uint256[] memory values = new uint256[](1);

        _calldatas[0] = calldatas;

        box[0] = _box;
        console.log("proposing pls wait ");
        console.log("description %s", desscription);

        vm.startBroadcast(privatekey);
        vm.recordLogs();
        MyGovernor(governor).propose(box, values, _calldatas, desscription);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        console.log();
        bytes32 proposalId = entries[0].topics[1];
        // Decode the entire log to get the proposalId

        //        event ProposalCreated(
        //     uint256 proposalId,
        //     address proposer,
        //     address[] targets,
        //     uint256[] values,
        //     string[] signatures,
        //     bytes[] calldatas,
        //     uint256 voteStart,
        //     uint256 voteEnd,
        //     string description
        // );
        // (uint256 proposalId,,,,,,,,) = abi.decode(
        //     entries[0].data, (uint256, address, address[], uint256[], string[], bytes[], uint256, uint256, string)
        // );

        vm.stopBroadcast();
        console.log("proposalId", uint256(proposalId));
        if (block.chainid == 31337) {
            console.log("passing the proposal time");
            vm.warp(block.timestamp + 1 + 1);
            vm.roll(block.number + 1 + 1);
            console.log("intial voting delay passed");
        }
        return (uint256(proposalId));
    }

    function vote(MyGovernor, uint256 proposaId, uint8 support, string memory reason) public {
        console.log("PROPOASAL ID START,,,,,,,,,,,", uint256(governor.state(proposaId)));
        console.log("casting vote pls wait..");

        vm.startBroadcast(privatekey);
        console.log("token balance.....................", MyToken(token).balanceOf(msg.sender));
        governor.castVoteWithReason(proposaId, support, reason);
        vm.stopBroadcast();
        if (block.chainid == 31337) {
            console.log("ending voting period");
            vm.warp(block.timestamp + 50400 + 1);
            vm.roll(block.number + 50400 + 1);
            console.log("voting period passed");
        }
        console.log("proposal state", uint256(governor.state(proposaId)));
    }

    function queueAndExecute(
        MyGovernor,
        address box,
        bytes memory _calldatas,
        string memory description,
        uint256 proposaId
    ) public {
        address[] memory targets = new address[](1);
        console.log("proposal state", uint256(governor.state(proposaId)));

        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = box;
        calldatas[0] = _calldatas;
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        vm.startBroadcast(privatekey);
        governor.queue(targets, values, calldatas, descriptionHash);
        vm.stopBroadcast();
        //alright your calldata is beem queued but you gotta wait for the timelock to execute it
        //3600 seconds
        if (block.chainid == 31337) {
            console.log("increasing timelock time for execution");
            vm.warp(block.timestamp + 3600 + 1);
            vm.roll(block.number + 3600 + 1);
        }
        console.log("executing pls wait");
        vm.startBroadcast(privatekey);
        governor.execute(targets, values, calldatas, descriptionHash);
        vm.stopBroadcast();
        console.log("executed");
        console.log("value of box", Box(box).getValue());
    }
}
