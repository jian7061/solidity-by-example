// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
contract SafeRemotePurchase{
    uint public value;
    address payable seller;
    address payable buyer;

    enum State {Created, Locked, Release, Inactive}
    State public state;

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this function");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this function");
        _;
    }

    modifier inState(State state_) {
        require(state == state_);
        _;
    }

    event Aborted();
    event PurchaseConfirmed();
    event ItemReceived();
    event SellerRefunded();

    constructor() payable {
        seller = payable(msg.sender);
        value = msg.value / 2;
        //check that msg.value is an even number.
        require((2 * value) == msg.value, "Value is an odd number");
    }

    //Only seller can abort the purchase and reclaim the ether before the contract is locked.
    function abort() external onlySeller inState(State.Created){
        emit Aborted();
        state = State.Inactive;

        seller.transfer(address(this).balance);
    }

    function confirmPurchase() external inState(State.Created) payable {
        require(msg.value ==(2 * value));

        emit PurchaseConfirmed();
        buyer = payable(msg.sender);
        state = State.Locked;
    }

    function confirmReceived() external payable onlyBuyer inState(State.Locked) {
        emit ItemReceived();
        state = State.Release;
        buyer.transfer(value);
    }

    function refundSeller() external payable onlySeller inState(State.Release) {
        emit SellerRefunded();
        state = State.Inactive;
        seller.transfer(3 * value);
    }
}