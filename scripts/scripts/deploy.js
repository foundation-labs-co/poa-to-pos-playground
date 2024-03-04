const { ethers } = require("hardhat");

async function main() {
  console.log("📡 Deploy \n");

  const [signer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", signer.address);

  let contractFactory = await ethers.getContractFactory("DepositContract");
  contractFactory = contractFactory.connect(signer);
  let contract = await contractFactory.deploy();
  console.log("Contract deployed to address:", contract.address);
  // const transactionReceipt = await contract.deploymentTransaction().wait(1);
  // console.log("deployed at:", transactionReceipt.blockNumber);
  const hashOfTx = contract.deployTransaction.hash;
  let contractDeployed = await contract.deployed();

  let txReceipt = await contractDeployed.provider.getTransactionReceipt(
    hashOfTx
  );
  console.log("deployed at:", txReceipt.blockNumber);

  console.log("Deploy Success");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
