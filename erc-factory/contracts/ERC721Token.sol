// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ERC721Token is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    event newMint(uint256 indexed newTokenId);

    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {}

    function newNft(
        address issuer,
        string memory tokenURI
    ) public returns (uint256) {
        _tokenIds.increment();

        uint256 newTokenId = _tokenIds.current();
        _mint(issuer, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        emit newMint(newTokenId);

        return newTokenId;
    }
}
