---
eip: <EIP number>
title: Standard for Fractionalizing Non-Fungible Tokens
description: This EIP proposes a standardized interface for fractionalizing Non-Fungible Tokens (NFTs) into fungible ERC-20 tokens, enabling wider accessibility, liquidity, and integration with DeFi platforms.
author: Wejdene Haouari (wejdeneHaouari@yorku.ca/WejdeneHaouari)
discussions-to: <Discussion URL>
status: Draft
type: Standards Track
category: ERC
created: <Creation Date (2024-04-23)>
requires: 20, 721, 1155
---

## Simple Summary

A standard interface for fractionalizing Non-Fungible Tokens (NFTs) into fungible ERC-20 tokens. This enables shared ownership of NFTs, creating liquidity and expanding market accessibility.

## Abstract

This standard outlines a protocol for fractionalizing NFTs (both ERC-721 and ERC-1155) into fungible ERC-20 tokens. It includes a series of smart contracts, each with specific roles and interfaces, to manage the process of fractionalization, governance, fee collection, market integration, and auction mechanisms.

## Motivation

Fractional ownership of NFTs addresses key challenges in the NFT market, such as lack of liquidity and high entry barriers due to the indivisible and often expensive nature of NFTs. This standard aims to increase NFT utility and accessibility, allowing more users to participate in the NFT ecosystem.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.


### 1. NFT Vault Contract (NFTVault.sol)

#### Purpose
Holds NFTs and manages fractional tokens representing ownership in these NFTs.

#### Key Features
- Deposit and withdrawal of NFTs.
- Minting of fractional tokens (fTokens) against NFTs.
- Random and targeted redemption of NFTs using fTokens.

#### Interface

```solidity
/**
 * @title IVault
 * @notice Defines the basic interface for a Vault that holds NFTs and manages fractional ownership.
 */
interface IVault is IERC721Receiver {
    /**
     * @notice Deposits an array of NFTs into the vault.
     * @param tokenIds The array of token IDs to deposit.
     */
    function depositNFTs(uint256[] calldata tokenIds) external;

    /**
     * @notice Withdraws specified NFTs from the vault by burning the corresponding fractional tokens.
     * @param tokenId The ID of the NFT
     */
    function withdrawNFT(uint256 tokenId)  external;

    /**
     * @notice Redeems fractional tokens for a share of the ETH from an NFT's sale.
     * @param tokenId The ID of the NFT whose sale proceeds are being claimed.
     * @param fractionAmount The amount of fractional tokens to redeem.
     */
    function redeemFractionValue(uint256 tokenId, uint256 fractionAmount) external;

    // Event emitted when an NFT is deposited into the vault.
    event NFTDeposited(uint256 indexed tokenId, address indexed from, uint256 fractionalTokensMinted);
    // Event emitted when an NFT is withdrawn from the vault.
    event NFTWithdrawn(uint256 indexed tokenId, address indexed to);
    // Event emitted when fractional token holders redeem their share for ETH.
    event FractionValueRedeemed(address indexed redeemer, uint256 tokenId, uint256 fractionAmount, uint256 redeemableAmount);
    // Event emitted when an auction is canceled.
}

```

### Scenarios and Rules
#### 1. Deposit NFTs (depositNFT):

- The depositNFT function **MUST** accept ERC721 and/or ERC1155 NFTs.
- It **MUST** emit the `NFTDeposited` event upon successful deposit.
- It **MUST** revert if the NFT contract does not support ERC721 or ERC1155 interface.

#### 2. Withdraw NFTs (withdrawNFT):

- The `withdrawNFT` function **MUST** allow NFT withdrawal by the depositor or an authorized user.
- It **MUST** emit the `NFTWithdrawn` event upon successful withdrawal.
- It **MUST** revert if the requested NFT is not available in the vault.


#### 3. Redeem NFTs (redeemNFT, redeemNFTTargeted):

