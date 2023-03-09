// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ENSRegistry.sol";

contract ENSResolver {
    event AddrChanged(bytes32 indexed node, address addr);

    address owner;
    ENSRegistry registry;
    mapping(bytes32 => address) addresses;

    constructor(ENSRegistry _registry) {
        owner = msg.sender;
        registry = _registry;
    }

    /**
     * @notice ERC-165 표준을 준수여부를 확인한다.
     * @param _interfaceID 인터페이스 ID
     */
    function supportsInterface(bytes4 _interfaceID) public pure returns (bool) {
        return _interfaceID == 0x01ffc9a7 || _interfaceID == 0x3b3b57de;
    }

    /**
     * @notice 노드에 매핑된 주소를 반환한다.
     * @param _node node
     */
    function addr(bytes32 _node) public view returns (address) {
        return addresses[_node];
    }

    /**
     * @notice 노드에 주소를 매핑한다.
     * @param _node node
     * @param _addr 주소
     */
    function setAddr(bytes32 _node, address _addr) public {
        require(
            msg.sender == registry.owner(_node),
            "ENSResolver: unauthorized owner"
        );

        emit AddrChanged(_node, _addr);

        addresses[_node] = _addr;
    }
}
