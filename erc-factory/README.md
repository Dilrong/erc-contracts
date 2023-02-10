# ERC Factory

ERC Create Factory Contract

## Setup

```
PRIVATE_KEY=
ETHERSCAN_KEY=
POLYGONSCAN_KEY=
DEV_ALCHEMY_KEY=
PROD_ALCHEMY_KEY=
ADMIN_ADDRESS=
```

## Get Started

### Ether

```
npm run deploy:mainnet
npm run deploy:testnet
```

### Polygon

```
npm run deploy:polygon
npm run deploy:mumbai
```

## Get Test

```
npm run test
```

## Get Verify

```
npm run compile
npx hardhat verify --network testnet ${contract address}
```

### Deployed Token

```
npx hardhat run --network testnet .\scripts\verify.ts
```

## Contract Address

### Goerli

```
0x756310aa6Db46B2F96bE8905ED0E059472FfFE38
```

### mumbai

```
0xA41bFD9016c2E77f714408b513d75B9541B34Aa3
```
