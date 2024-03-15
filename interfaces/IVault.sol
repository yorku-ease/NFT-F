// IVault.sol

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

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
