// SPDX-License-Identifier: GPL-3.0

/// @title Interface for JBProjectHandles

pragma solidity ^0.8.13;

interface IJBProjectHandles {
    event SetReverseRecord(uint256 indexed projectId, bytes32 indexed record);

    function setReverseRecord(uint256 projectId, bytes32 record) external;

    function reverseRecordOf(uint256 projectId)
        external
        view
        returns (bytes32 reverseRecord);

    function handleOf(uint256 projectId) external view returns (bytes32);
}
