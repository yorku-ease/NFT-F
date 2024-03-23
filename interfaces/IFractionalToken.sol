// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IFractionalToken
 * @dev Interface for the FractionalToken contract representing fractional ownership of NFTs,
 *      extending IERC20 and IERC20Burnable for ERC20 functionality and burning capabilities.
 */
interface IFractionalToken is IERC20 {
    /**
     * @dev Allows the NFT Vault to mint fractional tokens to a specified address.
     * This function is unique to the fractional token system and not part of the IERC20 interface.
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to be minted.
     */
    function mint(address to, uint256 amount) external;


    /**
     * @dev Allows the NFT Vault to burn fractional tokens from a holder's balance.
     * @param from The address whose tokens will be burned.
     * @param amount The amount of tokens to burn.
     */
    function burnFrom(address from, uint256 amount) external;

    /**
     * @dev Updates the address of the NFT Vault authorized to mint and burn tokens.
     * This function is unique to the fractional token system and not part of the IERC20 or IERC20Burnable interfaces.
     * @param newVaultAddress The new NFT Vault address.
     */


    function updateNFTVault(address newVaultAddress) external;

    /**
     * @dev Returns the current address of the NFT Vault.
     * This function is unique to the fractional token system and not part of the IERC20 interface.
     * @return The address of the NFT Vault.
     */
    function nftVault() external view returns (address);
}
