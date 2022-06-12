// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@ensdomains/ens-contracts/contracts/resolvers/profiles/ITextResolver.sol';
import '@openzeppelin/contracts/interfaces/IERC721.sol';
import '@jbx-protocol/contracts-v2/contracts/abstract/JBOperatable.sol';
import './interfaces/IJBProjectHandles.sol';
import './libraries/JBHandlesOperations.sol';

/** 
  @title 
  JBProjectHandles

  @author 
  peri

  @notice 
  Manages reverse records that point from JB project IDs to ENS nodes. If the reverse record of a project ID is pointed to an ENS node with a TXT record matching the ID of that project, then the ENS node will be considered the "handle" for that project.

  @dev
  Adheres to -
  IJBProjectHandles: General interface for the generic controller methods in this contract that interacts with funding cycles and tokens according to the protocol's rules.

  @dev
  Inherits from -
  JBOperatable: Several functions in this contract can only be accessed by a project owner, or an address that has been preconfifigured to be an operator of the project.
*/
contract JBProjectHandles is IJBProjectHandles, JBOperatable {
  //*********************************************************************//
  // --------------------- private stored properties ------------------- //
  //*********************************************************************//

  /** 
      @notice
      Mapping of project ID to ENS name

      _projectId The ID of the project to get an ENS name for.
    */
  mapping(uint256 => ENSName) private _ensNameOf;

  //*********************************************************************//
  // --------------- public immutable stored properties ---------------- //
  //*********************************************************************//

  /** 
    @notice
    The key of the ENS text record.
  */
  string public constant TEXT_KEY = 'juicebox';

  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /** 
    @notice
    The JBProjects contract address.
  */
  IJBProjects public immutable override jbProjects;

  /** 
    @notice
    The ENS text resolver contract address.
  */
  ITextResolver public immutable override ensTextResolver;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /** 
    @notice 
    Returns the handle for a Juicebox project.

    @dev 
    Requires a TXT record for the `TEXT_KEY` that matches the `_projectId`.

    @param _projectId The ID of the Juicebox project to get the handle of.

    @return The project's handle.
  */
  function handleOf(uint256 _projectId) external view override returns (string memory) {
    ENSName memory ensName = _ensNameOf[_projectId];

    // Return empty string if no ENS name set
    if (_isEmptyString(ensName.name)) return '';

    string memory reverseId = ensTextResolver.text(_namehash(ensName), TEXT_KEY);

    // Return empty string if reverseId from ENS name doesn't match projectId
    if (_stringToUint(reverseId) != _projectId) return '';

    return _formatEnsName(ensName);
  }

  /** 
    @notice 
    The ensName of Juicebox project.

    @param _projectId The ID of the Juicebox project to get the ENS name of.

    @return The ENS name for a project.
  */
  function ensNameOf(uint256 _projectId) external view override returns (ENSName memory) {
    return _ensNameOf[_projectId];
  }

  //*********************************************************************//
  // ---------------------------- constructor -------------------------- //
  //*********************************************************************//

  /** 
    @param _jbProjects A contract which mints ERC-721's that represent project ownership and transfers.
    @param _jbOperatorStore A contract storing operator assignments.
    @param _ensTextResolver The ENS text resolver contract address.
  */
  constructor(
    IJBProjects _jbProjects,
    IJBOperatorStore _jbOperatorStore,
    ITextResolver _ensTextResolver
  ) JBOperatable(_jbOperatorStore) {
    jbProjects = _jbProjects;
    ensTextResolver = _ensTextResolver;
  }

  //*********************************************************************//
  // --------------------- external transactions ----------------------- //
  //*********************************************************************//

  /** 
    @notice 
    Sets a reverse record for a Juicebox project.

    @dev
    The caller must be the project's owner, or a operator.

    @param _projectId The ID of the Juicebox project to set an ENS handle for.
    @param _name The ENS domain to use as project handle, excluding the trailing .eth.
  */
  function setEnsNameFor(uint256 _projectId, string calldata _name) external override {
    _setEnsNameFor(_projectId, ENSName({name: _name, subdomain: ''}));
  }

  /** 
    @notice 
    Sets a reverse record for a Juicebox project including a subdomain.

    @dev
    The caller must be the project's owner, or a operator.

    @param _projectId The ID of the Juicebox project to set an ENS handle for.
    @param _name The ENS domain to use as project handle, excluding the trailing .eth.
    @param _subdomain The subdomain to include in project handle.
  */
  function setEnsNameWithSubdomainFor(
    uint256 _projectId,
    string calldata _name,
    string calldata _subdomain
  ) external override {
    _setEnsNameFor(_projectId, ENSName({name: _name, subdomain: _subdomain}));
  }

  //*********************************************************************//
  // ------------------------ internal functions ----------------------- //
  //*********************************************************************//

  /** 
    @notice 
    Set a reverse record for a Juicebox project.

    @dev
    The caller must be the project's owner, or a operator.

    @param _projectId The ID of the Juicebox project to set an ENS handle for.
    @param _name The ENS domain to use as project handle, excluding the trailing .eth.
  */
  function _setEnsNameFor(uint256 _projectId, ENSName memory _name)
    internal
    requirePermission(
      jbProjects.ownerOf(_projectId),
      _projectId,
      JBHandlesOperations.SET_ENS_NAME_FOR
    )
  {
    _ensNameOf[_projectId] = _name;

    emit SetEnsName(_projectId, _formatEnsName(_name));
  }

  /** 
    @notice 
    Converts a string to a uint256.

    @param _numstring The number string to be converted.

    @return result The uint converted from string.
  */
  function _stringToUint(string memory _numstring) internal pure returns (uint256 result) {
    result = 0;
    bytes memory stringBytes = bytes(_numstring);
    for (uint256 i = 0; i < stringBytes.length; i++) {
      uint256 exp = stringBytes.length - i;
      bytes1 ival = stringBytes[i];
      uint8 uval = uint8(ival);
      uint256 jval = uval - uint256(0x30);

      result += (uint256(jval) * (10**(exp - 1)));
    }
  }

  /** 
    @notice 
    Returns a namehash for an ENS name.

    @dev 
    See https://eips.ethereum.org/EIPS/eip-137.

    @param _ensName The ENS name to hash.

    @return namehash The namehash for an ensName.
  */
  function _namehash(ENSName memory _ensName) internal pure returns (bytes32 namehash) {
    namehash = 0x0000000000000000000000000000000000000000000000000000000000000000;
    namehash = keccak256(abi.encodePacked(namehash, keccak256(abi.encodePacked('eth'))));
    namehash = keccak256(abi.encodePacked(namehash, keccak256(abi.encodePacked(_ensName.name))));
    if (!_isEmptyString(_ensName.subdomain))
      namehash = keccak256(
        abi.encodePacked(namehash, keccak256(abi.encodePacked(_ensName.subdomain)))
      );
  }

  /** 
    @notice 
    Formats an ENS struct into string.

    @param _ensName The ENS name to format.

    @return ensName The formatted ENS name.
  */
  function _formatEnsName(ENSName memory _ensName) internal pure returns (string memory ensName) {
    if (!_isEmptyString(_ensName.subdomain))
      ensName = string(abi.encodePacked(_ensName.subdomain, '.', _ensName.name));
    else ensName = _ensName.name;
  }

  /** 
    @notice 
    Returns true if string is empty.

    @param _str The string to check if empty

    @return True if string is empty.
  */
  function _isEmptyString(string memory _str) internal pure returns (bool) {
    return bytes(_str).length == 0;
  }
}
