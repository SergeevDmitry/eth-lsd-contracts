
const { ethers, web3 } = require("hardhat")
const { expect } = require("chai")

describe("LsdNetwok test", function () {
    before(async function () {
        this.signers = await ethers.getSigners()

        this.AccountDeployer = this.signers[0]
        this.AccountFactoryAdmin = this.signers[1]

        this.AccountUser1 = this.signers[2]
        this.AccountLightNode1 = this.signers[3]
        this.AccountTrustNode1 = this.signers[4]

        this.AccountProxyAdmin1 = this.signers[5]
        this.AccountNetworkAdmin1 = this.signers[6]
        this.AccountVoters1 = this.signers[7]
        this.AccountVoters2 = this.signers[8]



        this.FactoryFeePool = await ethers.getContractFactory("FeePool", this.AccountDeployer)
        this.FactoryLsdNetworkFactory = await ethers.getContractFactory("LsdNetworkFactory", this.AccountDeployer)
        this.FactoryLsdToken = await ethers.getContractFactory("LsdToken", this.AccountDeployer)
        this.FactoryNetworkBalances = await ethers.getContractFactory("NetworkBalances", this.AccountDeployer)
        this.FactoryNetworkProposal = await ethers.getContractFactory("NetworkProposal", this.AccountDeployer)
        this.FactoryNodeDeposit = await ethers.getContractFactory("NodeDeposit", this.AccountDeployer)
        this.FactoryUserDeposit = await ethers.getContractFactory("UserDeposit", this.AccountDeployer)
        this.FactoryNetworkWithdraw = await ethers.getContractFactory("NetworkWithdraw", this.AccountDeployer)

        this.FactoryDepositContract = await ethers.getContractFactory("DepositContract", this.AccountDeployer)
    })

    beforeEach(async function () {

        // deploy mock contract
        this.ContractDepositContract = await this.FactoryDepositContract.deploy()
        await this.ContractDepositContract.deployed()
        console.log("ContractDepositContract address: ", this.ContractDepositContract.address)

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


        // deploy factory

        this.ContractLsdNetworkFactory = await this.FactoryLsdNetworkFactory.deploy(this.AccountFactoryAdmin.address,
            this.ContractDepositContract.address, this.ContractFeePoolLogic.address, this.ContractNetworkBalancesLogic.address,
            this.ContractNetworkProposalLogic.address, this.ContractNodeDepositLogic.address,
            this.ContractUserDepositLogic.address, this.ContractNetworkWithdrawLogic.address)

        await this.ContractLsdNetworkFactory.deployed()
        console.log("ContractLsdNetworkFactory address: ", this.ContractLsdNetworkFactory.address)

    })

    it("should createLsdNetwork success", async function () {

        let createLsdNetworkTx = await this.ContractLsdNetworkFactory.connect(this.AccountUser1).createLsdNetwork(
            "test lsdEth", "lsdEth", this.AccountProxyAdmin1.address, this.AccountNetworkAdmin1.address,
            [this.AccountVoters1.address, this.AccountVoters2.address], 2)

        let createLsdNetworkTxRecipient = await createLsdNetworkTx.wait()
        console.log("createLsdNetworkTx gas: ", createLsdNetworkTxRecipient.gasUsed.toString())
    })

})