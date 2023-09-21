const { ethers, web3 } = require("hardhat")


async function main() {


    this.signers = await ethers.getSigners()

    this.AccountDeployer = this.signers[0]
    this.AccountFactoryAdmin = this.signers[1]
    this.FactoryProxyAdmin = this.signers[2]


    this.FactoryFeePool = await ethers.getContractFactory("FeePool", this.AccountDeployer)
    this.FactoryLsdNetworkFactory = await ethers.getContractFactory("LsdNetworkFactory", this.AccountDeployer)
    this.FactoryLsdToken = await ethers.getContractFactory("LsdToken", this.AccountDeployer)
    this.FactoryNetworkBalances = await ethers.getContractFactory("NetworkBalances", this.AccountDeployer)
    this.FactoryNetworkProposal = await ethers.getContractFactory("NetworkProposal", this.AccountDeployer)
    this.FactoryNodeDeposit = await ethers.getContractFactory("NodeDeposit", this.AccountDeployer)
    this.FactoryUserDeposit = await ethers.getContractFactory("UserDeposit", this.AccountDeployer)
    this.FactoryNetworkWithdraw = await ethers.getContractFactory("NetworkWithdraw", this.AccountDeployer)

    this.FactoryERC1967Proxy = await ethers.getContractFactory("ERC1967Proxy", this.AccountDeployer)



    this.ContractDepositContractAddress = "0xff50ed3d0ec03ac01d4c79aad74928bff48a7b2b"
    console.log("ContractDepositContract address: ", this.ContractDepositContractAddress)

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

    this.ContractLsdNetworkFactory = await ethers.getContractAt("LsdNetworkFactory", this.ContractTransparentUpgradeableProxy.address)

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
