console.log("line 1 - 2_deploy_contracts.js");
const ERC20 = artifacts.require("./ERC20Mock.sol");
const LP = artifacts.require('./LPMock.sol');
const Farm = artifacts.require("./Farm.sol");
const allConfigs = require("../config.json");
// console.log("line 6 - 2_deploy_contracts.js");
module.exports = function(deployer, network, addresses) {
  const config = allConfigs[network.replace(/-fork$/, '')] || allConfigs.default;

  if (!config) {
    return;
  }
  const erc20 = config.erc20;
    let deploy = deployer;
  console.log("line 16");
  if (!erc20.address) {
    deploy = deploy
      .then(() => {
        return deployer.deploy(
          ERC20,
          erc20.name,
          erc20.symbol,
          erc20.decimals,
          web3.utils.toBN(erc20.supply)
        );
      })
      .then(() => {return ERC20.deployed(); });
  }
  console.log("line 30");
  deploy = deploy  
    .then(() => {    
      return web3.eth.getBlockNumber();
    })
    .then((currentBlock) => {
      const startBlock = config.startBlock || web3.utils.toBN(currentBlock).add(web3.utils.toBN(config.delay));

      return deployer.deploy(
        Farm,
        erc20.address || ERC20.address,
        web3.utils.toBN(config.rewardPerBlock),
        startBlock
      );
    });
    console.log("line 45");
    if (config.fund) {
      deploy = deploy
        .then(() => {
          return erc20.address
            ? ERC20.at(erc20.address)
            : ERC20.deployed();
        })
        .then((erc20Instance) => {
          return erc20Instance.approve(Farm.address, web3.utils.toBN(config.fund));
        })
        .then(() => { return Farm.deployed(); })
        .then((farmInstance) => {
          return farmInstance.fund(web3.utils.toBN(config.fund));
        });
    }
    console.log("line 61");
    config.lp.forEach((token) => {
      if (!token.address) {
        deploy = deploy
          .then(() => {
            return deployer.deploy(
              LP,
              token.name,
              token.symbol,
              token.decimals,
            );
          })
          .then(() => {
            return LP.deployed();
          })
          .then((lpInstance) => {
            // const amount = web3.utils.toBN(10).pow(web3.utils.toBN(token.decimals)).mul(web3.utils.toBN(1000));
            // const amount = web3.utils.toBN(18).pow(web3.utils.toBN(token.decimals)).mul(web3.utils.toBN(100000000000));
            // const amount = web3.utils.toBN(8).pow(web3.utils.toBN(token.decimals)).mul(web3.utils.toBN(36500000000)); //365억
            const amount = 3650000000000000000;

            const promises = addresses.map((address) => {
              return lpInstance.mint(address, amount);
            });

            return Promise.all(promises);
          });
      }
      console.log("line 88");
      deploy = deploy
        .then(() => { return Farm.deployed(); })
        .then((farmInstance) => {
          return farmInstance.add(
            token.allocPoint,
            token.address || LP.address,
            false
          );
        });
    });

    return deploy;
};

