// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IGovernanceControlled.sol";
import "../interfaces/IAuction.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IFractionalToken.sol";

/**
 * @title Vault
 * @dev This contract manages the depositing, fractionalizing, and auctioning of NFTs.
 *      It integrates governance mechanisms allowing for updates to auction duration,
 *      royalty percentages, and the ability to cancel auctions based on governance decisions.
 */
contract Vault is ERC721Holder, IVault, IAuction, IGovernanceControlled, Ownable, ReentrancyGuard {

    // The NFT collection this vault will accept.
    IERC721 public nft;
    // Address of the governance contract
    address public governanceContract;
    // The token to be used as fractional shares of the deposited NFTs.
    IFractionalToken public fractionalToken;


    // Auction structure for managing NFT sales.
    struct Auction {
        bool isActive; // Whether the auction is active.
        uint256 endTime; // When the auction ends (timestamp).
        uint256 highestBid; // The highest bid amount in Wei.
        address highestBidder; // The address of the highest bidder.
        uint256 totalBids; // Total number of bids placed in this auction.
    }

    // Royalty details, set upon deployment, applicable to all NFTs in the vault.
    uint256 public  royaltyPercentage; // The percentage of the sale price to be paid as royalty.

    // Mapping from token ID to its auction details.
    mapping(uint256 => Auction) public auctions;
    // Tracks whether a token ID is in the vault.
    mapping(uint256 => bool) public inVault;
    // Sale proceeds for each token ID.
    mapping(uint256 => uint256) public nftSaleProceeds;
    // Original owner of each token ID to ensure royalties are paid correctly.
    mapping(uint256 => address) private originalOwner;

    mapping(address => uint256) private pendingWithdrawals;

    // Events for Governance Actions
    event GovernanceContractUpdated(address indexed newGovernanceContract);
    event AuctionDurationUpdated(uint256 newDuration);
    event RoyaltyPercentageUpdated(uint256 newPercentage);
    event AuctionCanceledByGovernance(uint256 indexed tokenId);
    event Withdrawal(address receiver, uint256 amount);


    // Constants for the contract operation.
    uint256 public constant FRACTIONAL_TOKENS_PER_NFT = 1000; // Number of fractional tokens minted per NFT deposit.
    uint256 public  auctionDuration = 7 days; // Default duration of each auction.
    uint256 public constant AUCTION_EXTENSION = 15 minutes; // Time to extend the auction if a bid is placed near the end.
    bool private isGovernanceContractSet = false;
    modifier onlyGovernance() {
        require(msg.sender == governanceContract, "Caller is not governance contract");
        _;
    }

    // Modifier to check if the sale proceeds for an NFT exist and are positive
    modifier hasSaleProceeds(uint256 tokenId) {
        require(nftSaleProceeds[tokenId] > 0, "No proceeds available for this NFT.");
        _;
    }


    event AuctionCanceled(uint256 indexed tokenId);
    event AuctionExtended(uint256 indexed tokenId, uint256 newEndTime);



    /**
     * @dev Sets up the NFT vault with a specific NFT collection and fractional token.
     * @param _nftAddress Address of the NFT contract.
     * @param _fractionalTokenAddress Address of the fractional token contract.
     * @param _royaltyPercentage Percentage of sale price to be paid as royalty.
     */
    constructor(
        address _nftAddress,
        address _fractionalTokenAddress,
        uint256 _royaltyPercentage
    )  Ownable(msg.sender) {
        nft = IERC721(_nftAddress);
        fractionalToken = IFractionalToken(_fractionalTokenAddress);
        royaltyPercentage = _royaltyPercentage;
        governanceContract = address(0);
    }

    /**
    * @notice Sets the governance contract responsible for controlling key parameters.
     * @param _governanceContract The address of the governance contract.
     */
    function setGovernanceContract(address _governanceContract) external onlyOwner {
        require(isGovernanceContractSet == false, "Governance contract already set");

    isGovernanceContractSet = true;
        governanceContract = _governanceContract;
        emit GovernanceContractUpdated(_governanceContract);
    }


    // Getter for governance contract
    function getgovernanceContract() external view returns (address) {
        return governanceContract;
    }

     /**
     * @dev Allows a user to deposit a single NFT into the vault if it's from an accepted collection.
     * @param nftAddress Address of the NFT.
     * @param tokenId ID of the NFT token to deposit.
     */
    function depositNFT(address nftAddress, uint256 tokenId) external nonReentrant {
        require(nftAddress == address(nft), "Collection not accepted by the vault");

        nft.safeTransferFrom(msg.sender, address(this), tokenId);
        inVault[tokenId] = true;
        originalOwner[tokenId] = msg.sender;
        fractionalToken.mint(msg.sender, FRACTIONAL_TOKENS_PER_NFT);
        emit NFTDeposited(tokenId, msg.sender, FRACTIONAL_TOKENS_PER_NFT);
    }

    /**
     * @dev Allows users to deposit NFTs into the vault in exchange for fractional tokens.
     * @param tokenIds Array of NFT token IDs to deposit.
     */
    function depositNFTs(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            nft.safeTransferFrom(msg.sender, address(this), tokenId);
            inVault[tokenId] = true;
            originalOwner[tokenId] = msg.sender;
            fractionalToken.mint(msg.sender, FRACTIONAL_TOKENS_PER_NFT);
            emit NFTDeposited(tokenId, msg.sender, FRACTIONAL_TOKENS_PER_NFT);
        }
    }
