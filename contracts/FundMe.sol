// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18; // 1 * 10 ** 18

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAdress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAdress);
    }

    function fund() public payable {
        // Requires that the value is at least 1 ETH
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough"
        ); //1e18 == 1 * 10 ** 18 = 1000000000000000000

        // If the requirement isn't met, a revert occurs
        // revert undo any action before, and send remaining gas back
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withDraw() public onlyOwner {
        require(msg.sender == i_owner, "Only the owner can withdraw");

        for (uint256 index = 0; index < funders.length; index++) {
            address funder = funders[index];
            addressToAmountFunded[funder] = 0;
        }

        // Reset funders array
        funders = new address[](0);

        // Sending eth from a contract
        // msg.sender = address
        // payable(msg.sender) = payable address
        // in order to transfer native blockchain tokens you can only work with payable address
        // There are 3 ways to do this:

        // transfer (Throws and error if it fails and reverts the transaction)
        payable(msg.sender).transfer(address(this).balance);

        // send (Returns bool and only revert the transaction if we add the require making sure that the result of the send operation is true)
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed");

        // call ( Recommended way. Returns a bool and allow to call a function in blockchain, like we were doing a transaction.
        // In this case no function is being called because we are transfering native blockchain tokens)
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    // Old way of reverting transactions
    // modifier onlyOwner{
    //     require(msg.sender == i_owner, "Only the owner can withdraw");
    //     _;
    // }

    // New way of reverting transactions with custom errors
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    // What happens if someone send this contract ETH without calling the 'fund' function?
    // We need to implement the 'receive' and 'fallback' special functions to call 'fund'
    // More information about how these functions are executed in the file ./FallbackExample.sol

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}
