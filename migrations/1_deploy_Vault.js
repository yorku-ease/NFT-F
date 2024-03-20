const Vault = artifacts.require("Vault");
const FractionalToken = artifacts.require("FractionalToken");
const MyToken = artifacts.require("MyToken");
const GovernanceContract = artifacts.require("GovernanceContract");
const TimelockController = artifacts.require("TimelockController");
const MarketIntegration = artifacts.require("MarketIntegration");


module.exports = async function (deployer, network, accounts) {
    // Deploy FractionalToken first
    await deployer.deploy(FractionalToken, "FractionalToken", "FTK");
    const fractionalTokenInstance = await FractionalToken.deployed();

    await deployer.deploy(FractionalToken, "tokenB", "TB");
    const tokenBAddress = await FractionalToken.deployed();

    await deployer.deploy(MyToken);
    const myTokenInstance = await MyToken.deployed();

    // Deploy Vault with references to NFT and FractionalToken contracts
    await deployer.deploy(Vault, myTokenInstance.address, fractionalTokenInstance.address, 5);
    const vault = await Vault.deployed();

    // Deploy TimelockController
    const minDelay = 60; // Minimum delay for timelock (in seconds)
    const proposers = [accounts[0]]; // Array of proposers
    const executors = [accounts[0]]; // Array of executors
    const adminAddress = accounts[0];
    await deployer.deploy(TimelockController, minDelay, proposers, executors, adminAddress);
    const timelockController = await TimelockController.deployed();

    // Deploy GovernanceContract
    await deployer.deploy(GovernanceContract, fractionalTokenInstance.address, timelockController.address);
    const governanceContract = await GovernanceContract.deployed();

    // Set GovernanceContract in Vault
    await vault.setGovernanceContract(governanceContract.address);

    // Deploy MarketIntegration
    await deployer.deploy(MarketIntegration, fractionalTokenInstance.address, tokenBAddress.address);
    const marketIntegration = await MarketIntegration.deployed();

};
