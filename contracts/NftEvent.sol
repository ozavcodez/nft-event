// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract EventOrganizer {
    address nftCollectionAddress;
    uint256 public totalEventsCreated;

    constructor() {}

    struct AttendanceRecord {
        address attendee;
        uint256 checkInTimestamp;
    }

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
        address nftRequired;
        address[] participants;
        AttendanceRecord[] attendanceRecords;
    }

    mapping(uint256 => OrganizedEvent) public eventRegistry;
    mapping(address => mapping(uint256 => bool)) public userRegistrations;

    // Function to create a new event
    function organizeEvent(
        address _nftRequired,
        string memory _eventName,
        string memory _location,
        string memory _details,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _maxParticipants
    ) external returns (OrganizedEvent memory) {
        require(msg.sender != address(0), "InvalidAddress");
        require(_nftRequired != address(0), "InvalidNFTAddress");
        require(!_isEmpty(_eventName), "EventNameRequired");
        require(!_isEmpty(_location), "LocationRequired");
        require(!_isEmpty(_details), "DetailsRequired");
        require(_startTime < _endTime, "InvalidStartTime");
        require(_maxParticipants > 0, "MaxParticipantsRequired");

        uint eventId = totalEventsCreated + 1;
        OrganizedEvent storage newEvent = eventRegistry[eventId];
        newEvent.eventId = eventId;
        newEvent.eventName = _eventName;
        newEvent.location = _location;
        newEvent.details = _details;
        newEvent.organizer = msg.sender;
        newEvent.startTime = _startTime;
        newEvent.endTime = _endTime;
        newEvent.creationTimestamp = block.timestamp;
        newEvent.nftRequired = _nftRequired;
        newEvent.maxParticipants = _maxParticipants;

        totalEventsCreated = eventId; // Update the event counter
        return newEvent;
    }

    // Get all participants for an event
    function getEventParticipants(uint eventId) external view returns (address[] memory) {
        require(isEventOrganizer(eventId), "NotOrganizer");
        require(eventRegistry[eventId].eventId >= 1, "InvalidEventId");

        return eventRegistry[eventId].participants;
    }

    // Register a user for the event
    function registerForEvent(uint256 eventId) external {
        require(eventRegistry[eventId].eventId >= 1, "InvalidEventId");
        require(!userRegistrations[msg.sender][eventId], "AlreadyRegistered");
        require(!eventRegistry[eventId].isRegistrationClosed, "RegistrationClosed");
        require(!eventRegistry[eventId].isEventCancelled, "EventCancelled");

        address nftRequired = eventRegistry[eventId].nftRequired;
        require(hasRequiredNFT(nftRequired, msg.sender) >= 1, "NFTRequiredForEvent");

        eventRegistry[eventId].participants.push(msg.sender);
        userRegistrations[msg.sender][eventId] = true;
    }

    // Check-in for an event
    function checkInForEvent(uint eventId, address participant) external returns (AttendanceRecord memory) {
        require(isEventOrganizer(eventId), "NotOrganizer");
        require(eventRegistry[eventId].eventId >= 1, "InvalidEventId");
        require(userRegistrations[participant][eventId], "NotRegisteredForEvent");

        AttendanceRecord memory newRecord = AttendanceRecord({
            attendee: participant,
            checkInTimestamp: block.timestamp
        });

        eventRegistry[eventId].attendanceRecords.push(newRecord);
        return newRecord;
    }

    // Internal function to check for empty strings
    function _isEmpty(string memory str) internal pure returns (bool) {
        return bytes(str).length == 0;
    }

    // Check if the user owns the required NFT for event participation
    function hasRequiredNFT(address _nftCollection, address user) public view returns (uint) {
        return IERC721(_nftCollection).balanceOf(user);
    }

    // Check if the message sender is the event organizer
    function isEventOrganizer(uint256 eventId) internal view returns (bool) {
        return eventRegistry[eventId].organizer == msg.sender;
    }
}