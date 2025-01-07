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
    const NewContractLib = await ethers.getContractFactory("NewContractLib", this.AccountDeployer);
    const newContractLib = await NewContractLib.deploy();
    await newContractLib.deploymentTransaction()?.wait()
    const newContractLibAddr = await newContractLib.getAddress()
    // const newContractLibAddr = "0xF41cFAF21e5f55CBFb3712C9F11B8CC0E78e64C8"
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
    await this.ContractFeePoolLogic.deploymentTransaction()?.wait()
    const feePoolLogicAddress = await this.ContractFeePoolLogic.getAddress()
    console.log("ContractFeePoolLogic address: ", feePoolLogicAddress)


    this.ContractNetworkBalancesLogic = await this.FactoryNetworkBalances.deploy()
    await this.ContractNetworkBalancesLogic.deploymentTransaction()?.wait()
    const networkBalancesLogicAddress = await this.ContractNetworkBalancesLogic.getAddress()
    console.log("ContractNetworkBalancesLogic address: ", networkBalancesLogicAddress)

    this.ContractNetworkProposalLogic = await this.FactoryNetworkProposal.deploy()
    await this.ContractNetworkProposalLogic.deploymentTransaction()?.wait()
    const networkProposalLogicAddress = await this.ContractNetworkProposalLogic.getAddress()
    console.log("ContractNetworkProposalLogic address: ", networkProposalLogicAddress)


    this.ContractNodeDepositLogic = await this.FactoryNodeDeposit.deploy()
    await this.ContractNodeDepositLogic.deploymentTransaction()?.wait()
    const nodeDepositLogicAddress = await this.ContractNodeDepositLogic.getAddress()
    console.log("ContractNodeDepositLogic address: ", nodeDepositLogicAddress)

    this.ContractUserDepositLogic = await this.FactoryUserDeposit.deploy()
    await this.ContractUserDepositLogic.deploymentTransaction()?.wait()
    const userDepositLogicAddress = await this.ContractUserDepositLogic.getAddress()
    console.log("ContractUserDepositLogic address: ", userDepositLogicAddress)

    this.ContractNetworkWithdrawLogic = await this.FactoryNetworkWithdraw.deploy()
    await this.ContractNetworkWithdrawLogic.deploymentTransaction()?.wait()
    const networkWithdrawLogicAddress = await this.ContractNetworkWithdrawLogic.getAddress()
    console.log("ContractNetworkWithdrawLogic address: ", networkWithdrawLogicAddress)

    // deploy factory logic contract
    this.ContractLsdNetworkFactoryLogic = await this.FactoryLsdNetworkFactory.deploy()
    await this.ContractLsdNetworkFactoryLogic.deploymentTransaction()?.wait()
    const lsdNetworkFactoryLogicAddress = await this.ContractLsdNetworkFactoryLogic.getAddress()
    console.log("ContractLsdNetworkFactoryLogic address: ", lsdNetworkFactoryLogicAddress)

    // deploy factory proxy contract
    this.ContractERC1967Proxy = await this.FactoryERC1967Proxy.deploy(lsdNetworkFactoryLogicAddress, "0x")
    await this.ContractERC1967Proxy.deploymentTransaction()?.wait()
    const ERC1967ProxyAddress = await this.ContractERC1967Proxy.getAddress()
    console.log("LsdNetworkFactory address: ", ERC1967ProxyAddress)

    this.ContractLsdNetworkFactory = await ethers.getContractAt("LsdNetworkFactory", ERC1967ProxyAddress, this.AccountDeployer)

    await this.ContractLsdNetworkFactory.init(
      this.AccountFactoryAdmin.address,
      this.ContractDepositContractAddress,
      feePoolLogicAddress,
      networkBalancesLogicAddress,
      networkProposalLogicAddress,
      nodeDepositLogicAddress,
      userDepositLogicAddress,
      networkWithdrawLogicAddress,
    )
    const lsdNetworkFactoryAddress = await this.ContractLsdNetworkFactory.getAddress()

    console.log("ContractLsdNetworkFactory address: ", lsdNetworkFactoryAddress)
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