- The `redeemNFT` function **MUST** allow fractional token holders to redeem NFTs from the vault.
- The `redeemNFTTargeted` function **MUST** allow redemption of a specific NFT for fractional tokens.
- Both functions **MUST** burn the fractional tokens used for redemption.
- They **MUST** emit either `NFTRedeemed` or `NFTTargetedRedeemed` event upon successful redemption.
- They **MUST** **revert** if the redemption criteria are not met.


### 2. Fractional Token Contract (FractionalToken.sol)

#### Purpose
Represents fractional ownership in an NFT through fungible tokens.


#### Key Features
- ERC-20 compliant token representing fractional ownership.
- Minting and burning in correspondence with NFT deposits and redemptions.

#### Interface

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IFractionalToken
 * @dev Interface for the Fractional Token contract.
 * This interface manages the ERC20 tokens representing fractional ownership of NFTs.
 */
interface IFractionalToken is IERC20{
    /**
     * @dev Mints fractional tokens to a specified address.
     * @param to The address to mint tokens to.
     * @param amount The amount of fractional tokens to mint.
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Burns fractional tokens from a holder's balance.
     * @param from The address to burn tokens from.
     * @param amount The amount of fractional tokens to burn.
     */
    function burn(address from, uint256 amount) external;

    // ERC20 standard functions
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    // Events
    event FractionalTokensMinted(address indexed to, uint256 amount);
    event FractionalTokensBurned(address indexed from, uint256 amount);
}

```

### Scenarios and Rules
#### 1. Mint Fractional Tokens (mint):

The `mint` function **MUST** create fractional tokens and assign them to the specified address.
It **MUST** emit the `FractionalTokensMinted` event upon successful minting.
It **MUST** revert if the minting exceeds the allowed fractional token supply.

#### 2. Burn Fractional Tokens (burn):

The burn function **MUST** destroy fractional tokens from the specified address's balance.
It MUST emit the FractionalTokensBurned event upon successful burning.
It MUST revert if the specified address does not have enough tokens to burn.

#### 3. ERC20 Standard Functions:

The interface MUST implement standard ERC20 functions such as transfer, approve, transferFrom, balanceOf, and allowance.
Each function MUST adhere to the standard ERC20 specifications and behavior.


### 3. Auction Contract (NFTAuction.sol)

#### Purpose
Enables auctioning of NFTs from the vault.


#### Key Features
- Initiating auctions for NFTs.
- Bidding in auctions using fractional tokens.
- Transferring NFT ownership post-auction.

#### Interface

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title INFTAuction
 * @dev Interface for the Auction Contract.
 * Manages the auction process for fractional tokens and NFT buyout attempts.
 */
interface INFTAuction {
    /**
     * @dev  Initiates a buyout attempt for an NFT.
     * @param tokenId The ID of the NFT for which the auction is being started.
     * @param reservePrice The minimum price for the auction.
     */
    function startAuction(uint256 tokenId, uint256 reservePrice) external;

    /**
     * @dev Places a bid in an ongoing auction.
     * @param tokenId The ID of the NFT being auctioned.
     * @param amount The bid amount.
     */
    function placeBid(uint256 tokenId, uint256 amount) external;

    /**
     * @dev Concludes the auction, transferring the NFT to the highest bidder.
     * @param tokenId The ID of the NFT being auctioned.
     */
    function endAuction(uint256 tokenId) external;

  
    // Events
    event AuctionStarted(uint256 indexed tokenId, uint256 reservePrice);
    event BidPlaced(uint256 indexed tokenId, address indexed bidder, uint256 amount);
    event AuctionEnded(uint256 indexed tokenId, address winner, uint256 winningBid);
}

```

### Scenarios and Rules


#### 1. Starting an Auction:

- A user **MAY** start an auction by calling `startAuction`.
- The auction **MUST NOT** start if the reservePrice is not met.

#### 2. Placing a Bid:

- Users **MAY** place bids by calling `placeBid`.
- A bid **MUST** be higher than the previous highest bid.
- The contract **SHOULD** handle bid refunds if outbid.

#### 3.Ending an Auction:

- The auction **MUST** end after a predefined duration or condition.
- The NFT **MUST** be transferred to the highest bidder.

### 4. Governance Contract (NFTGovernance.sol)

