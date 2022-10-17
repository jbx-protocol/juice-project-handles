// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import 'forge-std/Test.sol';

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBOperatorStore.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBProjects.sol';

import '../JBProjectHandles.sol';

contract DeployGoerli is Test {
  IJBOperatorStore _operatorStore = IJBOperatorStore(0x99dB6b517683237dE9C494bbd17861f3608F3585);
  IJBProjects _projects = IJBProjects(0x21263a042aFE4bAE34F08Bb318056C181bD96D3b);

  JBProjectHandles jbProjectHandles;

  function run() external {
    vm.startBroadcast();

    jbProjectHandles = new JBProjectHandles(_projects, _operatorStore);
  }
}

contract DeployMainnet is Test {
  IJBOperatorStore _operatorStore = IJBOperatorStore(0x6F3C5afCa0c9eDf3926eF2dDF17c8ae6391afEfb);
  IJBProjects _projects = IJBProjects(0xD8B4359143eda5B2d763E127Ed27c77addBc47d3);

  JBProjectHandles jbProjectHandles;

  function run() external {
    vm.startBroadcast();

    jbProjectHandles = new JBProjectHandles(_projects, _operatorStore);
  }
}
