const { ethers } = require("hardhat")
const { Wallet } = ethers


async function main() {
    console.log(ethers.version)
    this.ContractDepositContractAddress = process.env.DEPOSIT_CONTRACT_ADDRESS;
    console.log("ContractDepositContract address: ", this.ContractDepositContractAddress)

    const networkAdmin = new Wallet(process.env.NETWORK_ADMIN_PRIVATE_KEY, ethers.provider)
    this.AccountDeployer = networkAdmin
    this.AccountFactoryAdmin = networkAdmin

    // // Library deployment: uncomment below to deploy a new lib instance
    // const NewContractLib = await ethers.getContractFactory("NewContractLib", this.AccountDeployer);
    // const newContractLib = await NewContractLib.deploy();
    // console.log(newContractLib)
    // await newContractLib.deployed()
    // const newContractLibAddr = newContractLib.address
    const newContractLibAddr = "0xF41cFAF21e5f55CBFb3712C9F11B8CC0E78e64C8"
    console.log("NewContractLib Address ---> " + newContractLibAddr)

    this.FactoryLsdNetworkFactory = await ethers.getContractFactory("LsdNetworkFactory", {
        signer: this.AccountDeployer,
        libraries: { "contracts/libraries/NewContractLib.sol:NewContractLib": newContractLibAddr }
    })
    this.FactoryFeePool = await ethers.getContractFactory("FeePool", this.AccountDeployer)
    this.FactoryLsdToken = await ethers.getContractFactory("LsdToken", this.AccountDeployer)
    this.FactoryNetworkBalances = await ethers.getContractFactory("NetworkBalances", this.AccountDeployer)
    this.FactoryNetworkProposal = await ethers.getContractFactory("NetworkProposal", this.AccountDeployer)
    this.FactoryNodeDeposit = await ethers.getContractFactory("NodeDeposit", this.AccountDeployer)
    this.FactoryUserDeposit = await ethers.getContractFactory("UserDeposit", this.AccountDeployer)
    this.FactoryNetworkWithdraw = await ethers.getContractFactory("NetworkWithdraw", this.AccountDeployer)
    this.FactoryERC1967Proxy = await ethers.getContractFactory("ERC1967Proxy", this.AccountDeployer)


    // deploy logic contract
    this.ContractFeePoolLogic = await this.FactoryFeePool.deploy()
    await this.ContractFeePoolLogic.deployed()
    console.log("ContractFeePoolLogic address: ", this.ContractFeePoolLogic.address)


    this.ContractNetworkBalancesLogic = await this.FactoryNetworkBalances.deploy()
    await this.ContractNetworkBalancesLogic.deployed()
    console.log("ContractNetworkBalancesLogic address: ", this.ContractNetworkBalancesLogic.address)

    this.ContractNetworkProposalLogic = await this.FactoryNetworkProposal.deploy()
    await this.ContractNetworkProposalLogic.deployed()
    console.log("ContractNetworkProposalLogic address: ", this.ContractNetworkProposalLogic.address)


    this.ContractNodeDepositLogic = await this.FactoryNodeDeposit.deploy()
    await this.ContractNodeDepositLogic.deployed()
    console.log("ContractNodeDepositLogic address: ", this.ContractNodeDepositLogic.address)

    this.ContractUserDepositLogic = await this.FactoryUserDeposit.deploy()
    await this.ContractUserDepositLogic.deployed()
    console.log("ContractUserDepositLogic address: ", this.ContractUserDepositLogic.address)

    this.ContractNetworkWithdrawLogic = await this.FactoryNetworkWithdraw.deploy()
    await this.ContractNetworkWithdrawLogic.deployed()
    console.log("ContractNetworkWithdrawLogic address: ", this.ContractNetworkWithdrawLogic.address)

    // deploy factory logic contract
    this.ContractLsdNetworkFactoryLogic = await this.FactoryLsdNetworkFactory.deploy()
    await this.ContractLsdNetworkFactoryLogic.deployed()
    console.log("ContractLsdNetworkFactoryLogic address: ", this.ContractLsdNetworkFactoryLogic.address)

    // deploy factory proxy contract
    this.ContractERC1967Proxy = await this.FactoryERC1967Proxy.deploy(this.ContractLsdNetworkFactoryLogic.address, "0x")
    await this.ContractERC1967Proxy.deployed()
    console.log("LsdNetworkFactory address: ", this.ContractERC1967Proxy.address)

    this.ContractLsdNetworkFactory = await ethers.getContractAt("LsdNetworkFactory", this.ContractERC1967Proxy.address, this.AccountDeployer)

    await this.ContractLsdNetworkFactory.init(this.AccountFactoryAdmin.address,
        this.ContractDepositContractAddress, this.ContractFeePoolLogic.address, this.ContractNetworkBalancesLogic.address,
        this.ContractNetworkProposalLogic.address, this.ContractNodeDepositLogic.address,
        this.ContractUserDepositLogic.address, this.ContractNetworkWithdrawLogic.address)

    console.log("ContractLsdNetworkFactory address: ", this.ContractLsdNetworkFactory.address)
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
