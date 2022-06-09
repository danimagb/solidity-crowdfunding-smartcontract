const { network } = require("hardhat")
const { networkConfig, developmentChains } = require("../helper-hardhat-config")
const { verify } = require("../utils/etherScanContractVerifier")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts() // get namedAccounts defined in hardhatconfig.js
    const chainId = network.config.chainId

    // if pricefeedAdress contract doesn't exist in the test net we are deploying into (e.g: local test network)
    // we need to deploy a mock implementation of that pricefeed contract
    // If it is a testnet we can choose pricefeedAdress based on the chain Id we are deploying our contract in
    let ethUsdPriceFeedAddress
    if (developmentChains.includes(network.name)) {
        const ethUsdAggregator = await deployments.get("MockV3Aggregator")
        ethUsdPriceFeedAddress = ethUsdAggregator.address
    } else {
        ethUsdPriceFeedAddress =
            networkConfig[chainId]["ethUsdPriceFeedAddress"]
    }

    //when going for localhost or hardhat network we want to use a mock
    const fundMe = await deploy("FundMe", {
        from: deployer,
        args: [ethUsdPriceFeedAddress], // priceFeed address here,
        log: true,
        waiConfirmations: network.config.blockConfirmations | 1,
    })

    if (
        !developmentChains.includes(network.name) &&
        process.env.ETHERSCAN_API_KEY
    ) {
        await verify(fundMe.address, [ethUsdPriceFeedAddress])
    }

    log("---------------------------------------------")
}

module.exports.tags = ["all", "fundme"]