/**


    /**
   * @dev Allows users to withdraw their NFT from the vault by burning the corresponding fractional tokens.
     * @param tokenId NFT token ID to withdraw.
     */
    function withdrawNFT( uint256 tokenId) external nonReentrant {
        require(inVault[tokenId], "NFT not in vault");
        require(fractionalToken.balanceOf(msg.sender) >= FRACTIONAL_TOKENS_PER_NFT, "Insufficient fractional tokens");
        inVault[tokenId] = false;
        fractionalToken.burnFrom(msg.sender, FRACTIONAL_TOKENS_PER_NFT);
        nft.safeTransferFrom(address(this), msg.sender, tokenId);
        emit NFTWithdrawn(tokenId, msg.sender);
    }



/**
 * @dev Starts an auction for a specific NFT with additional checks for asset address and duration.
 * @param assetAddress Address of the NFT asset to auction.
 * @param tokenId The ID of the NFT to auction.
 * @param startingPrice The starting price of the auction in Wei.
 * @param duration The duration of the auction in seconds.
 */
    function startAuction(address assetAddress, uint256 tokenId, uint256 startingPrice, uint256 duration) external onlyOwner {
        // Check if the NFT asset address matches the vault's NFT attribute
        require(assetAddress == address(nft), "Asset address does not match vault NFT");

        // Check if the provided duration matches the auctionDuration setting
        require(duration == auctionDuration, "Duration does not match auctionDuration setting");

        // Check if the NFT is in the vault and not already in an active auction
        require(inVault[tokenId], "NFT not in vault");
        Auction storage auction = auctions[tokenId];
        require(!auction.isActive, "Auction already active");

        // Initialize the auction with the provided starting price and calculate the end time using the provided duration
        auction.isActive = true;
        auction.endTime = block.timestamp + duration; // Use the validated duration
        auction.highestBid = startingPrice;
        auction.highestBidder = address(0);
        auction.totalBids = 0;

        emit AuctionStarted(tokenId, auction.endTime, startingPrice);
    }


    /**
       * @dev Allows users to place bids on active auctions.
     * @param assetId The ID of the NFT being auctioned.
     */
    function placeBid(uint256 assetId) external payable {
        Auction storage auction = auctions[assetId];
        require(auction.isActive, "Auction not active");
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(msg.value > auction.highestBid, "Bid too low");

        //  handle refunding the previous highest bid
        if (auction.highestBidder != address(0)) {
            // Refund the previous highest bidder by adding their bid to pendingWithdrawals
            pendingWithdrawals[auction.highestBidder] += auction.highestBid;
        }

        // update the auction with the new highest bid and bidder
        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;
        auction.totalBids++;

        // Extend auction if bid is placed in the last minute
        if (auction.endTime - block.timestamp <= 60 seconds) {
            auction.endTime += AUCTION_EXTENSION;
            emit AuctionExtended(assetId, auction.endTime);
        }

        emit BidPlaced(assetId, msg.sender, msg.value);
    }

    /**
        * @dev Ends an auction, transferring the NFT to the highest bidder and handling royalty payments.
     * @param assetId The ID of the NFT being auctioned.
     */
    function endAuction(uint256 assetId) public {
        Auction storage auction = auctions[assetId];
        require(auction.isActive, "Auction not active");
        require(block.timestamp >= auction.endTime, "Auction not yet ended");
        require(auction.highestBidder != address(0), "No bids");

        uint256 royaltyAmount = auction.highestBid * royaltyPercentage / 100; // Calculate royalty

        // Ensure the original owner is valid
        address originalOwnerAddr = originalOwner[assetId];
        require(originalOwnerAddr != address(0), "Original owner not found.");

        pendingWithdrawals[originalOwnerAddr] += royaltyAmount;

        // Deactivate the auction before transferring the NFT to avoid reentrancy concerns
        auction.isActive = false;

        // Transfer the NFT to the highest bidder
        nft.safeTransferFrom(address(this), auction.highestBidder, assetId);

        emit AuctionEnded(assetId, auction.highestBidder, auction.highestBid);
    }



    function withdraw() public nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "No funds to withdraw");

        // Reset the pending withdrawal to prevent re-entrancy
        pendingWithdrawals[msg.sender] = 0;

        // Transfer pending withdrawal to the caller
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");

        emit Withdrawal(msg.sender, amount);
    }


    /**
    * @notice Allows governance to cancel an active auction and refunds the highest bidder, if any.
 * @param assetId The ID of the token whose auction is to be canceled.
 */
    function cancelAuction(uint256 assetId) external nonReentrant onlyGovernance {
        require(auctions[assetId].isActive, "Auction is not active");

        Auction storage auction = auctions[assetId];
        // Mark the auction as inactive
        auction.isActive = false;

        // Check if there's a highest bid to refund
        if (auction.highestBid > 0 && auction.highestBidder != address(0)) {

            auction.highestBid = 0;
            auction.highestBidder = address(0);
            // Refund the highest bid
            pendingWithdrawals[auction.highestBidder] += auction.highestBid;

        }
        emit AuctionCanceledByGovernance(assetId);


    }



    /**
     * @dev Redeems fractional tokens for a share of the ETH from an NFT's sale.
     * @param tokenId The ID of the NFT whose sale proceeds are being claimed.
     * @param fractionAmount The amount of fractional tokens to redeem.
     */
    function redeemFractionValue(uint256 tokenId, uint256 fractionAmount) public nonReentrant hasSaleProceeds(tokenId) {
        uint256 totalSupply = fractionalToken.totalSupply();
        require(totalSupply > 0, "Total supply cannot be zero.");
        require(fractionalToken.balanceOf(msg.sender) >= fractionAmount, "Insufficient fractional tokens owned.");

        // Calculate the redeemable ETH amount for the given fractionAmount
        uint256 redeemableAmount = (nftSaleProceeds[tokenId] * fractionAmount) / totalSupply;
        // Update the stored proceeds to reflect the redeemed amount
        nftSaleProceeds[tokenId] = nftSaleProceeds[tokenId] - redeemableAmount;
        // Burn the fractional tokens to prevent reclamation
        fractionalToken.burnFrom(msg.sender, fractionAmount);



        // Transfer the redeemable ETH amount to the msg.sender
        (bool sent, ) = msg.sender.call{value: redeemableAmount}("");
        require(sent, "Failed to send Ether");

        emit FractionValueRedeemed(msg.sender, tokenId, fractionAmount, redeemableAmount);
    }

     /**
     * @notice Updates the auction duration through governance decisions.
     * @param _newDuration The new auction duration in seconds.
     */
    function updateAuctionDuration(uint256 _newDuration) external onlyGovernance {
        auctionDuration = _newDuration;
        emit AuctionDurationUpdated(_newDuration);
    }

    /**
     * @notice Updates the royalty percentage through governance decisions.
     * @param _newPercentage The new royalty percentage.
     */
    function updateRoyaltyPercentage(uint256 _newPercentage) external onlyGovernance {
        royaltyPercentage = _newPercentage;
        emit RoyaltyPercentageUpdated(_newPercentage);
    }


    // Getter for checking if a specific tokenId is in the vault
    function isTokenInVault(uint256 tokenId) external view returns (bool) {
        return inVault[tokenId];
    }

    // Getter for retrieving the original owner of a specific tokenId
    function getOriginalOwner(uint256 tokenId) external view returns (address) {
        return originalOwner[tokenId];
    }


    // Getter for auction details of a specific tokenId
    function getAuctionDetails(uint256 tokenId) external view returns (bool, uint256, uint256, address, uint256) {
        Auction memory auction = auctions[tokenId];
        return (auction.isActive, auction.endTime, auction.highestBid, auction.highestBidder, auction.totalBids);
    }

    // Getter for the sale proceeds of a specific tokenId
    function getNFTSaleProceeds(uint256 tokenId) external view returns (uint256) {
        return nftSaleProceeds[tokenId];
    }

    // Getter for the royalty percentage
    function getRoyaltyPercentage() external view returns (uint256) {
        return royaltyPercentage;
    }

    // Getter for the auction duration
    function getAuctionDuration() external view returns (uint256) {
        return auctionDuration;
    }

}
