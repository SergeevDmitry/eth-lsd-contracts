const { ethers, network } = require("hardhat")
const { Wallet } = ethers

console.log("ethers version:", ethers.version)

// $ npx hardhat run --network holesky ./script/deploy_network_proposal_logic.js
async function main() {
    const networkAdmin = new Wallet(process.env.NETWORK_ADMIN_PRIVATE_KEY, ethers.provider)
    console.log("deployer", networkAdmin.address);

     // Library deployment
    const NetworkProposal = await ethers.getContractFactory("NetworkProposal", {
        signer: networkAdmin,
    });
    const ins = await NetworkProposal.deploy();
    await ins.waitForDeployment()
    console.log("NetworkProposal logic Address: " + await ins.getAddress())
    console.log("Run below command to verify the code\n$ npx hardhat verify --network holesky ", await ins.getAddress())
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error)
        process.exit(1)
    })
