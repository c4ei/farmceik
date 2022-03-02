# DEOR Uniswap liquidity staking

This project is copied from [sashimiswap](https://github.com/SashimiProject/sashimiswap) and modified to work with
non-mintable tokens.

# Quickstart

## Installation

```
npm install
```

## Run tests

```
npm test
```

## Configuration

Create a `.env` file with keys

```
MNEMONIC="..."
INFURA_ID="..."
ETHERSCAN_API_KEY="..."
```

* Deployment to rinkeby is done via [Infura](https://infura.io/).
* Create an [Etherscan API key](https://etherscan.io/myapikey) for contract verification.

_Forks of this project should also modify `config.json`. Decimals aren't considered in the configuration._

## Deployment

### Ganache

[Ganache](https://www.trufflesuite.com/ganache) is a personal Ethereum blockchain for development and
tests.

```
npm run migrate -- --network development
```

### Rinkeby

To deploy on the [Rinkeby](https://rinkeby.io/) Ethereum testnet, make sure your wallet has enough ETH to pay for the
GAS.

[Faucet 1](https://testnet.help/en/ethfaucet/rinkeby) | [Faucet 2](https://faucet.rinkeby.io/)

```
npm run migrate -- --network rinkeby
npm run verify -- --network rinkeby
```

You may also want to verify the ERC20Mock and LPMock contracts on Etherscan.

```
node_modules/.bin/truffle verify ERC20Mock
node_modules/.bin/truffle verify LPMock
```

_Verification may fail because of rate limits. Just try again._

### Ethereum mainnet

```
npm run migrate -- --network mainnet
npm run verify -- --network mainnet
```

The account that is used to create the Farm contract should have a sufficient amount of (DEOR) ERC20 to fund the
contract. Alternatively; to manually fund, remove the 'fund' property from the configuration.
Farm 계약을 생성하는 데 사용되는 계정에는 자금을 조달할 수 있는 충분한 양의 (DEOR) ERC20이 있어야 합니다.
계약. 대안으로; 수동으로 자금을 조달하려면 구성에서 'fund' 속성을 제거하십시오.

# How it works

The `Farm` contract will distribute ERC20 tokens to participants relative to the number of LP tokens deposited to the
contract. These ERC20 tokens aren't minted. Instead, the contract needs to be funded.
# 작동 원리

'Farm' 계약은 ERC20 토큰을 참여자에게 예치된 LP 토큰 수에 비례하여 분배합니다.
계약. 이 ERC20 토큰은 발행되지 않습니다. 대신 계약에 자금이 필요합니다.

## Creation

The address of the ERC20 token, the reward per block, and the starting block are specified in the constructor of the
`Farm` contract.
## 창조

ERC20 토큰의 주소, 블록당 보상, 시작 블록은 생성자에서 지정됩니다.
'농장' 계약.

## Fund

The contract needs to be funded before the start block. 

To fund the contract, the `Farm` must be allowed to withdraw the amount of ERC20 using the `approve` method of the ERC20
contract.

Call the `fund` method with the appropriate amount The end block is calculated as

    endBlock = startBlock + (funds / rewardPerBlock)

It's possible to add funds with the farm is running and increase the end block.
 
If the end block is reached, the farm is closed and it will no longer be possible to add funds.   
## 펀드

계약은 시작 블록 전에 자금을 조달해야 합니다.
계약 자금을 조달하려면 'Farm'이 ERC20의 '승인' 방법을 사용하여 ERC20 금액을 인출할 수 있어야 합니다.
계약.
적절한 금액으로 'fund' 메소드를 호출합니다. 엔드 블록은 다음과 같이 계산됩니다.
    endBlock = startBlock + (자금 / rewardPerBlock)
농장이 운영되고 있는 상태에서 자금을 추가하고 엔드 블록을 늘릴 수 있습니다.
엔드 블록에 도달하면 농장이 폐쇄되고 더 이상 자금을 추가할 수 없습니다.

## Adding liquidity pairs

Tokens are distributes amount users that has deposited specific LP tokens. These LP tokens are distributed by the
Uniswap contract for providing liqidity. _Other LP tokens could be used as well._

Each LP token has a specific contract address which can be found on the [Uniswap exchange](https://info.uniswap.org/).

Use the `add` method to add a liquidity pair for which the farm will pay out a reward.

It's possible to add liquidity pairs at a later time. The reward is shared over all pairs.
## 유동성 쌍 추가

토큰은 특정 LP 토큰을 예치한 사용자에게 금액을 분배합니다. 이 LP 토큰은
유동성 제공을 위한 Uniswap 계약. _다른 LP 토큰도 사용할 수 있습니다._
각 LP 토큰에는 [Uniswap exchange](https://info.uniswap.org/)에서 찾을 수 있는 특정 계약 주소가 있습니다.
농장이 보상을 지급할 유동성 쌍을 추가하려면 `add` 방법을 사용하십시오.
나중에 유동성 쌍을 추가할 수 있습니다. 보상은 모든 쌍에서 공유됩니다.

### AllocPoint

The `add` method takes an `allocPoint` parameter. When adding multiple pairs, this decides the portion of the reward
shared for that LP token.
'add' 메소드는 'allocPoint' 매개변수를 사용합니다. 여러 쌍을 추가할 때 보상의 부분을 결정합니다.
해당 LP 토큰에 대해 공유됩니다.

**Example:** the farm is configured for 3 pairs with an `allocPoint` of resp 6, 12, 18. The
total alloc points is 36. 1/6th of the tokens is distributed under participants that deposited the pair with 6
alloc points: (`6 / 36 = 1/6`). 
**예:** 팜은 'allocPoint'가 resp 6, 12, 18인 3쌍으로 구성됩니다.
총 할당 포인트는 36입니다. 토큰의 1/6은 6으로 쌍을 입금한 참가자 아래에 분배됩니다.
할당 포인트: (`6 / 36 = 1/6`).

It's possible to change the alloc points at a later time via the `update` method.
'업데이트' 방법을 통해 나중에 할당 포인트를 변경할 수 있습니다.

## Deposit and withdraw

To participate in farming, users must deposit LP tokens using the `deposit` method.

Before using this method, the farm must be allowed to withdraw the LP tokens. This is done via the `approve` method on
the LP token contract.

The current deposit can be check using the `deposited` method. 

Participants can withdraw their LP tokens at any time using the `withdraw` method.
## 입출금

파밍에 참여하기 위해서는 '입금' 방식으로 LP 토큰을 입금해야 합니다.

이 방법을 사용하기 전에 농장에서 LP 토큰을 인출할 수 있어야 합니다. 이것은 의 '승인' 메소드를 통해 수행됩니다.
LP 토큰 계약.

현재 입금액은 '입금' 방식으로 확인할 수 있습니다.

참여자는 '인출' 방식을 사용하여 언제든지 LP 토큰을 출금할 수 있습니다.

## Reward

Each participant has a pending reward which is hold by the farm. The pending reward can be checked using the `pending`
method.

Any change to the deposit of the participant (with `deposit` or `withdraw`), will pay out the pending reward. It's
possible to do a zero withdraw to just receive the pending reward.

# Frontend

The `frontend` folder contains the frontend application that displays the uniswap pairs and allows users to participate.

_Note that the frontend is specifically styled and configured for DEOR. You need to modify it to use it for a
different project._  

/home/dev/www/farmceik/config.json
-----------------------------------------------
https://public-node-api.klaytnapi.com/v1/cypress
8217
https://scope.klaytn.com
-----------------------------------------------

클레이튼+세이크 POOL
https://klayswap.com/exchange/pool/detail/0x50e746edaa283365136ed86a4e5dfddc6cd3cf9e
클레이튼+세이크 LP (KSLP) Address : 0x50E746EdaA283365136ed86a4E5DfDdc6CD3cF9e
CEIK Address : 0x18814b01b5cc76f7043e10fd268cc4364df47da0 (소수점 8 자리)


클레이스왑+세이크
https://klayswap.com/exchange/pool/detail/0xcc81d437ffc161d349d6186b1a1f8dde515093d6


dev@ubuntu:~/www/farmceik$ truffle version
Truffle v5.4.15 (core: 5.4.15)
Solidity - 0.6.12 (solc-js)
Node v16.13.0
Web3.js v1.5.3

npm install -g truffle@5.0.26

npm run migrate --network mainnet
npm run verify --network mainnet

배포실패
scope.klaytn.com
