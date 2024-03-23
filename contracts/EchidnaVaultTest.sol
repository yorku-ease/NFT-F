// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Vault.sol";

// Simplified mock ERC721 token for testing purposes
contract MockERC721 {
    mapping(uint256 => address) private _owners;

    function setOwnerOf(uint256 tokenId, address owner) public {
        _owners[tokenId] = owner;
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return _owners[tokenId];
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        require(_owners[tokenId] == from, "MockERC721: transfer from incorrect owner");
        _owners[tokenId] = to;
    }
}




/**
 * @title VaultEchidnaTest
 * @dev Echidna testing contract for the Vault
 */
contract EchidnaVaultTest  {
    Vault public vault;
    MockERC721 public mockERC721;
    address constant echidna_caller = address(0x100);

    // Constructor to deploy the Vault contract for testing
    constructor() {
        mockERC721 = new MockERC721();
        vault = new Vault(address(mockERC721), address(0), 0); // Using mockERC721 for testing
        vault.transferOwnership(echidna_caller);
        mockERC721.setOwnerOf(1, echidna_caller); // Simulate echidna_caller owning token 1
    }

    // Test that the governance contract can only be set once
    function echidna_test_set_governance_contract_once() public returns (bool) {
        return vault.getgovernanceContract() == address(0);
    }

    // Ensure auction duration cannot be set to 0 by the governance contract
    function echidna_test_auction_duration_positive() public returns (bool) {
        return vault.getAuctionDuration() > 0;
    }

    // Check that the royalty percentage is within a reasonable range (0-100%)
    function echidna_test_royalty_percentage_range() public returns (bool) {
        uint256 royaltyPercentage = vault.getRoyaltyPercentage();
        return royaltyPercentage >= 0 && royaltyPercentage <= 100;
    }

    // Verify that tokens cannot be withdrawn without sufficient balance
    function echidna_test_withdraw_without_balance() public returns (bool) {
        // Attempt to withdraw with no prior balance or deposits, expecting failure
        try vault.withdraw() {
            return false; // Withdraw should not succeed
        } catch {
            return true; // Expected to fail, thus passing the test
        }
    }

    // Ensure that the original owner of an NFT is correctly set upon deposit
    function echidna_test_original_owner_set_on_deposit() public returns (bool) {
        // Simulate deposit action by transferring token 1 from echidna_caller to the vault
        mockERC721.safeTransferFrom(echidna_caller, address(vault), 1);

        address originalOwner = vault.getOriginalOwner(1);
        return originalOwner == echidna_caller; // Should pass if the original owner is correctly set
    }

}
