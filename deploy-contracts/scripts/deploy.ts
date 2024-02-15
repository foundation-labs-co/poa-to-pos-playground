const { ethers } = require("hardhat");


async function main() {
    console.log("📡 Deploy \n");
    console.log(ethers)

    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    let contractFactory = await ethers.getContractFactory('DepositContract');
    contractFactory = contractFactory.connect(deployer);
    let contract = await contractFactory.deploy();
    console.log("Contract deployed to address:", contract.target);

    console.log("Deploy Success")
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
