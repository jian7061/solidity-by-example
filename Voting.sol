// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
/// @title Voting 
contract Voting {
    //a single voter.
    struct Voter {
        bool isVoted;
        uint indexOfVote;
        uint weight; //accumulated by delegation.
        address delegate;
    }

    //a single proposal
    struct Proposal {
        bytes32 name;
        uint count; 
    }
    
    address public admin;

    mapping(address => Voter) public voters;

    Proposal[] public proposals;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only Admin can execute");
        _;
    }

    modifier onlyOneVote(address voter) {
        require(!voters[voter].isVoted, "You already voted");
        _;
    }

    modifier haveRightToVote(address voter) {
        require(voters[voter].weight!=0,"You don't have the right to vote");
        _;
    }

    modifier haveNoRightToVote(address voter) {
        require(voters[voter].weight==0,"You already have the right to vote");
        _;
    }

    //create a ballot by suggesting one or more proposals.
    constructor(bytes32[] memory proposalNames) {
        admin =  msg.sender;
        voters[admin].weight = 1;

        for(uint i = 0; i < proposalNames.length; i++) {
            proposals.push(
                Proposal({
                    name: proposalNames[i],
                    count: 0
                })
            );
        }
    }

    //give 'voter' the right to vote on this ballot.
    function giveRightToVote(address voter) external onlyAdmin onlyOneVote(voter) haveNoRightToVote(voter){
        voters[voter].weight = 1;
    }

    //delegate your right to vote to another voter.
    function delegate(address to) external haveRightToVote(msg.sender) onlyOneVote(msg.sender) {
        require(to != msg.sender, "Self-delegation is not allowed");
        while(voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            require(to != msg.sender, "Found a loop in delegation");
        }
        //check that delegate has the right to vote
        require(voters[to].weight !=0);
        voters[msg.sender].isVoted = true;
        voters[msg.sender].delegate = to;
        if(voters[to].isVoted) {
            proposals[voters[to].indexOfVote].count += voters[msg.sender].weight;
        } else {
            voters[to].weight += voters[msg.sender].weight;
        }
    }

    function vote(uint proposal) external haveRightToVote(msg.sender) onlyOneVote(msg.sender) {
        voters[msg.sender].isVoted = true;
        voters[msg.sender].indexOfVote = proposal;

        proposals[proposal].count += voters[msg.sender].weight;
    }

    function winningProposal() public view returns(bytes32 winningProposalName) {
        uint winningVoteCount = 0;
        for(uint p=0; p < proposals.length; p++) {
            if(proposals[p].count > winningVoteCount) {
                winningVoteCount = proposals[p].count;
                winningProposalName = proposals[p].name;
            }
        }
    }

}