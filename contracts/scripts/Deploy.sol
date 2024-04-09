// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import 'forge-std/Test.sol';

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBOperatorStore.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBProjects.sol';

import '../JBProjectHandles.sol';

contract DeploySepolia is Test {
  IJBOperatorStore _operatorStore = IJBOperatorStore(0x8f63C744C0280Ef4b32AF1F821c65E0fd4150ab3);
  IJBProjects _projects = IJBProjects(0x43CB8FCe4F0d61579044342A5d5A027aB7aE4D63);
  IJBProjectHandles _oldHandle = IJBProjectHandles(0x0000000000000000000000000000000000000000);

  JBProjectHandles jbProjectHandles;

  function run() external {
    vm.startBroadcast();

    jbProjectHandles = new JBProjectHandles(_projects, _operatorStore, _oldHandle);
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
