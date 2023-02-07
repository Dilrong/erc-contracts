// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import "./ERC20Token.sol";
import "./ERC721Token.sol";
import "./interfaces/IERCFactory.sol";

contract ERCFactory is IERCFactory, Ownable {
    address public adminAddress;

    event ERC20TokenCreated(address tokenAddress);
    event ERC721TokenCreated(address tokenAddress);

    event UpdateAdmin(address indexed adminAddress);

    constructor(address _adminAddress) {
        require(
            _adminAddress != address(0),
            "Operations: Admin address cannot be zero"
        );

        adminAddress = _adminAddress;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Management: Not admin");
        _;
    }

    /**
     * @notice ERC20 컨트랙트를 배포한다.
     * @param name: 이름
     * @param symbol: 심볼
     * @param decimals: 자릿수
     * @param initialSupply: 초기공급량
     */
    function deployNewERC20Token(
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 initialSupply
    ) external onlyAdmin returns (address) {
        ERC20Token token = new ERC20Token(
            name,
            symbol,
            decimals,
            initialSupply,
            msg.sender
        );
        emit ERC20TokenCreated(address(token));

        return address(token);
    }

    /**
     * @notice ERC721 컨트랙트를 배포한다.
     * @param _name: 이름
     * @param _symbol: 심볼
     * @param _maxSupply: 총 발행량
     */
    function deployNewERC721Token(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply
    ) external onlyAdmin returns (address) {
        ERC721Token token = new ERC721Token(_name, _symbol, _maxSupply);
        emit ERC721TokenCreated(address(token));

        return address(token);
    }

    /**
     * @notice 어드민 주소를 변경한다.
     * @param _adminAddress: 어드민 주소
     */
    function updateAdmin(address _adminAddress) external onlyOwner {
        require(
            _adminAddress != address(0),
            "Operations: Admin address cannot be zero"
        );

        adminAddress = _adminAddress;

        emit UpdateAdmin(_adminAddress);
    }
}
