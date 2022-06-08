const { expect, assert } = require("chai")
const { ethers } = require("hardhat")

describe("SimpleStorage", function () {
    let simpleStorageFactory, simpleStorage
    beforeEach(async function () {
        simpleStorageFactory = await ethers.getContractFactory("SimpleStorage")

        simpleStorage = await simpleStorageFactory.deploy()
    })

    it("Should start with a favorite number of 0", async function () {
        // Arrange
        const expectedValue = "0"

        // Act
        const currentValue = await simpleStorage.retrieve()

        // Assert
        assert.equal(currentValue.toString(), expectedValue)
    })
    it("Should update favorite number when store is called", async function () {
        // Arrange
        const expectedValue = "7"

        // Act
        const transactionResponse = await simpleStorage.store(expectedValue)
        await transactionResponse.wait(1)

        //Assert
        const currentValue = await simpleStorage.retrieve()
        assert.equal(currentValue, expectedValue)
    })
})
