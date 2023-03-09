// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ENSRegistry.sol";

contract ENSRegistrar {
    bytes32 rootNode;
    ENSRegistry registry;

    constructor(ENSRegistry _registry, bytes32 _node) {
        rootNode = _node;
        registry = _registry;
    }

    /**
     * @notice 하위 도메인에 소유자를 등록한다.
     * @param _subnode 하위 도메인
     * @param _owner 소유자
     */
    function register(bytes32 _subnode, address _owner) public {
        address currentOwner = registry.owner(
            keccak256(abi.encodePacked(rootNode, _subnode))
        );

        require(
            currentOwner == address(0) && currentOwner == msg.sender,
            "ENSRegistrar: unauthorized owner"
        );

        registry.setSubnodeOwner(rootNode, _subnode, _owner);
    }
}
