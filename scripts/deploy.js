const { ethers, run, network } = require("hardhat")

async function main() {
    const SimpleStorageFactory = await ethers.getContractFactory(
        "SimpleStorage"
    )

    console.log("Deploying contract...")

    const simpleStorage = await SimpleStorageFactory.deploy()

    await simpleStorage.deployed()

    console.log(`Deployed contract to: ${simpleStorage.address}`)

    if (network.config.chainId === 4 && process.env.ETHERSCAN_API_KEY) {
        console.log("Waiting for block confirmations...")
        await simpleStorage.deployTransaction.wait(6) // We will wait 6 blocks
        await verify(simpleStorage.address, [])
    }

    //Interacting with the contract
    const currValue = await simpleStorage.retrieve()
    console.log(`Current value is: ${currValue}`)

    const transactionResponse = await simpleStorage.store(7)
    await transactionResponse.wait(1) // Wait 1 block for that transaction to go through

    const updatedValue = await simpleStorage.retrieve()
    console.log(`Updated value is: ${updatedValue}`)
}

async function verify(contractAddress, args) {
    console.log("Verifying contract...")
    try {
        await run("verify:verify", {
            address: contractAddress,
            constructorArguments: args,
        })
    } catch (e) {
        if (e.message.toLowerCase().includes("already verified")) {
            console.log("The contract was already verified!")
        } else {
            console.log(e)
        }
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
