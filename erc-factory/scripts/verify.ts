import hre from "hardhat";

// hre.run("verify:verify", {
//   address: "0x381b54d8bffc70d2c094d5be0bb37a804f9c2db5",
//   contract: "contracts/ERC20Token.sol:ERC20Token",
//   constructorArguments: [
//     "test20",
//     "test20",
//     10,
//     20,
//     "0xCBdAcb9d814DF5D65850CD004D1B5298B6918728",
//   ],
// });

hre.run("verify:verify", {
  address: "0xcC5b28693A60429E45ae4581EBC87Da640112cd6",
  contract: "contracts/ERC721Token.sol:ERC721Token",
  constructorArguments: [
    "test721",
    "test721",
    100,
    "0xCBdAcb9d814DF5D65850CD004D1B5298B6918728",
  ],
});
