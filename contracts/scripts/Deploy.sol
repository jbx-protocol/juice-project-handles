// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import 'forge-std/Test.sol';

import '@ensdomains/ens-contracts/contracts/resolvers/profiles/ITextResolver.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBOperatorStore.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBProjects.sol';

import '../JBProjectHandles.sol';

contract DeployGoerli is Test {
  IJBOperatorStore _operatorStore = IJBOperatorStore(0x99dB6b517683237dE9C494bbd17861f3608F3585);
  IJBProjects _projects = IJBProjects(0x21263a042aFE4bAE34F08Bb318056C181bD96D3b);
  ITextResolver _ENSResolver = ITextResolver(0xE264d5bb84bA3b8061ADC38D3D76e6674aB91852);

  JBProjectHandles jbProjectHandles;

  function run() external {
    vm.startBroadcast();

    jbProjectHandles = new JBProjectHandles(_projects, _operatorStore, _ENSResolver);
  }
}

contract DeployMainnet is Test {
  IJBOperatorStore _operatorStore = IJBOperatorStore(0x6F3C5afCa0c9eDf3926eF2dDF17c8ae6391afEfb);
  IJBProjects _projects = IJBProjects(0xD8B4359143eda5B2d763E127Ed27c77addBc47d3);
  ITextResolver _ENSResolver = ITextResolver(0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41);

  JBProjectHandles jbProjectHandles;

  function run() external {
    vm.startBroadcast();

    jbProjectHandles = new JBProjectHandles(_projects, _operatorStore, _ENSResolver);
  }
}