#### Purpose
Enables fractional token holders to vote on key decisions.



#### Key Features
- Proposal creation by token holders.
- Voting mechanism based on token holdings.

#### Interface

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title INFTGovernance
 * @dev Interface for the Governance Contract.
 * Enables fractional token holders to participate in governance decisions.
 */
interface INFTGovernance {
    /**
     * @dev Initiates a new governance proposal.
     * @param description A brief description of the proposal.
     * @param callData The function call to be executed if the proposal passes.
     * @return proposalId The ID of the created proposal.
     */
    function createProposal(string calldata description, bytes calldata callData) external returns (uint256 proposalId);

    /**
     * @dev Allows a token holder to cast a vote on an active proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support A boolean indicating whether the vote is in support of the proposal.
     */
    function voteOnProposal(uint256 proposalId, bool support) external;

    /**
     * @dev Executes a proposal after it has passed.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external;

    /**
     * @dev Retrieves the details of a specific proposal.
     * @param proposalId The ID of the proposal.
     * @return description The description of the proposal.
     * @return executed A boolean indicating whether the proposal has been executed.
     * @return voteCount The total number of votes cast for the proposal.
     */
    function getProposalDetails(uint256 proposalId) external view returns (string memory description, bool executed, uint256 voteCount);

    // Events
    event ProposalCreated(uint256 indexed proposalId, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
}

```
### Scenarios and Rules
#### 1. Proposal Creation:

- A user **MAY** create a proposal by calling `createProposal`.
- The proposal **MUST** include a description and call data.

#### 2. Voting on a Proposal:

- Token holders **MAY** vote on proposals by calling `voteOnProposal`.
- Each token holder's vote **MUST** be weighted according to their token holdings.

#### 3. Executing a Proposal:

- A proposal **MAY** be executed after it meets defined criteria (e.g., quorum, majority).
- Proposals **SHOULD NOT** be executed if they do not meet these criteria.

#### 4. Retrieving Proposal Details:

- Users **MAY** retrieve details of a proposal using `getProposalDetails`.
- Details **MUST** include the proposal's status and vote count.

### 5. Fee Management Contract (FeeManager.sol)

#### Purpose
Handles fee collection and distribution for various operations within the ecosystem.




#### Key Features
- Fee collection for actions like minting, redeeming, and auction participation.
- Fee distribution to stakeholders such as liquidity providers, developers, or a treasury.

#### Interface

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IFeeManager
 * @dev Interface for the Fee Management Contract.
 * Manages the collection and distribution of fees in the NFT fractionalization ecosystem.
 */
interface IFeeManager {
    /**
     * @dev Collects fees from specified operations.
     * @param from The address from which the fee is collected.
     * @param amount The amount of fee to collect.
     */
    function collectFee(address from, uint256 amount) external;

    /**
     * @dev Distributes collected fees to various stakeholders.
     * Typically called after a certain threshold of fees is collected or at regular intervals.
     */
    function distributeFees() external;

    /**
     * @dev Sets the distribution percentages for collected fees.
     * @param liquidityProviders Percentage of fees going to liquidity providers.
     * @param developers Percentage of fees going to developers.
     * @param treasury Percentage of fees going to the treasury.
     */
    function setFeeDistribution(uint256 liquidityProviders, uint256 developers, uint256 treasury) external;

    /**
     * @dev Allows stakeholders to withdraw their allocated fees.
     * @param stakeholder The address of the stakeholder withdrawing the fees.
     */
    function withdrawFees(address stakeholder) external;

    // Events
    event FeeCollected(address indexed from, uint256 amount);
    event FeesDistributed(uint256 liquidityProvidersAmount, uint256 developersAmount, uint256 treasuryAmount);
    event FeeWithdrawn(address indexed stakeholder, uint256 amount);
}


```

### Scenarios and Rules
#### 1. Fee Collection 

- The contract **MUST** allow for the collection of fees via the `collectFee` function.
- `collectFee` function `SHOULD` only be callable by authorized entities to ensure proper fee management.
#### 2. Fee Distribution:
- The `distributeFees` function **MUST** enable the distribution of collected fees to various stakeholders.
- `distributeFees` function **SHOULD** typically be invoked after a certain threshold of fees is collected or at regular intervals.
#### 3. Setting Fee Distribution Percentages:
- The `setFeeDistribution` function **MUST** allow the contract owner or authorized entity to set the distribution percentages for collected fees.
- `setFeeDistribution` function **MUST** accept percentages for liquidity providers, developers, and the treasury.
- Changes in distribution percentages **SHOULD** be governed by a predefined governance process or administrative control to maintain fairness and transparency.
#### 4. Withdrawal of Fees:
- Stakeholders **SHOULD** be able to withdraw their allocated fees using the `withdrawFees` function.
- `withdrawFees`  function **MUST** include security checks to ensure only rightful stakeholders can withdraw their allocated fees.

### 6. Market Integration Contract (MarketIntegrator.sol)

#### Purpose
Facilitates the trading of fractional tokens on secondary markets and integrates with DeFi protocols.



#### Key Features
- Integration with Automated Market Makers (AMMs) like Uniswap or Sushiswap.
- Management of incentives for liquidity providers.

#### Interface

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IMarketIntegrator
 * @dev Interface for the Market Integration Contract.
 * Facilitates the integration of fractional tokens with DeFi protocols and manages liquidity provision incentives.
 */
interface IMarketIntegrator {
    /**
     * @dev Registers a liquidity pool for fractional tokens on a specific AMM.
     * @param fractionalToken Address of the fractional token.
     * @param liquidityPool Address of the liquidity pool on the AMM.
     */
    function addLiquidityPool(address fractionalToken, address liquidityPool) external;

