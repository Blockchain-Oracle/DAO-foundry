// SPDX-License-Identifier:MIT
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.18;

contract Box is Ownable {
    uint256 value;

    constructor(address initialOwner) Ownable(initialOwner) {}

    function getValue() public view returns (uint256) {
        return value;
    }

    function setValue(uint256 _value) public {
        value = _value;
    }
}
