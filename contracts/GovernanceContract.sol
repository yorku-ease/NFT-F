// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Importing required OpenZeppelin contracts for ERC20 token interactions, ownership management, security, and mathematical operations.
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/governance/TimelockController.sol";
import "../interfaces/INFTGovernance.sol";
import "../node_modules/@openzeppelin/contracts/utils/ReentrancyGuard.sol";
/**
 * @title Governance Contract for Fraction Holders
 * @dev This contract implements governance functionalities enabling fraction holders to vote on proposals.
 * It integrates with a TimelockController to schedule and execute proposals after a delay, enhancing security.
 */
contract GovernanceContract is INFTGovernance, Ownable, ReentrancyGuard {

    // ERC20 governance token used for voting.
    IERC20 public governanceToken;

    // TimelockController instance to manage proposal scheduling and execution with a delay.
    TimelockController public timelockController;

    // Struct to define the properties of a governance proposal.
    struct Proposal {
        string description; // Description of what the proposal intends to achieve.
        address target; // Contract address where the proposal call will be made.
        bytes data; // Encoded function call to be executed.
        uint256 votingStart; // Timestamp when voting starts.
        uint256 votingEnd; // Timestamp when voting ends.
        bool executed; // Flag indicating if the proposal has been executed.
        uint256 votesFor; // Total votes in favor of the proposal.
        uint256 votesAgainst; // Total votes against the proposal.
        uint256 totalVotes; // Total votes cast.
        uint256 totalTokenSupplyAtCreation; // Snapshot of total token supply at proposal creation for quorum calculation.
    }

    // Quorum required as a percentage of total token supply for proposal to be valid.
    uint256 public constant QUORUM_PERCENTAGE = 50;

    // Counter for proposal IDs.
    uint256 public proposalCount = 0;

    // Mapping from proposal ID to Proposal struct.
    mapping(uint256 => Proposal) public proposals;

    // Default voting period for proposals, can be updated through governance actions.
    uint256 public votingPeriod = 7 days;



    // Constructor to initialize governance token and timelock controller addresses.
    constructor(address _governanceToken, address payable _timelockController)  Ownable(msg.sender){
        require(_governanceToken != address(0), "Invalid governance token address");
        require(_timelockController != address(0), "Invalid TimelockController address");
         governanceToken = IERC20(_governanceToken);
        timelockController = TimelockController(_timelockController);

    }

    // Modifier to ensure actions are taken within the active voting period of a proposal.
    modifier isActiveProposal(uint256 proposalId) {
        require(block.timestamp >= proposals[proposalId].votingStart && block.timestamp <= proposals[proposalId].votingEnd, "Voting is not active");
        _;
    }

    /**
     * @notice Creates a new proposal.
     * @param description A brief description of the proposal.
     * @param target The contract address the proposal will interact with.
     * @param data The encoded function call to be executed.
     */
    function createProposal(string memory description, address target, bytes memory data) public {
        uint256 holderBalance = governanceToken.balanceOf(msg.sender);
        uint256 totalSupply = governanceToken.totalSupply();
        require(holderBalance >= totalSupply * 5 / 100, "Insufficient token balance to create proposal");
        uint256 proposalId = proposalCount++;
        Proposal storage proposal = proposals[proposalId];
        proposal.description = description;
        proposal.target = target;
        proposal.data = data;
        proposal.votingStart = block.timestamp;
        proposal.votingEnd = block.timestamp + votingPeriod;
        proposal.executed = false;
        proposal.totalTokenSupplyAtCreation = totalSupply; // Snapshot of total supply at proposal creation

        emit ProposalCreated(proposalId, description, proposal.votingStart, proposal.votingEnd);
    }

    /**
     * @notice Allows a token holder to cast their vote on an active proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support A boolean indicating if the vote is in favor (true) or against (false).
     */
    function vote(uint256 proposalId, bool support) public isActiveProposal(proposalId) nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        uint256 weight = governanceToken.balanceOf(msg.sender);
        require(weight > 0, "No voting power");

        if (support) {
            proposal.votesFor += weight;
        } else {
            proposal.votesAgainst += weight;
        }
        proposal.totalVotes += weight;

        emit Vote(proposalId, msg.sender, support, weight);
    }

    /**
     * @notice Executes a proposal after the voting period has ended and if it is approved by the quorum.
     * @param proposalId The ID of the proposal to be executed.
     */
    function executeProposal(uint256 proposalId) public nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        uint256 quorumRequired = proposal.totalTokenSupplyAtCreation * QUORUM_PERCENTAGE / 100;
        require(block.timestamp > proposal.votingEnd, "Voting has not ended");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.totalVotes >= quorumRequired, "Quorum not reached");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal not approved");

        proposal.executed = true;

        // Scheduling the action through TimelockController for execution after the time lock expires
        timelockController.schedule(proposal.target, 0, proposal.data, bytes32(0), bytes32(0), 2 days);

        emit ProposalExecuted(proposalId);
    }



    /**
     * @notice Retrieves the current status of a proposal.
     * @param proposalId The ID of the proposal.
     * @return status The current status of the proposal as a string.
     */
    function getProposalStatus(uint256 proposalId) public view returns (string memory status) {
        Proposal storage proposal = proposals[proposalId];
        if (!proposal.executed) {
            if (block.timestamp < proposal.votingStart) {
                return "Pending";
            } else if (block.timestamp >= proposal.votingStart && block.timestamp <= proposal.votingEnd) {
                return "Active";
            } else {
                return "Voting Ended";
            }
        }
        return proposal.votesFor > proposal.votesAgainst ? "Approved" : "Rejected";
    }
}
