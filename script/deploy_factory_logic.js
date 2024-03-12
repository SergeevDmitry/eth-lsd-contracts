const { ethers } = require("hardhat")
const { Wallet } = ethers

console.log("ethers version:", ethers.version)

// $ npx hardhat run --network holesky ./script/deploy_factory_logic.js
async function main() {
    const networkAdmin = new Wallet(process.env.NETWORK_ADMIN_PRIVATE_KEY, ethers.provider)
    console.log("deployer", networkAdmin.address);
    const libAddr = "0x4FbF88A54b87FD6a08756F9A66C021623BCc393e"

     // Library deployment
    const Contract = await ethers.getContractFactory("LsdNetworkFactory", {
        signer: networkAdmin,
        libraries: { "contracts/libraries/NewContractLib.sol:NewContractLib": libAddr }
    });
    const factory = await Contract.deploy();
    await factory.waitForDeployment()
    const factoryAddr = await factory.getAddress()
    console.log("LsdNetworkFactory logic Address:", factoryAddr)
    // console.log("Run below command to verify the code\n$ npx hardhat verify --network holesky ", factoryAddr)

    console.log("Verifying...")
    await hre.run('verify:verify', {
      address: factoryAddr,
    });
    console.log("verified!")
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error)
        process.exit(1)
    })
