// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "forge-std/Test.sol";

import '@ensdomains/ens-contracts/contracts/resolvers/profiles/ITextResolver.sol';
import '@jbx-protocol/contracts-v2/contracts/JBProjects.sol';
import '@jbx-protocol/contracts-v2/contracts/JBOperatorStore.sol';

import "@contracts/JBProjectHandles.sol";
import "@contracts/libraries/JBHandlesOperations.sol";

contract ContractTest is Test {
    event SetEnsName(uint256 indexed projectId, string indexed ensName);

    address projectOwner = address(6942069);

    ITextResolver ensTextResolver = ITextResolver(address(69420));
    JBOperatorStore jbOperatorStore;
    JBProjects jbProjects;

    JBProjectHandles projectHandle;

    function setUp() public {
        jbOperatorStore = new JBOperatorStore();
        jbProjects = new JBProjects(jbOperatorStore);
        projectHandle = new JBProjectHandles(jbProjects, jbOperatorStore, ensTextResolver);
    }

    function testSetEnsNameFor_passIfProjectOwner(string calldata _name) public {
        uint256 _projectId = jbProjects.createFor(projectOwner, JBProjectMetadata({content: 'content', domain: 1}));
        
        vm.expectEmit(false, false, false, true);
        emit SetEnsName(_projectId, _name);

        vm.prank(projectOwner);
        projectHandle.setEnsNameFor(_projectId, _name);
    }

    function testSetEnsNameFor_passIfAuthorized(address caller, string calldata _name) public {
        uint256 _projectId = jbProjects.createFor(projectOwner, JBProjectMetadata({content: 'content', domain: 1}));
        
        uint256[] memory permissionIndexes = new uint256[](1);
        permissionIndexes[0] = JBHandlesOperations.SET_ENS_NAME_FOR;

        vm.prank(projectOwner);
        jbOperatorStore.setOperator(JBOperatorData({
            operator: caller,
            domain: 1,
            permissionIndexes: permissionIndexes
        }));

        vm.expectEmit(false, false, false, true);
        emit SetEnsName(_projectId, _name);

        vm.prank(caller);
        projectHandle.setEnsNameFor(_projectId, _name);
    }

    function testSetEnsNameWithSubdomainFor_passIfProjectOwner(string calldata _name, string calldata _subdomain) public {
        uint256 _projectId = jbProjects.createFor(projectOwner, JBProjectMetadata({content: 'content', domain: 1}));
        
        vm.expectEmit(false, false, false, true);
        emit SetEnsName(_projectId, _namAnd);

        vm.prank(projectOwner);
        projectHandle.setEnsNameFor(_projectId, _name);
    }
}
