// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBProjects.sol';
import '@ensdomains/ens-contracts/contracts/resolvers/profiles/ITextResolver.sol';
import '../structs/ENSName.sol';

interface IJBProjectHandles {
  event SetEnsName(uint256 indexed projectId, string indexed ensName);

  function setEnsNameFor(uint256 _projectId, string calldata _name) external;

  function setEnsNameWithSubdomainFor(
    uint256 _projectId,
    string calldata _name,
    string calldata _subdomain
  ) external;

  function ensNameOf(uint256 _projectId) external view returns (ENSName memory);

  function jbProjects() external view returns (IJBProjects);

  function ensTextResolver() external view returns (ITextResolver);

  function handleOf(uint256 _projectId) external view returns (string memory);
}
