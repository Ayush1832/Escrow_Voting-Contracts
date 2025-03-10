
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SecureVoting {
    struct Elector {
        bool isRegistered;
        bool hasVoted;
        bytes32 votedFor;
    }

    address public admin;
    uint256 public registrationEndTime;
    mapping(address => Elector) public electors;
    mapping(bytes32 => uint256) public voteCounts;
    mapping(address => bool) public blacklistedElectors;

    event ElectorRegistered(address elector);
    event VoteSubmitted(address elector, bytes32 candidate);
    event ElectorBlacklisted(address elector);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Admin Only");
        _;
    }

    modifier registrationOngoing() {
        require(block.timestamp < registrationEndTime, "Registration period has ended");
        _;
    }

    modifier onlyRegisteredElectors() {
        require(electors[msg.sender].isRegistered, "Elector is not registered");
        _;
    }

    constructor() {
        admin = msg.sender;
        registrationEndTime = 1720895400; // 14th July 2024
    }

    function registerElector() public registrationOngoing {
        require(!electors[msg.sender].isRegistered, "Elector already registered");
        electors[msg.sender] = Elector({isRegistered: true, hasVoted: false, votedFor: ""});
        emit ElectorRegistered(msg.sender);
    }

    function submitVote(bytes32 _candidate) public onlyRegisteredElectors {
        require(!blacklistedElectors[msg.sender], "Elector is blacklisted");
        Elector storage elector = electors[msg.sender];
        require(!elector.hasVoted, "Elector has already voted");

        elector.hasVoted = true;
        elector.votedFor = _candidate;
        voteCounts[_candidate]++;
        emit VoteSubmitted(msg.sender, _candidate);
    }

    function blacklistElector(address _elector) public onlyAdmin {
        require(electors[_elector].isRegistered, "Elector is not registered");
        require(!blacklistedElectors[_elector], "Elector is already blacklisted");

        if (electors[_elector].hasVoted) {
            revokeVote(_elector);
        }

        blacklistedElectors[_elector] = true;
        emit ElectorBlacklisted(_elector);
    }

    function revokeVote(address _elector) internal {
        Elector storage elector = electors[_elector];
        if (elector.hasVoted) {
            bytes32 candidate = elector.votedFor;
            voteCounts[candidate]--;
            elector.hasVoted = false;
            elector.votedFor = "";
        }
    }

    function getVoteCount(bytes32 _candidate) public view returns (uint256) {
        return voteCounts[_candidate];
    }
}
