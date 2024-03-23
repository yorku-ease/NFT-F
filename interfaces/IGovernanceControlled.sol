// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title IGovernanceControlled
 * @notice Interface for governance actions within the NFT Vault system.
 * Allows for configuration and administrative tasks to be performed by governance mechanisms.
 */
interface IGovernanceControlled {
    /**
     * @notice Sets a new governance contract address.
     * @param _governanceContract Address of the new governance contract.
     */
    function setGovernanceContract(address _governanceContract) external;

    /**
     * @notice Updates the auction duration for all future auctions.
     * @param _newDuration New duration in seconds.
     */
    function updateAuctionDuration(uint256 _newDuration) external;

    /**
     * @notice Updates the royalty percentage for all NFT sales.
     * @param _newPercentage New royalty percentage.
     */
    function updateRoyaltyPercentage(uint256 _newPercentage) external;

    /**
     * @notice Allows governance to cancel an active auction, typically for emergency use.
     * @param tokenId The ID of the NFT whose auction is to be canceled.
     */
    function cancelAuction(uint256 tokenId) external;
}
