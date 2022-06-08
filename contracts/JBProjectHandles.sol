// SPDX-License-Identifier: MIT

/// @title JBProjectHandles
/// @author peri
/// @notice Manages reverse records that point from JB project IDs to ENS nodes. If the reverse record of a project ID is pointed to an ENS node with a TXT record matching the ID of that project, then the ENS node will be considered the "handle" for that project.

pragma solidity 0.8.6;

import "@ensdomains/ens-contracts/contracts/resolvers/profiles/ITextResolver.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@jbx-protocol/contracts-v2/contracts/abstract/JBOperatable.sol";
import "@jbx-protocol/contracts-v2/contracts/interfaces/IJBProjects.sol";
import "@jbx-protocol/contracts-v2/contracts/interfaces/IJBOperatorStore.sol";
import "./interfaces/IJBProjectHandles.sol";
import "./libraries/JBOperations.sol";

error NotJuiceboxProjectOwner(uint256 projectId, address owner);

contract JBProjectHandles is IJBProjectHandles, JBOperatable {
    /* -------------------------------------------------------------------------- */
    /* ------------------------------ CONSTRUCTOR ------------------------------- */
    /* -------------------------------------------------------------------------- */

    constructor(
        IJBProjects _jbProjects,
        address _ensTextResolver,
        IJBOperatorStore _jbOperatorStore
    ) JBOperatable(_jbOperatorStore) {
        jbProjects = _jbProjects;
        ensTextResolver = _ensTextResolver;
    }

    /* -------------------------------------------------------------------------- */
    /* ------------------------------- VARIABLES -------------------------------- */
    /* -------------------------------------------------------------------------- */

    /// Key of ENS text record
    string public constant TEXT_KEY = "juicebox";

    /// JB Projects contract address
    IJBProjects public immutable jbProjects;

    /// ENS text resolver contract address
    address public immutable ensTextResolver;

    /// Mapping of project ID to ENS name
    mapping(uint256 => ENSName) ensNames;

    /* -------------------------------------------------------------------------- */
    /* --------------------------- EXTERNAL FUNCTIONS --------------------------- */
    /* -------------------------------------------------------------------------- */

    /// @notice Set reverse record for Juicebox project
    /// @dev Requires sender to own Juicebox project
    /// @param projectId ID of Juicebox project
    /// @param name ENS domain to use as project handle, excluding .eth.
    function setEnsNameFor(uint256 projectId, string calldata name)
        external
        override
    {
        _setEnsNameFor(projectId, ENSName({name: name, subdomain: ""}));
    }

    /// @notice Set reverse record for Juicebox project
    /// @dev Requires sender to own Juicebox project
    /// @param projectId ID of Juicebox project
    /// @param name ENS name to use as project handle, excluding .eth.
    /// @param subdomain Include subdomain in project handle.
    function setEnsNameWithSubdomainFor(
        uint256 projectId,
        string calldata name,
        string calldata subdomain
    ) external override {
        _setEnsNameFor(projectId, ENSName({name: name, subdomain: subdomain}));
    }

    /// @notice Returns ensName of Juicebox project
    /// @param projectId id of Juicebox project
    /// @return ensName for project
    function ensNameOf(uint256 projectId)
        public
        view
        override
        returns (ENSName memory ensName)
    {
        ensName = ensNames[projectId];
    }

    /// @notice Returns ensName for Juicebox project
    /// @dev Requires ensName to have TXT record matching projectId
    /// @param projectId id of Juicebox project
    /// @return ensName for project
    function handleOf(uint256 projectId)
        public
        view
        override
        returns (string memory)
    {
        ENSName memory ensName = ensNameOf(projectId);

        // Return empty string if no ENS name set
        if (isEmptyString(ensName.name) && isEmptyString(ensName.subdomain)) {
            return "";
        }

        string memory reverseId = ITextResolver(ensTextResolver).text(
            namehash(ensName),
            TEXT_KEY
        );

        // Return empty string if reverseId from ENS name doesn't match projectId
        if (stringToUint(reverseId) != projectId) {
            return "";
        }

        return formatEnsName(ensName);
    }

    /* -------------------------------------------------------------------------- */
    /* --------------------------- INTERNAL FUNCTIONS --------------------------- */
    /* -------------------------------------------------------------------------- */

    /// @notice Set reverse record for Juicebox project
    /// @dev Requires sender to own or operate the Juicebox project
    /// @param projectId ID of Juicebox project
    /// @param ensName ENS name to use as project handle, excluding .eth.
    function _setEnsNameFor(uint256 projectId, ENSName memory ensName)
        internal
        requirePermission(
            jbProjects.ownerOf(projectId),
            projectId,
            JBOperations.SET_ENS_NAME_FOR
        )
    {
        ensNames[projectId] = ensName;

        emit SetEnsName(projectId, formatEnsName(ensName));
    }

    /// @notice Converts string to uint256
    /// @param numstring number string to be converted
    /// @return result uint conversion from string
    function stringToUint(string memory numstring)
        internal
        pure
        returns (uint256 result)
    {
        result = 0;
        bytes memory stringBytes = bytes(numstring);
        for (uint256 i = 0; i < stringBytes.length; i++) {
            uint256 exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
            uint256 jval = uval - uint256(0x30);

            result += (uint256(jval) * (10**(exp - 1)));
        }
    }

    /// @notice Returns namehash for ENS name
    /// @dev https://eips.ethereum.org/EIPS/eip-137
    /// @param ensName ENS name to hash
    /// @return _namehash namehash for ensName
    function namehash(ENSName memory ensName)
        internal
        pure
        returns (bytes32 _namehash)
    {
        _namehash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        _namehash = keccak256(
            abi.encodePacked(_namehash, keccak256(abi.encodePacked("eth")))
        );
        _namehash = keccak256(
            abi.encodePacked(
                _namehash,
                keccak256(abi.encodePacked(ensName.name))
            )
        );
        if (!isEmptyString(ensName.subdomain)) {
            _namehash = keccak256(
                abi.encodePacked(
                    _namehash,
                    keccak256(abi.encodePacked(ensName.subdomain))
                )
            );
        }
    }

    /// @notice Formats ENS struct into string
    /// @param ensName ENS name to format
    /// @return _ensName formatted ENS name
    function formatEnsName(ENSName memory ensName)
        internal
        pure
        returns (string memory _ensName)
    {
        if (!isEmptyString(ensName.subdomain)) {
            _ensName = string(
                abi.encodePacked(ensName.subdomain, ".", ensName.name)
            );
        } else {
            _ensName = ensName.name;
        }
    }

    /// @notice Returns true if string is empty
    /// @param str String to check if empty
    /// @return true if string is empty
    function isEmptyString(string memory str) internal pure returns (bool) {
        return bytes(str).length == 0;
    }
}
