export const getEthChainInfo = () => {
    // let chainId: number = 42;
    // let rpcUrl: string = 'https://kovan.infura.io/v3/e707b58edfd7437cbb6e9079c259eda7/';
    // let ethscanType: string = 'kovan.';
    let chainId: number = 8217;
    let rpcUrl: string = 'https://public-node-api.klaytnapi.com/v1/cypress';
    let ethscanType: string = 'klay.';

    const href = window.location.href;
    if (/\/\/farm.deor.io/.test(href)) {
        //  chainId = 1;
        //  rpcUrl = 'https://mainnet.infura.io/v3/e707b58edfd7437cbb6e9079c259eda7/';
        //  ethscanType = '';
        chainId = 21004;
        rpcUrl = 'https://rpc.c4ei.net/';
        ethscanType = 'c4ei.';
    }
    return {
        chainId,
        rpcUrl,
        ethscanType
    }
};
