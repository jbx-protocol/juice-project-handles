// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import 'forge-std/Test.sol';

import '@ensdomains/ens-contracts/contracts/registry/ENS.sol'; // This is an interface...
import '@ensdomains/ens-contracts/contracts/resolvers/profiles/ITextResolver.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/JBProjects.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/JBOperatorStore.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import '@contracts/JBProjectHandles.sol';
import '@contracts/libraries/JBOperations2.sol';

ENS constant ensRegistry = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
IJBProjectHandles constant oldHandle = IJBProjectHandles(0x41126eC99F8A989fEB503ac7bB4c5e5D40E06FA4);

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
    vm.etch(address(ensRegistry), '0x69');
    vm.etch(address(oldHandle), '0x69');
    vm.label(address(ensTextResolver), 'ensTextResolver');
    vm.label(address(ensRegistry), 'ensRegistry');
    vm.label(address(oldHandle), 'ensRegistry');

    jbOperatorStore = new JBOperatorStore();
    jbProjects = new JBProjects(jbOperatorStore);
    projectHandle = new JBProjectHandles(jbProjects, jbOperatorStore, oldHandle);
  }

  //*********************************************************************//
  // ------------------------ SetEnsNamePartsFor(..) ------------------- //
  //*********************************************************************//

  function testSetEnsNamePartsFor_passIfCallerIsProjectOwnerAndOnlyName(string calldata _name)
    public
  {
    vm.assume(bytes(_name).length != 0);

    uint256 _projectId = jbProjects.createFor(
      projectOwner,
      JBProjectMetadata({content: 'content', domain: 1})
    );

    string[] memory _nameParts = new string[](1);
    _nameParts[0] = _name;

    // Test the event emitted
    vm.expectEmit(true, true, true, true);
    emit SetEnsNameParts(_projectId, _name, _nameParts, projectOwner);

    vm.prank(projectOwner);
    projectHandle.setEnsNamePartsFor(_projectId, _nameParts);

    // Control: correct ENS name?
    assertEq(projectHandle.ensNamePartsOf(_projectId), _nameParts);
  }

  function testSetEnsNameFor_passIfAuthorizedCallerAndOnlyName(
    address caller,
    string calldata _name
  ) public {
    vm.assume(bytes(_name).length != 0);

    uint256 _projectId = jbProjects.createFor(
      projectOwner,
      JBProjectMetadata({content: 'content', domain: 1})
    );

    // Give the authorisation to set ENS to caller
    uint256[] memory permissionIndexes = new uint256[](1);
    permissionIndexes[0] = JBOperations2.SET_ENS_NAME_FOR;

    vm.prank(projectOwner);
    jbOperatorStore.setOperator(
      JBOperatorData({operator: caller, domain: 1, permissionIndexes: permissionIndexes})
    );

    string[] memory _nameParts = new string[](1);
    _nameParts[0] = _name;

    // Test event
    vm.expectEmit(true, true, true, true);
    emit SetEnsNameParts(_projectId, _name, _nameParts, caller);

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
    vm.assume(
      bytes(_name).length > 0 && bytes(_subdomain).length > 0 && bytes(_subsubdomain).length > 0
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

    string memory _fullName = string(abi.encodePacked(_name, '.', _subdomain, '.', _subsubdomain));

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
    vm.assume(authorizationIndex != JBOperations2.SET_ENS_NAME_FOR && authorizationIndex < 255);
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
      bytes(_name).length == 0 || bytes(_subdomain).length == 0 || bytes(_subsubdomain).length == 0
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

  function testSetEnsNameWithSubdomainFor_RevertIfEmptyNameParts() public {
    uint256 _projectId = jbProjects.createFor(
      projectOwner,
      JBProjectMetadata({content: 'content', domain: 1})
    );

    // name.subdomain.subsubdomain.eth is stored as ['subsubdomain', 'subdomain', 'domain']
    string[] memory _nameParts = new string[](0);

    vm.prank(projectOwner);
    vm.expectRevert(abi.encodeWithSignature('NO_PARTS()'));
    projectHandle.setEnsNamePartsFor(_projectId, _nameParts);

    // Control: ENS has correct name and domain
    assertEq(projectHandle.ensNamePartsOf(_projectId), new string[](0));
  }

  //*********************************************************************//
  // ---------------------------- handleOf(..) ------------------------- //
  //*********************************************************************//

  function testHandleOf_returnsEmptyStringIfNoHandleSet(uint256 projectId) public {
    // No ENS set, even in previous JBProjectHandle -> return empty
    vm.mockCall(address(oldHandle), abi.encodeCall(IJBProjectHandles.handleOf, (projectId)), abi.encode(''));
    assertEq(projectHandle.handleOf(projectId), '');
  }

  function testHandleOf_returnsPreviousHandleIfRegisteredONLYOnPreviousVersion(uint256 projectId, string memory handle) public {
    // ENS set in previous JBProjectHandle, not in the new one -> return it
    vm.mockCall(address(oldHandle), abi.encodeCall(IJBProjectHandles.handleOf, (projectId)), abi.encode(handle));
    assertEq(projectHandle.handleOf(projectId), handle);
  }

  function testHandleOf_returnsNewestHandleIfRegisteredOnBothOldAndNewVersion(
    string calldata _name,
    string calldata _subdomain,
    string calldata _subsubdomain
  ) public {
    vm.assume(
      bytes(_name).length > 0 && bytes(_subdomain).length > 0 && bytes(_subsubdomain).length > 0
    );


    uint256 _projectId = jbProjects.createFor(
      projectOwner,
      JBProjectMetadata({content: 'content', domain: 1})
    );

    string memory KEY = projectHandle.TEXT_KEY();

    // name.subdomain.subsubdomain.eth is stored as ['subsubdomain', 'subdomain', 'domain']
    string[] memory _nameParts = new string[](3);
    _nameParts[0] = _subsubdomain;
    _nameParts[1] = _subdomain;
    _nameParts[2] = _name;

    vm.prank(projectOwner);
    projectHandle.setEnsNamePartsFor(_projectId, _nameParts);

    vm.mockCall(
      address(ensRegistry),
      abi.encodeWithSelector(ENS.resolver.selector, _namehash(_nameParts)),
      abi.encode(address(ensTextResolver))
    );

    vm.mockCall(
      address(ensTextResolver),
      abi.encodeWithSelector(ITextResolver.text.selector, _namehash(_nameParts), KEY),
      abi.encode(Strings.toString(_projectId))
    );

    // Mock the registration on the previous version
    vm.mockCall(address(oldHandle), abi.encodeCall(IJBProjectHandles.handleOf, (_projectId)), abi.encode('I am so deprecated that it hurts'));

    // Returns the handle from the latest version
    assertEq(
      projectHandle.handleOf(_projectId),
      string(abi.encodePacked(_name, '.', _subdomain, '.', _subsubdomain))
    );
  }

  function testHandleOf_returnsEmptyStringIfENSIsNotRegistered(
    uint256 projectId,
    uint256 _reverseId,
    string calldata _name,
    string calldata _subdomain,
    string calldata _subsubdomain
  ) public {
    vm.assume(projectId != _reverseId);

    // No handle set on the previous JBProjectHandle version
    vm.mockCall(address(oldHandle), abi.encodeCall(IJBProjectHandles.handleOf, (projectId)), abi.encode(''));

    // name.subdomain.subsubdomain.eth is stored as ['subsubdomain', 'subdomain', 'domain']
    string[] memory _nameParts = new string[](3);
    _nameParts[0] = _subsubdomain;
    _nameParts[1] = _subdomain;
    _nameParts[2] = _name;

    vm.mockCall(
      address(ensRegistry),
      abi.encodeWithSelector(ENS.resolver.selector, _namehash(_nameParts)),
      abi.encode(address(0))
    );

    assertEq(projectHandle.handleOf(projectId), '');
  }

  function testHandleOf_returnsEmptyStringIfReverseIdDoesNotMatchProjectId(
    uint256 projectId,
    uint256 _reverseId,
    string calldata _name,
    string calldata _subdomain,
    string calldata _subsubdomain
  ) public {
    vm.assume(projectId != _reverseId);

    // No handle set on the previous JBProjectHandle version
    vm.mockCall(address(oldHandle), abi.encodeCall(IJBProjectHandles.handleOf, (projectId)), abi.encode(''));

    string memory reverseId = Strings.toString(_reverseId);
    string memory KEY = projectHandle.TEXT_KEY();

    // name.subdomain.subsubdomain.eth is stored as ['subsubdomain', 'subdomain', 'domain']
    string[] memory _nameParts = new string[](3);
    _nameParts[0] = _subsubdomain;
    _nameParts[1] = _subdomain;
    _nameParts[2] = _name;

    vm.mockCall(
      address(ensRegistry),
      abi.encodeWithSelector(ENS.resolver.selector, _namehash(_nameParts)),
      abi.encode(address(ensTextResolver))
    );

    vm.mockCall(
      address(ensTextResolver),
      abi.encodeWithSelector(ITextResolver.text.selector, _namehash(_nameParts), KEY),
      abi.encode(reverseId)
    );

    assertEq(projectHandle.handleOf(projectId), '');
  }

  function testHandleOf_returnsHandleIfReverseIdMatchProjectId(
    string calldata _name,
    string calldata _subdomain,
    string calldata _subsubdomain
  ) public {
    vm.assume(
      bytes(_name).length > 0 && bytes(_subdomain).length > 0 && bytes(_subsubdomain).length > 0
    );

    uint256 _projectId = jbProjects.createFor(
      projectOwner,
      JBProjectMetadata({content: 'content', domain: 1})
    );

    string memory KEY = projectHandle.TEXT_KEY();

    // name.subdomain.subsubdomain.eth is stored as ['subsubdomain', 'subdomain', 'domain']
    string[] memory _nameParts = new string[](3);
    _nameParts[0] = _subsubdomain;
    _nameParts[1] = _subdomain;
    _nameParts[2] = _name;

    vm.prank(projectOwner);
    projectHandle.setEnsNamePartsFor(_projectId, _nameParts);

    vm.mockCall(
      address(ensRegistry),
      abi.encodeWithSelector(ENS.resolver.selector, _namehash(_nameParts)),
      abi.encode(address(ensTextResolver))
    );

    vm.mockCall(
      address(ensTextResolver),
      abi.encodeWithSelector(ITextResolver.text.selector, _namehash(_nameParts), KEY),
      abi.encode(Strings.toString(_projectId))
    );

    assertEq(
      projectHandle.handleOf(_projectId),
      string(abi.encodePacked(_name, '.', _subdomain, '.', _subsubdomain))
    );
  }

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