    /**
     * @dev Removes a registered liquidity pool.
     * @param fractionalToken Address of the fractional token.
     */
    function removeLiquidityPool(address fractionalToken) external;

    /**
     * @dev Provides liquidity to a registered pool and mints LP tokens.
     * @param fractionalToken Address of the fractional token.
     * @param amount Amount of fractional tokens to provide as liquidity.
     */
    function provideLiquidity(address fractionalToken, uint256 amount) external;

    /**
     * @dev Withdraws liquidity from a pool and burns the LP tokens.
     * @param fractionalToken Address of the fractional token.
     * @param amount Amount of LP tokens to burn in exchange for fractional tokens.
     */
    function withdrawLiquidity(address fractionalToken, uint256 amount) external;

    /**
     * @dev Claims rewards for providing liquidity.
     * @param fractionalToken Address of the fractional token.
     */
    function claimRewards(address fractionalToken) external;

    /**
     * @dev Sets the incentive scheme for liquidity providers.
     * @param fractionalToken Address of the fractional token.
     * @param rewardRate The rate of rewards distribution.
     * @param duration The duration for which the rewards are distributed.
     */
    function setIncentiveScheme(address fractionalToken, uint256 rewardRate, uint256 duration) external;

    // Events
    event LiquidityPoolAdded(address indexed fractionalToken, address indexed liquidityPool);
    event LiquidityPoolRemoved(address indexed fractionalToken);
    event LiquidityProvided(address indexed fractionalToken, uint256 amount);
    event LiquidityWithdrawn(address indexed fractionalToken, uint256 amount);
    event RewardsClaimed(address indexed fractionalToken, uint256 amount);
    event IncentiveSchemeSet(address indexed fractionalToken, uint256 rewardRate, uint256 duration);
}


```
### Scenarios and Rules
#### 1. Liquidity Pool Management:
- The contract **MUST** allow for the registration of liquidity pools for fractional tokens using the `addLiquidityPool` function.
- The contract **MUST** also allow for the removal of liquidity pools via the `removeLiquidityPool` function.
#### 2. Liquidity Provision:
- Users **MAY** provide liquidity to registered pools using the `provideLiquidity` function.
- Users **MAY** withdraw their liquidity using the `withdrawLiquidity` function.
#### 3. Rewards Management:
- The contract **MUST** enable liquidity providers to claim their rewards through the claimRewards function.
#### 4. Setting Incentive Schemes:
- The `setIncentiveScheme` function **MUST** allow the configuration of incentive schemes for liquidity providers.
- `setIncentiveScheme`  function **MUST** accept parameters for the fractional token, reward rate, and duration of the incentive scheme.

# Fractionalization Standard: Safe Transfer and Interaction Rules

The proposed Fractionalization Standard outlines the rules and scenarios for safely transferring fractional tokens and interacting with various contracts in the ecosystem. These rules are essential to ensure standard-compliant behavior and interoperability between contracts.

## Scenarios and Rules

### Fractional Token Transfers

#### Scenario #1: Transferring to EOA (Externally Owned Account)

- Fractional tokens **MUST** be transferable to EOAs.
- The transfer **MUST NOT** call any contract functions on the recipient EOA.

#### Scenario #2: Transferring to a Contract

- If the recipient is a contract, the transfer **MUST** check if the contract implements the `IFractionalTokenReceiver` interface.
- If the interface is implemented, the `onFractionalTokenReceived` function **MUST** be called.
- If the function call returns a value other than the expected magic value, or the contract does not implement the interface, the transfer **MUST** be reverted.

### NFT Deposits and Withdrawals

#### Scenario #3: Depositing an NFT into the Vault

- The NFT **MUST** be transferred to the vault contract.
- The vault **MUST** verify the ownership and call `mintFractionalTokens` to mint fractional tokens.

#### Scenario #4: Withdrawing an NFT from the Vault

- Fractional tokens **MUST** be burned or exchanged for the NFT withdrawal.
- The vault **MUST** transfer the NFT back to the original owner or designated recipient.

### Auction and Buyout Processes

#### Scenario #5: Initiating and Participating in Auctions

- Users **MUST** be able to start and bid in auctions for NFTs or fractional tokens.
- The auction contract **MUST** handle bids, track the highest bidder, and transfer ownership upon auction conclusion.

#### Scenario #6: Initiating and Finalizing Buyouts

- Users **MUST** be able to propose buyouts for NFTs.
- If a buyout is accepted, the contract **MUST** handle the transfer of ownership and payment.

### Governance and Fee Management

#### Scenario #7: Governance Proposals and Voting

- Token holders **MUST** be able to create and vote on governance proposals.
- The governance contract **MUST** validate and execute proposals based on voting outcomes.

#### Scenario #8: Fee Collection and Distribution

- The fee management contract **MUST** collect and distribute fees according to predefined rules.
- Stakeholders **SHOULD** be able to withdraw their allocated fees.

### Market Integration and Liquidity Provision

#### Scenario #9: Providing Liquidity and Claiming Rewards

- Users **MUST** be able to add or remove liquidity for fractional tokens in DeFi protocols.
- Rewards for liquidity provision **MUST** be claimable according to the incentive scheme.


### Implementation-Specific API Rules

- Contracts **MAY** have implementation-specific APIs for advanced features.
- Such APIs **MUST** adhere to the core principles of the standard, ensuring safe transfer and interaction rules are maintained.

By following these scenarios and rules, the Fractionalization Standard ensures a consistent, safe, and interoperable framework for managing fractional ownership of NFTs and integrating with the broader Ethereum ecosystem.



## Rationale
The standard's design considers the complexities of NFT ownership and the need for a flexible yet secure system for fractionalization. Each contract in the standard plays a specific role, ensuring clarity and efficiency in the fractionalization process.

## Backwards Compatibility
This standard builds upon existing ERC-20, ERC-721, and ERC-1155 standards. It does not modify these standards but extends their functionality to enable fractional ownership of NFTs.

## Reference Implementation
A reference Implementation can be found in the contracts' directory.
## Security Considerations
Implementations of this standard should consider the following:

Reentrancy attacks, particularly in functions that involve token transfers.

Proper access control in minting and burning of fractional tokens.

Validation of NFT ownership and authenticity.
## Conclusion
This EIP aims to foster innovation and growth in the NFT space by introducing a standardized approach to fractionalizing NFTs, thereby enhancing liquidity and market participation.