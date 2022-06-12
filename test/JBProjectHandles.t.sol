// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import 'forge-std/Test.sol';

import '@ensdomains/ens-contracts/contracts/resolvers/profiles/ITextResolver.sol';
import '@jbx-protocol/contracts-v2/contracts/JBProjects.sol';
import '@jbx-protocol/contracts-v2/contracts/JBOperatorStore.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import '@contracts/JBProjectHandles.sol';
import '@contracts/libraries/JBHandlesOperations.sol';

contract ContractTest is Test {
  // For testing the event emitted
  event SetEnsNameParts(
    uint256 indexed projectId,
    string indexed ensName,
    string[] parts,
    address caller
  );

  address projectOwner = address(6942069);

  ITextResolver ensTextResolver = ITextResolver(address(69420)); // Mocked
  JBOperatorStore jbOperatorStore;
  JBProjects jbProjects;
  JBProjectHandles projectHandle;

  function setUp() public {
    vm.etch(address(ensTextResolver), '0x69');
    vm.label(address(ensTextResolver), 'ensTextResolver');
    jbOperatorStore = new JBOperatorStore();
    jbProjects = new JBProjects(jbOperatorStore);
    projectHandle = new JBProjectHandles(jbProjects, jbOperatorStore, ensTextResolver);
  }

  //*********************************************************************//
  // ------------------------ SetEnsNamePartsFor(..) ------------------- //
  //*********************************************************************//

  function testSetEnsNamePartsFor_passIfCallerIsProjectOwnerAndOnlyName(string calldata _name) public {
    vm.assume(bytes(_name).length != 0);

    uint256 _projectId = jbProjects.createFor(
      projectOwner,
      JBProjectMetadata({content: 'content', domain: 1})
    );

    string[] memory _nameParts = new string[](1);
    _nameParts[0] = _name;

    // Test the event emitted
    vm.expectEmit(true, true, true, true);
    emit SetEnsNameParts(_projectId, string(abi.encodePacked(_name, '.eth')), _nameParts, projectOwner);

    vm.prank(projectOwner);
    projectHandle.setEnsNamePartsFor(_projectId, _nameParts);

    // Control: correct ENS name?
    assertEq(projectHandle.ensNamePartsOf(_projectId), _nameParts);
  }

  function testSetEnsNameFor_passIfAuthorizedCallerAndOnlyName(address caller, string calldata _name) public {
    vm.assume(bytes(_name).length != 0);

    uint256 _projectId = jbProjects.createFor(
      projectOwner,
      JBProjectMetadata({content: 'content', domain: 1})
    );

    // Give the authorisation to set ENS to caller
    uint256[] memory permissionIndexes = new uint256[](1);
    permissionIndexes[0] = JBHandlesOperations.SET_ENS_NAME_FOR;

    vm.prank(projectOwner);
    jbOperatorStore.setOperator(
      JBOperatorData({operator: caller, domain: 1, permissionIndexes: permissionIndexes})
    );

    string[] memory _nameParts = new string[](1);
    _nameParts[0] = _name;

    // Test event
    vm.expectEmit(true, true, true, true);
    emit SetEnsNameParts(_projectId, string(abi.encodePacked(_name, '.eth')), _nameParts, caller);

    vm.prank(caller);
    projectHandle.setEnsNamePartsFor(_projectId, _nameParts);

    // Control: correct ENS name?
    assertEq(projectHandle.ensNamePartsOf(_projectId), _nameParts);
  }

  function testSetEnsNameWithSubdomainFor_passIfMultipleSubdomainLevels(
    string memory _name,
    string memory _subdomain,
    string memory _subsubdomain
  ) public {
    vm.assume(bytes(_name).length > 0 && bytes(_subdomain).length > 0  && bytes(_subsubdomain).length > 0);

    uint256 _projectId = jbProjects.createFor(
      projectOwner,
      JBProjectMetadata({content: 'content', domain: 1})
    );

    // name.subdomain.subsubdomain.eth is stored as ['subsubdomain', 'subdomain', 'domain']
    string[] memory _nameParts = new string[](3);
    _nameParts[0] = _subsubdomain;
    _nameParts[1] = _subdomain;
    _nameParts[2] = _name;

    string memory _fullName = string(abi.encodePacked(_name, '.', _subdomain, '.', _subsubdomain, '.eth'));

    // Test event
    vm.expectEmit(true, true, true, true);
    emit SetEnsNameParts(_projectId, _fullName, _nameParts, projectOwner);

    vm.prank(projectOwner);
    projectHandle.setEnsNamePartsFor(_projectId, _nameParts);

    // Control: ENS has correct name and domain
    assertEq(projectHandle.ensNamePartsOf(_projectId), _nameParts);
  }

  function testSetEnsNameFor_revertIfNotAuthorized(
    uint96 authorizationIndex,
    address caller,
    string calldata _name
  ) public {
    vm.assume(
      authorizationIndex != JBHandlesOperations.SET_ENS_NAME_FOR && authorizationIndex < 255
    );
    vm.assume(caller != projectOwner);
    uint256 _projectId = jbProjects.createFor(
      projectOwner,
      JBProjectMetadata({content: 'content', domain: 1})
    );

    string[] memory _nameParts = new string[](1);
    _nameParts[0] = _name;

    // Is the caller not authorized by default?
    vm.prank(caller);
    vm.expectRevert(abi.encodeWithSignature('UNAUTHORIZED()'));
    projectHandle.setEnsNamePartsFor(_projectId, _nameParts);

    // Still noot authorized if wrong permission index
    uint256[] memory permissionIndexes = new uint256[](1);
    permissionIndexes[0] = authorizationIndex;

    vm.prank(projectOwner);
    jbOperatorStore.setOperator(
      JBOperatorData({operator: caller, domain: 1, permissionIndexes: permissionIndexes})
    );

    vm.prank(caller);
    vm.expectRevert(abi.encodeWithSignature('UNAUTHORIZED()'));
    projectHandle.setEnsNamePartsFor(_projectId, _nameParts);

    // Control: ENS is still empty
    assertEq(projectHandle.ensNamePartsOf(_projectId), new string[](0));
  }

  function testSetEnsNameWithSubdomainFor_RevertIfEmptyElementInNameParts(
    string memory _name,
    string memory _subdomain,
    string memory _subsubdomain
  ) public {
    vm.assume(
      bytes(_name).length == 0
      || bytes(_subdomain).length == 0
      || bytes(_subsubdomain).length == 0
    );

    uint256 _projectId = jbProjects.createFor(
      projectOwner,
      JBProjectMetadata({content: 'content', domain: 1})
    );

    // name.subdomain.subsubdomain.eth is stored as ['subsubdomain', 'subdomain', 'domain']
    string[] memory _nameParts = new string[](3);
    _nameParts[0] = _subsubdomain;
    _nameParts[1] = _subdomain;
    _nameParts[2] = _name;

    vm.prank(projectOwner);
    vm.expectRevert(abi.encodeWithSignature('EMPTY_NAME_PART()'));
    projectHandle.setEnsNamePartsFor(_projectId, _nameParts);

    // Control: ENS has correct name and domain
    assertEq(projectHandle.ensNamePartsOf(_projectId), new string[](0));
  }

  //*********************************************************************//
  // ---------------------------- handleOf(..) ------------------------- //
  //*********************************************************************//

  // function testHandleOf_returnsEmptyStringIfNoENSset(uint256 projectId) public {
  //   // No ENS set -> empty
  //   assertEq(projectHandle.handleOf(projectId), '');
  // }

  // function testHandleOf_returnsEmptyStringIfReverseIdDoesNotMatchProjectId(
  //   uint256 projectId,
  //   uint256 _reverseId,
  //   string calldata _name,
  //   string calldata _subdomain
  // ) public {
  //   vm.assume(projectId != _reverseId);

  //   string memory reverseId = Strings.toString(_reverseId);
  //   string memory KEY = projectHandle.TEXT_KEY();

  //   vm.mockCall(
  //     address(ensTextResolver),
  //     abi.encodeWithSelector(
  //       ITextResolver.text.selector,
  //       _namehash(ENSName({name: _name, subdomain: _subdomain})),
  //       KEY
  //     ),
  //     abi.encode(reverseId)
  //   );

  //   assertEq(projectHandle.handleOf(projectId), '');
  // }

  // function testHandleOf_returnsHandleIfReverseIdMatchProjectId(
  //   string calldata _name,
  //   string calldata _subdomain
  // ) public {
  //   vm.assume(bytes(_name).length > 0 && bytes(_subdomain).length > 0);

  //   uint256 _projectId = jbProjects.createFor(
  //     projectOwner,
  //     JBProjectMetadata({content: 'content', domain: 1})
  //   );

  //   string memory reverseId = Strings.toString(_projectId);
  //   string memory KEY = projectHandle.TEXT_KEY();

  //   vm.prank(projectOwner);
  //   projectHandle.setEnsNameWithSubdomainFor(_projectId, _name, _subdomain);

  //   vm.mockCall(
  //     address(ensTextResolver),
  //     abi.encodeWithSelector(
  //       ITextResolver.text.selector,
  //       _namehash(ENSName({name: _name, subdomain: _subdomain})),
  //       KEY
  //     ),
  //     abi.encode(Strings.toString(_projectId))
  //   );

  //   assertEq(projectHandle.handleOf(_projectId), string(abi.encodePacked(_subdomain, '.', _name)));
  // }

  //*********************************************************************//
  // ---------------------------- helpers ---- ------------------------- //
  //*********************************************************************//

  // Assert equals between two string arrays
  function assertEq(string[] memory _first, string[] memory _second) internal {
    assertEq(_first.length, _second.length);
    for (uint256 _i; _i < _first.length; _i++)
      assertEq(keccak256(bytes(_first[_i])), keccak256(bytes(_second[_i])));
  }

  function _namehash(string[] memory _ensName) internal pure returns (bytes32 namehash) {
    namehash = 0x0000000000000000000000000000000000000000000000000000000000000000;
    namehash = keccak256(abi.encodePacked(namehash, keccak256(abi.encodePacked('eth'))));

    // Get a reference to the number of parts are in the ENS name.
    uint256 _nameLength = _ensName.length;

    // Hash each part.
    for (uint256 _i = 0; _i < _nameLength; ) {
      namehash = keccak256(abi.encodePacked(namehash, keccak256(abi.encodePacked(_ensName[_i]))));
      unchecked {
        ++_i;
      }
    }
  }
}
