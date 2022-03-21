// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract RoomBooking {
    uint8 constant ROOM_COUNT = 20;

    enum Company {
        COKE,
        PEPSI
    }

    struct RoomData {
        uint8 userCount;
        Company company;
    }

    address[] public users;

    // saves room number of user (real room number = value + 1)
    mapping(address => uint8) private userRoom;

    // rooms data with user-count and company type
    RoomData[ROOM_COUNT] public rooms;

    event BookedRoom(uint8 room, address booker, Company company);
    event CanceledReservation(uint8 room, address booker, Company company);

    modifier onlyBookedUser(address _addr) {
        require(userRoom[_addr] >= uint8(0x0), "Not booked yet");
        _;
    }

    modifier onlyLimitedRooms(uint8 _roomNumber) {
        require(_roomNumber < ROOM_COUNT, "Room is not exist");
        _;
    }

    // get room number of an user
    function getUserRoom(address _addr)
        public
        view
        onlyBookedUser(_addr)
        returns (uint8)
    {
        return userRoom[_addr] - 1;
    }

    // get users list of specific room
    function getRoomUsers(uint8 _roomNumber)
        public
        view
        onlyLimitedRooms(_roomNumber)
        returns (address[] memory)
    {
        address[] memory roomUsers = new address[](
            rooms[_roomNumber].userCount
        );

        uint8 roomUserCount = 0;
        for (uint256 i = 0; i < users.length; i++) {
            if ((userRoom[users[i]] - 1) == _roomNumber) {
                roomUsers[roomUserCount] = users[i];
                roomUserCount++;
            }
        }

        return roomUsers;
    }

    // book a room by room number and comapny
    function bookRoom(uint8 _roomNumber, Company company)
        public
        onlyLimitedRooms(_roomNumber)
    {
        if (
            rooms[_roomNumber].company != company &&
            rooms[_roomNumber].userCount > 0
        ) {
            revert("Another company owned the room");
        }
        require(userRoom[msg.sender] == uint8(0x0), "Already booked a room");

        rooms[_roomNumber].userCount++;
        rooms[_roomNumber].company = company;
        userRoom[msg.sender] = _roomNumber + 1;
        users.push(msg.sender);

        emit BookedRoom(_roomNumber, msg.sender, company);
    }

    // cancel reservation
    function cancelReservation() public onlyBookedUser(msg.sender) {
        RoomData storage targetRoom = rooms[userRoom[msg.sender] - 1];
        targetRoom.userCount--;

        emit CanceledReservation(userRoom[msg.sender] - 1, msg.sender, targetRoom.company);

        if (targetRoom.userCount == 0) {
            delete targetRoom.company;
        }
        delete userRoom[msg.sender];
    }
}
