// const FractionalToken = artifacts.require("FractionalToken");
//
// module.exports = function(deployer) {
//     // Define token name and symbol
//     const tokenName = "FractionalToken";
//     const tokenSymbol = "FT";
//
//     deployer.deploy(FractionalToken, tokenName, tokenSymbol);
// };
const SimpleStorage = artifacts.require("SimpleStorage");

module.exports = function (deployer) {
    deployer.deploy(SimpleStorage);
};
