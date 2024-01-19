const { ethers, web3 } = require('hardhat')
const { expect } = require('chai')

describe('LsdNetwok test', function () {
  before(async function () {
    signers = await ethers.getSigners()

    AccountDeployer = signers[0]
    AccountFactoryAdmin = signers[1]

    AccountUser1 = signers[2]
    AccountSoloNode1 = signers[3]
    AccountTrustNode1 = signers[4]

    AccountProxyAdmin1 = signers[5]
    AccountNetworkAdmin1 = signers[6]
    AccountVoters1 = signers[7]
    AccountVoters2 = signers[8]
    FactoryProxyAdmin = signers[9]

    // Library deployment
    const lib = await ethers.getContractFactory("NewContractLib", AccountDeployer)
    const libInstance = await lib.deploy()
    await libInstance.waitForDeployment()
    console.log("NewContractLib Address: " + await libInstance.getAddress())
    const libAddr = await libInstance.getAddress()

    const FactoryFeePool = await ethers.getContractFactory('FeePool', AccountDeployer)
    const FactoryFeePoolV2Example = await ethers.getContractFactory('FeePoolV2Example', AccountDeployer)
    const FactoryFeePoolV3Example = await ethers.getContractFactory('FeePoolV3Example', AccountDeployer)
    const FactoryLsdNetworkFactory = await ethers.getContractFactory('LsdNetworkFactory', {
        signer: AccountDeployer, 
        libraries: { "contracts/libraries/NewContractLib.sol:NewContractLib": libAddr }
    })
    FactoryLsdToken = await ethers.getContractFactory('LsdToken', AccountDeployer)
    const FactoryNetworkBalances = await ethers.getContractFactory('NetworkBalances', AccountDeployer)
    FactoryNetworkProposal = await ethers.getContractFactory('NetworkProposal', AccountDeployer)
    const FactoryNodeDeposit = await ethers.getContractFactory('NodeDeposit', AccountDeployer)
    const FactoryUserDeposit = await ethers.getContractFactory('UserDeposit', AccountDeployer)
    const FactoryNetworkWithdraw = await ethers.getContractFactory('NetworkWithdraw', AccountDeployer)

    const FactoryDepositContract = await ethers.getContractFactory('DepositContract', AccountDeployer)

    FactoryERC1967Proxy = await ethers.getContractFactory(
      'ERC1967Proxy',
      FactoryProxyAdmin,
    )


    // deploy mock contracts
    ContractDepositContract = await FactoryDepositContract.deploy()
    await ContractDepositContract.waitForDeployment()
    console.log('ContractDepositContract address:', await ContractDepositContract.getAddress())

    // deploy logic contracts
    ContractFeePoolLogic = await FactoryFeePool.deploy()
    await ContractFeePoolLogic.waitForDeployment()
    console.log('ContractFeePoolLogic address: ', await ContractFeePoolLogic.getAddress())

    ContractFeePoolV2ExampleLogic = await FactoryFeePoolV2Example.deploy()
    await ContractFeePoolV2ExampleLogic.waitForDeployment()
    console.log('ContractFeePoolV2ExampleLogic address: ', await ContractFeePoolV2ExampleLogic.getAddress())

    ContractFeePoolV3ExampleLogic = await FactoryFeePoolV3Example.deploy()
    await ContractFeePoolV3ExampleLogic.waitForDeployment()
    console.log('ContractFeePoolV3ExampleLogic address: ', await ContractFeePoolV3ExampleLogic.getAddress())

    ContractNetworkBalancesLogic = await FactoryNetworkBalances.deploy()
    await ContractNetworkBalancesLogic.waitForDeployment()
    console.log('ContractNetworkBalancesLogic address: ', await ContractNetworkBalancesLogic.getAddress())

    ContractNetworkProposalLogic = await FactoryNetworkProposal.deploy()
    await ContractNetworkProposalLogic.waitForDeployment()
    console.log('ContractNetworkProposalLogic address: ', await ContractNetworkProposalLogic.getAddress())

    ContractNodeDepositLogic = await FactoryNodeDeposit.deploy()
    await ContractNodeDepositLogic.waitForDeployment()
    console.log('ContractNodeDepositLogic address: ', await ContractNodeDepositLogic.getAddress())

    ContractUserDepositLogic = await FactoryUserDeposit.deploy()
    await ContractUserDepositLogic.waitForDeployment()
    console.log('ContractUserDepositLogic address: ', await ContractUserDepositLogic.getAddress())

    ContractNetworkWithdrawLogic = await FactoryNetworkWithdraw.deploy()
    await ContractNetworkWithdrawLogic.waitForDeployment()
    console.log('ContractNetworkWithdrawLogic address: ', await ContractNetworkWithdrawLogic.getAddress())

    // deploy factory logic contract
    ContractLsdNetworkFactoryLogic = await FactoryLsdNetworkFactory.deploy()
    await ContractLsdNetworkFactoryLogic.waitForDeployment()
    console.log('ContractLsdNetworkFactoryLogic address: ', await ContractLsdNetworkFactoryLogic.getAddress())
  })

  beforeEach(async function () {
    // deploy factory proxy contract
    ERC1967Proxy = await FactoryERC1967Proxy.deploy(
      await ContractLsdNetworkFactoryLogic.getAddress(),
      '0x',
    )
    await ERC1967Proxy.waitForDeployment()

    ContractLsdNetworkFactory = await ethers.getContractAt(
      'LsdNetworkFactory',
      await ERC1967Proxy.getAddress(),
    )
  })

  async function initFactory() {
    // init factory
    await ContractLsdNetworkFactory.init(
      AccountFactoryAdmin,
      await ContractDepositContract.getAddress(),
      await ContractFeePoolLogic.getAddress(),
      await ContractNetworkBalancesLogic.getAddress(),
      await ContractNetworkProposalLogic.getAddress(),
      await ContractNodeDepositLogic.getAddress(),
      await ContractUserDepositLogic.getAddress(),
      await ContractNetworkWithdrawLogic.getAddress(),
    )
  }

  it('should createLsdNetwork success', async function () {
    await initFactory()

    console.log('ContractLsdNetworkFactory address: ', await ContractLsdNetworkFactory.getAddress())

    let createLsdNetworkTx = await ContractLsdNetworkFactory.connect(AccountUser1).createLsdNetwork(
      'test lsdEth',
      'lsdEth',
      AccountNetworkAdmin1,
      [AccountVoters1, AccountVoters2],
      2,
    )

    let createLsdNetworkTxRecipient = await createLsdNetworkTx.wait()
    console.log('createLsdNetworkTx gas: ', createLsdNetworkTxRecipient.gasUsed.toString())

    let createLsdNetworkTx2 = await ContractLsdNetworkFactory.connect(AccountUser1).createLsdNetwork(
      'test lsdEth',
      'lsdEth',
      AccountNetworkAdmin1,
      [AccountVoters1, AccountVoters2],
      2,
    )

    let createLsdNetworkTxRecipient2 = await createLsdNetworkTx2.wait()
    console.log('createLsdNetworkTx2 gas: ', createLsdNetworkTxRecipient2.gasUsed.toString())

    let createLsdNetworkWithTimelockTx = await ContractLsdNetworkFactory.connect(
      AccountUser1,
    ).createLsdNetworkWithTimelock(
      'test lsdEth',
      'lsdEth',
      [AccountVoters1, AccountVoters2],
      2,
      1000,
      [AccountVoters1, AccountVoters2],
    )

    let createLsdNetworkWithTimelockTxRecipient = await createLsdNetworkWithTimelockTx.wait()
    console.log('createLsdNetworkWithTimelockTx gas: ', createLsdNetworkWithTimelockTxRecipient.gasUsed.toString())
  })

  it('should createLsdNetwork with feePoolV2Example success', async function () {
    await initFactory();
    console.log('ContractLsdNetworkFactory address: ', await ContractLsdNetworkFactory.getAddress())

    let createLsdNetworkTx = await ContractLsdNetworkFactory.connect(AccountUser1).createLsdNetwork(
      'test lsdEth',
      'lsdEth',
      AccountNetworkAdmin1,
      [AccountVoters1, AccountVoters2],
      2,
    )

    let createLsdNetworkTxRecipient = await createLsdNetworkTx.wait()
    console.log('createLsdNetworkTx gas: ', createLsdNetworkTxRecipient.gasUsed.toString())

    let createLsdNetworkTx2 = await ContractLsdNetworkFactory.connect(AccountUser1).createLsdNetwork(
      'test lsdEth',
      'lsdEth',
      AccountNetworkAdmin1,
      [AccountVoters1, AccountVoters2],
      2,
    )

    let createLsdNetworkTxRecipient2 = await createLsdNetworkTx2.wait()
    console.log('createLsdNetworkTx2 gas: ', createLsdNetworkTxRecipient2.gasUsed.toString())

    let createLsdNetworkWithTimelockTx = await ContractLsdNetworkFactory.connect(
      AccountUser1,
    ).createLsdNetworkWithTimelock(
      'test lsdEth',
      'lsdEth',
      [AccountVoters1, AccountVoters2],
      2,
      1000,
      [AccountVoters1, AccountVoters2],
    )

    let createLsdNetworkWithTimelockTxRecipient = await createLsdNetworkWithTimelockTx.wait()
    console.log('createLsdNetworkWithTimelockTx gas: ', createLsdNetworkWithTimelockTxRecipient.gasUsed.toString())
  })

  it('should createLsdNetwork with feePoolV3Example success', async function () {
    await initFactory()
    console.log('ContractLsdNetworkFactory address: ', await ContractLsdNetworkFactory.getAddress())

    let createLsdNetworkTx = await ContractLsdNetworkFactory.connect(AccountUser1).createLsdNetwork(
      'test lsdEth',
      'lsdEth',
      AccountNetworkAdmin1,
      [AccountVoters1, AccountVoters2],
      2,
    )

    let createLsdNetworkTxRecipient = await createLsdNetworkTx.wait()
    console.log('createLsdNetworkTx gas: ', createLsdNetworkTxRecipient.gasUsed.toString())

    let createLsdNetworkTx2 = await ContractLsdNetworkFactory.connect(AccountUser1).createLsdNetwork(
      'test lsdEth',
      'lsdEth',
      AccountNetworkAdmin1,
      [AccountVoters1, AccountVoters2],
      2,
    )

    let createLsdNetworkTxRecipient2 = await createLsdNetworkTx2.wait()
    console.log('createLsdNetworkTx2 gas: ', createLsdNetworkTxRecipient2.gasUsed.toString())

    let createLsdNetworkWithTimelockTx = await ContractLsdNetworkFactory.connect(
      AccountUser1,
    ).createLsdNetworkWithTimelock(
      'test lsdEth',
      'lsdEth',
      [AccountVoters1, AccountVoters2],
      2,
      1000,
      [AccountVoters1, AccountVoters2],
    )

    let createLsdNetworkWithTimelockTxRecipient = await createLsdNetworkWithTimelockTx.wait()
    console.log('createLsdNetworkWithTimelockTx gas: ', createLsdNetworkWithTimelockTxRecipient.gasUsed.toString())
  })

  it('should fail to create lsd network with empty entrusted voters', async function () {
    await initFactory();
    await expect(ContractLsdNetworkFactory.connect(AccountUser1).createLsdNetworkWithEntrustedVoters(
      'test lsdEth',
      'lsdEth',
      AccountNetworkAdmin1,
    )).to.be.revertedWithCustomError(ContractLsdNetworkFactory, "EmptyEntrustedVoters")
  })

  it('should create lsd network with entrusted voters', async function () {
    await initFactory();

    await ContractLsdNetworkFactory.connect(AccountFactoryAdmin).setEntrustWithVoters([AccountVoters1], 1)
    const createTx = await ContractLsdNetworkFactory.connect(AccountUser1).createLsdNetworkWithEntrustedVoters(
      'test lsdEth',
      'lsdEth',
      AccountUser1,
    )
    const receipt = await createTx.wait()
    console.log('createLsdNetworkWithEntrustedVoters gas: ', receipt.gasUsed.toString())
    const lsdTokens = await ContractLsdNetworkFactory.connect(AccountUser1).lsdTokensOfCreater(AccountUser1)
    const [_feePool, _networkBalances, _networkProposal, _nodeDeposit, _userDeposit, _networkWithdraw, _block]
      = await ContractLsdNetworkFactory.connect(AccountUser1).networkContractsOfLsdToken(lsdTokens[0])
    const networkProposal = FactoryNetworkProposal.attach( _networkProposal);
    // confirm the voters of the network are whom we set in factory
    expect(await networkProposal.getVoters()).to.be.eql([AccountVoters1.address])
    expect(await networkProposal.threshold()).to.be.eq(1)
  })

  it('should fail to create lsd network when lsd token has been used', async function () {
    await initFactory();
    const lsdToken = await FactoryLsdToken.deploy('test lsdEth', 'lsdEth')
    await lsdToken.waitForDeployment()
    console.log('lsdToken address:', await lsdToken.getAddress())

    await ContractLsdNetworkFactory.connect(AccountFactoryAdmin).addAuthorizedLsdToken(lsdToken)
    await ContractLsdNetworkFactory.connect(AccountUser1).createLsdNetworkWithLsdToken(
      lsdToken,
      AccountNetworkAdmin1,
      [AccountVoters1],
      1,
    )

    await expect(ContractLsdNetworkFactory.connect(AccountUser1).createLsdNetworkWithLsdToken(
      lsdToken,
      AccountNetworkAdmin1,
      [AccountVoters1, AccountVoters2],
      2,
    )).to.be.revertedWithCustomError(ContractLsdNetworkFactory, "LsdTokenCanOnlyUseOnce")
  })
})
