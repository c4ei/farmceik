const HDWalletProvider = require("@truffle/hdwallet-provider");
require('dotenv').config();

const provider = new HDWalletProvider({ 
  privateKeys:[process.env.PK]
  ,providerOrUrl:'https://public-node-api.klaytnapi.com/v1/cypress'}
  )

module.exports = {
    networks: {
        // development: {
        //     host: "localhost",
        //     port: 7545,
        //     network_id: "*"
        // },
        // test: {
        //     host: "localhost",
        //     port: 8545,
        //     network_id: "*"
        // },
        mainnet: {
            url: "https://public-node-api.klaytnapi.com/v1/cypress",
            provider: provider,
            network_id: '8217', //Klaytn baobab testnet's network id
            gas: '8500000',
            gasPrice:'25000000000'
            // gasPrice:'725000000000'
        },
        // mainnet: {
        //     provider: function() {
        //         return new HDWalletProvider(
        //             process.env.MNEMONIC,
        //             `https://mainnet.infura.io/v3/${process.env.INFURA_ID}`
        //         )
        //     },
        //     network_id: 1
        // },
        // kovan: {
        //     provider: function() {
        //         return new HDWalletProvider(
        //             process.env.MNEMONIC,
        //             `https://kovan.infura.io/v3/${process.env.INFURA_ID}`
        //         )
        //     },
        //     network_id: 42
        // }
    },

    compilers: {
        solc: {
            version: "0.6.12",
            optimizer: {
                enabled: true,
                runs: 200
            }
        }
    },

    plugins: [
        'truffle-plugin-verify'
    ],

    api_keys: {
        etherscan: process.env.ETHERSCAN_API_KEY
    }
};
