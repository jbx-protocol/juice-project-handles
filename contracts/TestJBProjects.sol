// SPDX-License-Identifier: MIT

/// @notice Test ERC721 contract. Includes a single function `mint` allowing a token to be minted to any wallet for free.

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestJBProjects is ERC721 {
    uint256 public supply;

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    function mint(address to) external {
        _mint(to, supply + 1);
        supply++;
    }
}
