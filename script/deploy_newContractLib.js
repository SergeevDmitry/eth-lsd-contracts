const { ethers, network } = require("hardhat")
const { Wallet } = ethers

console.log("ethers version:", ethers.version)

// $ npx hardhat run --network holesky ./script/deploy_newContractLib.js
async function main() {
    const networkAdmin = new Wallet(process.env.NETWORK_ADMIN_PRIVATE_KEY, ethers.provider)
    console.log("deployer", networkAdmin.address);

     // Library deployment
    const lib = await ethers.getContractFactory("NewContractLib", networkAdmin);
    const libInstance = await lib.deploy();
    await libInstance.waitForDeployment()
    console.log("NewContractLib Address: " + await libInstance.getAddress())
    console.log("Run below command to verify it \n$ npx hardhat verify --network holesky ", await libInstance.getAddress())
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error)
        process.exit(1)
    })
