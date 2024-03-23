// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./FractionalToken.sol";

contract FractionalTokenTest is FractionalToken {
    constructor() FractionalToken("FractionalTestToken", "FTT") {}

    // Test that minting fails if called by an address other than nftVault
    function echidna_test_mint() public returns (bool) {
        address nonVaultCaller = address(0x123); // Example address
        try this.mint(nonVaultCaller, 10) {
            // If mint succeeds, the test should fail
            return false;
        } catch {
            // Mint failed as expected, test passes
            return true;
        }
    }

    // This test ensures that only the NFT Vault can burn tokens
    function echidna_test_burn() public returns (bool) {
        address nonVaultCaller = address(0x456); // Example non-vault address
        try this.burnFrom(nonVaultCaller, 10) {
            // If burn succeeds, the test should fail
            return false;
        } catch {
            // Burn failed as expected, test passes
            return true;
        }
    }



  // This test checks that the total supply of the token remains constant if no minting or burning operations are performed.
    uint256 initialTotalSupply = totalSupply();

    function echidna_test_total_supply_constant() public view returns (bool) {
        return totalSupply() == initialTotalSupply;
    }

    address newVaultAddress = address(0xABC); // New vault address for testing






}
