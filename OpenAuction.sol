// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
contract OpenAuction {
    address payable public beneficiary;
    uint public auctionEndTime;

    //current state of the auction
    address public highestBidder;
    uint public highestBid;

    mapping(address => uint) pendingReturns;
    
    //intitialized to 'false' and set to 'true' at the end.
    bool ended;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor(uint biddingTime, address payable beneficiaryAddress) {
        auctionEndTime = block.timestamp + biddingTime;        
        beneficiary = beneficiaryAddress;
    }

    function bid() external payable {
        require(block.timestamp <= auctionEndTime);
        require(msg.value > highestBid);
        if(highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function withdraw () external returns(bool){
        uint amount = pendingReturns[msg.sender];
        if(amount > 0) {
            pendingReturns[msg.sender] = 0;
            if(!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    //End the auction and send the highest bid to the beneficiary.
    function endAuction() external {
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        beneficiary.transfer(highestBid);
    }
}