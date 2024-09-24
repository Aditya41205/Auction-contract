// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;
contract SimpleAuction {
    address payable public owner;   // Auction owner (who is selling the item)
    uint public auctionEndTime;     // Auction end time
    address public highestBidder;   // Address of the highest bidder
    uint public highestBid;         // Value of the highest bid

    // To keep track of bids from other users (so they can withdraw if they lose)
    mapping(address => uint) public pendingReturns;

    // Auction state
    bool ended = false;

    // Events
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    // Constructor to initialize the auction
    constructor(uint _biddingTime) {
        owner = payable(msg.sender);
        auctionEndTime = block.timestamp + _biddingTime; // _biddingTime is in seconds
    }

    // Bid function
    function bid() public payable {
        // Ensure the auction is still running
        require(block.timestamp < auctionEndTime, "Auction has ended.");
        
        // Ensure the bid is higher than the current highest bid
        require(msg.value > highestBid, "There is already a higher or equal bid.");

        // Return the previous highest bid to the previous highest bidder
        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        // Update the highest bid and the highest bidder
        highestBidder = msg.sender;
        highestBid = msg.value;

        emit HighestBidIncreased(msg.sender, msg.value);
    }

    // Withdraw function to allow non-winning bidders to get their money back
    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            if (!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    // Function to end the auction, only the owner can call this
    function endAuction() public {
        // Ensure the auction has ended
        require(block.timestamp >= auctionEndTime, "Auction is still ongoing.");
        // Ensure the function is called only once
        require(!ended, "Auction end has already been called.");
        // Ensure the caller is the owner
        require(msg.sender == owner, "Only the owner can end the auction.");

        // Mark the auction as ended
        ended = true;

        // Trigger event
        emit AuctionEnded(highestBidder, highestBid);

        // Send the highest bid to the owner
        owner.transfer(highestBid);
    }
}