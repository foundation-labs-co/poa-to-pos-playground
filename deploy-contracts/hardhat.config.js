/** @type import('hardhat/config').HardhatUserConfig */
require("dotenv").config();
require("@nomicfoundation/hardhat-ethers");


module.exports = {
  solidity: {
    version: "0.6.11",
  },
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545/",
      chainId: 1112,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },
  }
};