// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title IAuction
 * @notice Interface for the auction functionality of NFTs within a Vault.
 */
interface IAuction {
    /**
     * @notice Starts an auction for a specific NFT with a starting price.
     * @param assetAddress The address of te NFT.
     * @param tokenId The ID of the NFT to auction.
     * @param startingPrice The starting price of the auction in Wei.
     */
    function startAuction(address assetAddress, uint256 tokenId, uint256 startingPrice, uint256 duration) external;

    /**
     * @notice Allows users to place bids on an active auction of an NFT.
     * @param tokenId The ID of the NFT being auctioned.
     */
    function placeBid(uint256 tokenId) external payable;

    /**
     * @notice Ends an auction, transferring the NFT to the highest bidder and distributing the sale proceeds.
     * @param tokenId The ID of the NFT being auctioned.
     */
    function endAuction(uint256 tokenId) external;


    event AuctionStarted(uint256 indexed tokenId, uint256 endTime, uint256 price);
    event BidPlaced(uint256 indexed tokenId, address bidder, uint256 amount);
    event AuctionEnded(uint256 indexed tokenId, address winner, uint256 amount);

}
