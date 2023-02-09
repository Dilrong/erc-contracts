// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract ERC721Token is ERC721Enumerable, Ownable {
    using Strings for uint256;

    address public adminAddress;

    uint256 public immutable maxSupply;

    string public baseURI;

    event Mint(address indexed to, uint256 tokenId);
    event SetBaseURI(string uri);
    event UpdateAdmin(address indexed adminAddress);

    /**
     * @notice Constructor
     * @param _name: NFT 이름
     * @param _symbol: NFT 심볼
     * @param _maxSupply: NFT 총발행량
     * @param _adminAddress: 어드민 주소
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        address _adminAddress
    ) ERC721(_name, _symbol) {
        require(
            (_maxSupply == 100) ||
                (_maxSupply == 1000) ||
                (_maxSupply == 10000),
            "Operations: Wrong max supply"
        );
        maxSupply = _maxSupply;
        adminAddress = _adminAddress;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Management: Not admin");
        _;
    }

    /**
     * @notice 민팅한다.
     * @param _to: 토큰을 받는 주소
     * @param _tokenId: 토큰 아이디
     */
    function mint(address _to, uint256 _tokenId) external onlyAdmin {
        require(totalSupply() < maxSupply, "Nft: Total supply reached");
        _safeMint(_to, _tokenId);

        emit Mint(_to, _tokenId);
    }

    /**
     * @notice 기본 uri를 설정한다.
     * @param _uri: base uri
     */
    function setBaseURI(string memory _uri) external onlyAdmin {
        baseURI = _uri;

        emit SetBaseURI(_uri);
    }

    /**
     * @notice 토큰 아이디에 해당하는 URI를 반환한다.
     * @param _tokenId: 토큰 아이디
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, _tokenId.toString(), ".json")
                )
                : "";
    }

    /**
     * @notice 어드민 주소를 변경한다.
     * @param _adminAddress: 어드민 주소
     */
    function updateAdmin(address _adminAddress) external onlyAdmin {
        require(
            _adminAddress != address(0),
            "Operations: Admin address cannot be zero"
        );

        adminAddress = _adminAddress;

        emit UpdateAdmin(_adminAddress);
    }
}
