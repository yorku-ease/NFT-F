// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./GovernanceContract.sol";

contract MockToken is IERC20 {
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    constructor() {
        balanceOf[msg.sender] = 1000; // Initial supply to the deployer for testing
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        return true;
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        require(allowance[from][msg.sender] >= value, "Allowance exceeded");
        require(balanceOf[from] >= value, "Insufficient balance");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        return true;
    }

    function totalSupply() external pure override returns (uint256) {
        return 1000;
    }
}


contract GovernanceContractTest  {
    GovernanceContract public governance;
    MockToken public token;
    uint256 public votingPeriod = 7 days;
    uint256 public initialProposalCount;

    constructor() {
        token = new MockToken();
        governance = new GovernanceContract(address(token), payable(address(this)));
        token.transfer(address(this), 500);
        token.approve(address(governance), 500); // Approve governance to use tokens

        // Create an initial proposal
        governance.createProposal("Initial Proposal", address(this), "0x00");
        initialProposalCount = governance.proposalCount();
    }


    // Ensure that voting on a proposal correctly increases the vote count
    function echidna_test_voting_increases_votes() public returns (bool) {
        uint256 proposalId = 0; // Assuming a proposal with ID 0 exists and is active
        governance.vote(proposalId, true); // Vote on the proposal

        (,,,,,,,uint256 votesFor,,) = governance.proposals(proposalId);
        return votesFor > 0; // Expect votes to increase
    }

    function echidna_test_quorum_not_met() public returns (bool) {
        uint256 proposalId = initialProposalCount - 1; // Use the last proposal ID
        // Assuming `getProposalStatus` returns a string that can be "Approved" or something else
        string memory status = governance.getProposalStatus(proposalId);
        // Check if status is not "Approved" since quorum was not met
        return keccak256(abi.encodePacked(status)) != keccak256(abi.encodePacked("Approved"));
    }


    function echidna_test_create_proposal() public returns (bool) {
        // Setup tokens for proposal creation if necessary
        uint256 requiredBalance = token.totalSupply() * 5 / 100;
        if (token.balanceOf(address(this)) < requiredBalance) {
            token.transfer(address(this), requiredBalance);
            token.approve(address(governance), requiredBalance);
        }

        // Create a new proposal
        governance.createProposal("Test Proposal", address(this), "0x00");
        // Check if a new proposal was added
        return governance.proposalCount() == initialProposalCount + 1;
    }





}
