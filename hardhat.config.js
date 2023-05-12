require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity:{
    version : "0.8.18",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  } ,
  networks: {
    arbtest: {
      url: `https://goerli-rollup.arbitrum.io/rpc`,
      accounts: [`88bd0e317d9e38be6a17c1af053ba664111253dac61aadcdb488ad2fb64f8d2d`],
    },
  }

};