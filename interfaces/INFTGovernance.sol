// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IFractionHolderGovernance.sol
 * @dev Interface for the FractionHolderGovernance contract.
 * This interface abstracts governance functionalities for fraction holders to vote on proposals.
 */
interface INFTGovernance {
    /**
     * @notice Creates a new governance proposal.
     * @param description The description of what the proposal intends to achieve.
     * @param target The contract address where the proposal call will be made.
     * @param data The encoded function call to be executed.
     */
    function createProposal(string memory description, address target, bytes memory data) external;

    /**
     * @notice Allows a token holder to vote on an active proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True if the vote is in favor of the proposal, false otherwise.
     */
    function vote(uint256 proposalId, bool support) external;

    /**
     * @notice Executes a proposal that has met the quorum and voting criteria.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external;


    /**
     * @notice Retrieves the current status of a proposal.
     * @param proposalId The ID of the proposal.
     * @return status The current status of the proposal.
     */
    function getProposalStatus(uint256 proposalId) external view returns (string memory status);

    // Events
    event ProposalCreated(uint256 indexed proposalId, string description, uint256 votingStart, uint256 votingEnd);
    event Vote(uint256 indexed proposalId, address indexed voter, bool vote, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);
    event VotingPeriodUpdated(uint256 newVotingPeriod);
}
