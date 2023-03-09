// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract ENSRegistry {
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);
    event Transfer(bytes32 indexed node, address owner);
    event NewResolver(bytes32 indexed node, address resolver);

    struct Record {
        address owner;
        address resolver;
        uint64 ttl;
    }

    mapping(bytes32 => Record) records;

    constructor(address _owner) {
        records[0].owner = _owner;
    }

    /**
     * @notice 소유자를 반환한다.
     * @param _node node
     */
    function owner(bytes32 _node) public view returns (address) {
        return records[_node].owner;
    }

    /**
     * @notice resolver를 반환한다.
     * @param _node node
     */
    function resolver(bytes32 _node) public view returns (address) {
        return records[_node].resolver;
    }

    /**
     * @notice ttl를 반환한다.
     * @param _node node
     */
    function ttl(bytes32 _node) public view returns (uint64) {
        return records[_node].ttl;
    }

    /**
     * @notice ENS 레코드 존배 여부를 반환한다.
     * @param _node node
     */
    function recordExists(bytes32 _node) external view virtual returns (bool) {
        return records[_node].owner != address(0);
    }

    /**
     * @notice 소유자를 설정한다.
     * @param _node node
     * @param _owner 소유자
     */
    function setOwner(bytes32 _node, address _owner) public {
        Record storage record = records[_node];

        require(msg.sender == record.owner, "Registry: unauthorized owner");

        emit Transfer(_node, _owner);

        record.owner = _owner;
    }

    /**
     * @notice 소유자를 변경한다.
     * @param _node node
     * @param _label 라벨
     * @param _owner 소유자
     */
    function setSubnodeOwner(
        bytes32 _node,
        bytes32 _label,
        address _owner
    ) public {
        require(
            msg.sender == records[_node].owner,
            "Registry: unauthorized owner"
        );

        emit NewOwner(_node, _label, _owner);

        records[keccak256(abi.encodePacked(_node, _label))].owner = _owner;
    }

    /**
     * @notice Resolver를 설정한다.
     * @param _node node
     * @param _resolver resolver
     */
    function setResolver(bytes32 _node, address _resolver) public {
        Record storage record = records[_node];

        require(msg.sender == record.owner, "Registry: unauthorized owner");

        emit NewResolver(_node, _resolver);

        record.resolver = _resolver;
    }

    /**
     * @notice ttl을 설정한다.
     * @param _node node
     * @param _ttl ttl
     */
    function setTTL(bytes32 _node, uint64 _ttl) public {
        Record storage record = records[_node];

        require(msg.sender == record.owner, "Registry: unauthorized owner");

        record.ttl = _ttl;
    }
}
