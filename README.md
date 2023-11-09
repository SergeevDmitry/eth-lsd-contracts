# eth-lsd-contracts

Contracts is the foundation of ETH LSD stack. It consists of LsdToken, UserDeposit, NodeDeposit and NetworkWithdraw and other contracts, which enables users to stake, unstake and withdraw, validators to run node with minimum amount of ETH and platform to manage solo and trust nodes. 

To learn more about ETH LSD stack, see [**ETH LSD Stack Documentation and Guide**](https://github.com/stafiprotocol/stack-docs/blob/main/README.md#eth-lsd-stack)

a very brief diagrams of the workflow:

```mermaid
sequenceDiagram
actor User

User->>UserPool.sol: stake ETH
UserPool.sol->>User: mint rToken
User->>UserPool.sol: unstake rToken 
UserPool.sol->>User: transfer ETH
```

```mermaid
sequenceDiagram
actor Admin
actor Node
participant NodeDeposit.sol

Admin->>NodeDeposit.sol: manage trust node
Node->>NodeDeposit.sol: create new validator
```

```mermaid
sequenceDiagram
Ethereum->>FeePool.sol: distribute priority fee
Ethereum->>NetworkWithdraw.sol: distribute validator rewards
```


```mermaid
sequenceDiagram
Voter->>NetworkBalances.sol: vote for user balances <br>and other proposals for the network
```
