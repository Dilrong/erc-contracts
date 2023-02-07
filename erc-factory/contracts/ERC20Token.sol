// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Token is ERC20 {
    event Mint(
        string name,
        string symbol,
        uint256 initialSupply,
        address indexed owner
    );

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply,
        address _owner
    ) ERC20(_name, _symbol) {
        _mint(_owner, _initialSupply * 10 ** uint256(_decimals));

        emit Mint(_name, _symbol, _initialSupply, _owner);
    }
}
