// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract ERC721Token is ERC721Enumerable, Pausable, Ownable {
    using Strings for uint256;

    uint256 public immutable maxSupply;

    string public baseURI;

    /**
     * @notice Constructor
     * @param _name: NFT 이름
     * @param _symbol: NFT 심볼
     * @param _maxSupply: NFT 총발행량
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply
    ) ERC721(_name, _symbol) {
        maxSupply = _maxSupply;
    }

    /**
     * @notice 민팅한다.
     * @param _to: 토큰을 받는 주소
     * @param _tokenId: 토큰 아이디
     */
    function mint(address _to, uint256 _tokenId) external onlyOwner {
        require(totalSupply() < maxSupply, "NFT: Total supply reached");
        _safeMint(_to, _tokenId);
    }

    /**
     * @notice 기본 uri를 설정한다.
     * @param _uri: base uri
     */
    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    /**
     * @notice 토큰 아이디에 해당하는 URI를 반환한다.
     * @param tokenId: 토큰 아이디
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }
}
