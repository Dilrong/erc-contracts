// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IERCFactory {
    function deployNewERC20Token(
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 initialSupply
    ) external returns (address);

    function deployNewERC721Token(
        string memory name,
        string memory symbol
    ) external returns (address);
}
