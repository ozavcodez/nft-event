// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract EventOrganizer {
    uint256 public totalEventsCreated;

    struct OrganizedEvent {
        uint256 eventId;
        string eventName;
        string location;
        string details;
        address organizer;
        uint256 startTime;
        uint256 endTime;
        uint256 creationTimestamp;
        uint256 maxParticipants;
        bool isRegistrationClosed;
        bool isEventCancelled;
        address nftRequired;  // Address of the NFT collection required to register
        address[] participants;
        mapping(address => bool) attendanceRecord;
    }

    mapping(uint256 => OrganizedEvent) public eventRegistry;
    mapping(address => mapping(uint256 => bool)) public userRegistrations; // Tracks whether a user has registered for an event


    // Create a new event
    function organizeEvent(
        address _nftRequired,
        string memory _eventName,
        string memory _location,
        string memory _details,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _maxParticipants
    ) external returns (uint256) {
        require(_nftRequired != address(0), "NFT collection address required");
        require(bytes(_eventName).length > 0, "Event name required");
        require(_startTime < _endTime, "Invalid event timings");

        totalEventsCreated++;
        OrganizedEvent storage newEvent = eventRegistry[totalEventsCreated];
        newEvent.eventId = totalEventsCreated;
        newEvent.eventName = _eventName;
        newEvent.location = _location;
        newEvent.details = _details;
        newEvent.organizer = msg.sender;  // Set the caller as the organizer
        newEvent.startTime = _startTime;
        newEvent.endTime = _endTime;
        newEvent.creationTimestamp = block.timestamp;
        newEvent.nftRequired = _nftRequired;  // Set the NFT collection required for registration
        newEvent.maxParticipants = _maxParticipants;

        return totalEventsCreated;
    }

    // Register for an event
    function registerForEvent(uint256 eventId) external {
        OrganizedEvent storage orgEvent = eventRegistry[eventId];
        require(orgEvent.eventId > 0, "Invalid event");
        require(!userRegistrations[msg.sender][eventId], "Already registered");
        require(orgEvent.participants.length < orgEvent.maxParticipants, "Max participants reached");
        require(!orgEvent.isRegistrationClosed, "Registration closed");
        require(!orgEvent.isEventCancelled, "Event cancelled");

        // Ensure the participant holds the required NFT
        require(IERC721(orgEvent.nftRequired).balanceOf(msg.sender) > 0, "Must hold required NFT to register");

        // Add participant to the event
        orgEvent.participants.push(msg.sender);
        userRegistrations[msg.sender][eventId] = true;
    }

    // Check-in to the event (only event organizer can check in participants)
    function checkInParticipant(uint256 eventId, address participant) external {
        OrganizedEvent storage orgEvent = eventRegistry[eventId];
        require(msg.sender == orgEvent.organizer, "Only organizer can check in");
        require(userRegistrations[participant][eventId], "User not registered");

        orgEvent.attendanceRecord[participant] = true;
    }

    // Get all participants for an event
    function getEventParticipants(uint256 eventId) external view returns (address[] memory) {
        return eventRegistry[eventId].participants;
    }

    // Check if a participant attended the event
    function isUserAttended(uint256 eventId, address participant) external view returns (bool) {
        return eventRegistry[eventId].attendanceRecord[participant];
    }
}
