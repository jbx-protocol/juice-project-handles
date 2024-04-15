// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "forge-std/Test.sol";

import "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBOperatorStore.sol";
import "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBProjects.sol";

import "../JBProjectHandles.sol";

contract DeploySepolia is Test {
    IJBOperatorStore _operatorStore = IJBOperatorStore(0x8f63C744C0280Ef4b32AF1F821c65E0fd4150ab3);
    IJBProjects _projects = IJBProjects(0x43CB8FCe4F0d61579044342A5d5A027aB7aE4D63);

    // Have to use its own address as the `_oldHandle`.
    // TODO: UPDATE THIS EACH TIME YOU DEPLOY.
    address willBeDeployedAt = _addressFrom(0xfAb4c9E48EB050E8f51555Ef949a7ef1b8fb263B, 0);

    IJBProjectHandles _oldHandle = IJBProjectHandles(willBeDeployedAt);

    JBProjectHandles jbProjectHandles;

    function run() external {
        vm.startBroadcast();

        jbProjectHandles = new JBProjectHandles(_projects, _operatorStore, _oldHandle);
    }

    /// @notice Compute the address of a contract deployed using `create` based on the deployer's address and nonce.
    /// @dev Taken from https://ethereum.stackexchange.com/a/87840/68134 - this won't work for nonces > 2**32. If
    /// you reach that nonce please: 1) ping us, because wow 2) use another deployer.
    /// @param origin The deployer's address.
    /// @param nonce The nonce used to deploy the contract.
    function _addressFrom(address origin, uint256 nonce) internal pure returns (address addr) {
        bytes memory data;
        if (nonce == 0x00) {
            data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), origin, bytes1(0x80));
        } else if (nonce <= 0x7f) {
            data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), origin, uint8(nonce));
        } else if (nonce <= 0xff) {
            data = abi.encodePacked(bytes1(0xd7), bytes1(0x94), origin, bytes1(0x81), uint8(nonce));
        } else if (nonce <= 0xffff) {
            data = abi.encodePacked(bytes1(0xd8), bytes1(0x94), origin, bytes1(0x82), uint16(nonce));
        } else if (nonce <= 0xffffff) {
            data = abi.encodePacked(bytes1(0xd9), bytes1(0x94), origin, bytes1(0x83), uint24(nonce));
        } else {
            data = abi.encodePacked(bytes1(0xda), bytes1(0x94), origin, bytes1(0x84), uint32(nonce));
        }
        bytes32 hash = keccak256(data);
        assembly {
            mstore(0, hash)
            addr := mload(0)
        }
    }
}

contract DeployGoerli is Test {
    IJBOperatorStore _operatorStore = IJBOperatorStore(0x99dB6b517683237dE9C494bbd17861f3608F3585);
    IJBProjects _projects = IJBProjects(0x21263a042aFE4bAE34F08Bb318056C181bD96D3b);
    IJBProjectHandles _oldHandle = IJBProjectHandles(0x41126eC99F8A989fEB503ac7bB4c5e5D40E06FA4);

    JBProjectHandles jbProjectHandles;

    function run() external {
        vm.startBroadcast();

        jbProjectHandles = new JBProjectHandles(_projects, _operatorStore, _oldHandle);
    }
}

contract DeployMainnet is Test {
    IJBOperatorStore _operatorStore = IJBOperatorStore(0x6F3C5afCa0c9eDf3926eF2dDF17c8ae6391afEfb);
    IJBProjects _projects = IJBProjects(0xD8B4359143eda5B2d763E127Ed27c77addBc47d3);
    IJBProjectHandles _oldHandle = IJBProjectHandles(0xE3c01E9Fd2a1dCC6edF0b1058B5757138EF9FfB6);

    JBProjectHandles jbProjectHandles;

    function run() external {
        vm.startBroadcast();

        jbProjectHandles = new JBProjectHandles(_projects, _operatorStore, _oldHandle);
    }
}
