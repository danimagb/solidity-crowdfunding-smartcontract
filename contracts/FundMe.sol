// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

//ContractName__ErrorCode
error FundMe__NotOwner();

/** @title A contract for crowd funding
 * @author Daniel Magalhães
 * @notice This contract is to demo a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18; // 1 * 10 ** 18

    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;

    address private immutable i_owner;

    AggregatorV3Interface private s_priceFeed;

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    constructor(address s_priceFeedAdress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(s_priceFeedAdress);
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

    /**
     * @notice This function funds this contract
     * @dev This implements price feeds as our library
     */
    function fund() public payable {
        // Requires that the value is at least 1 ETH
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough"
        ); //1e18 == 1 * 10 ** 18 = 1000000000000000000

        // If the requirement isn't met, a revert occurs
        // revert undo any action before, and send remaining gas back
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    /**
     * @notice This function withdraw (transfers) the balance of the contract to another accout address
     * @dev It only works if the sender is the same as the owner of the contract
     */
    function withDraw() public onlyOwner {
        // We are saving s_funders into memory so we don't need to read from storage during the loop
        // Reading from storage would cost a huge amount of gas
        // mappings can't be in memory :(
        address[] memory funders = s_funders;

        for (uint256 index = 0; index < funders.length; index++) {
            address funder = funders[index];
            s_addressToAmountFunded[funder] = 0;
        }

        // Reset funders array
        s_funders = new address[](0);

        // Sending eth from a contract
        // In order to transfer native blockchain tokens you can only work with payable address
        // There are 3 ways to do this:

        // transfer (Throws and error if it fails and reverts the transaction)
        //payable(msg.sender).transfer(address(this).balance);

        // send (Returns bool and only revert the transaction if we add the require making sure that the result of the send operation is true)
        //bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //require(sendSuccess, "Send failed");

        // call ( Recommended way. Returns a bool and allow to call a function in blockchain, like we were doing a transaction.
        // In this case no function is being called because we are transfering native blockchain tokens)
        (bool callSuccess, ) = i_owner.call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    /** @notice Gets the amount that an address has funded
     *  @param fundingAddress the address of the funder
     *  @return the amount funded
     */
    function getAddressToAmountFunded(address fundingAddress)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
