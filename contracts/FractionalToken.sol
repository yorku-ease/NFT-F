// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IFractionalToken.sol";

/**
 * @title FractionalToken
 * @dev ERC20 Token representing fractional ownership of NFTs, with minting and burning capabilities.
 */
contract FractionalToken is  ERC20Burnable, Ownable {
    address public nftVault;
    bool private isNftVaultSet = false;
    event updatedNFTVault(address newVaultAddress);

    /**
     * @dev Constructor that sets the token details and the NFT Vault address.
     * @param _name The name of the fractional token.
     * @param _symbol The symbol of the fractional token.
     */
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) Ownable(msg.sender)  {
    nftVault = address(0);
    }

    modifier onlyVault() {
        require(msg.sender == nftVault, "FractionalToken: caller is not the NFT Vault");
        _;
    }

    function mint(address to, uint256 amount) public onlyVault {
        _mint(to, amount);
    }

    function burnFrom(address from, uint256 amount) public override onlyVault {
        _burn(from, amount);
    }

    /**
     * @dev Update the NFT Vault address in case of changes.
     * @param newVaultAddress The new address of the NFT Vault contract.
     */
    function updateNFTVault(address newVaultAddress) public onlyOwner {

        require(!isNftVaultSet, "NFT Vault already set");

        require(newVaultAddress != address(0), "FractionalToken: vault address already set");
        nftVault = newVaultAddress;
        isNftVaultSet = true;
        emit updatedNFTVault(newVaultAddress);

    }
}
