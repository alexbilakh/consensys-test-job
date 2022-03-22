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

    struct UserData {
        address userAddress;
        uint32 bookedAt;
    }

    UserData[] public users;

    // saves room number of user (real room number = value + 1)
    mapping(address => uint8) private userRoom;

    // rooms data with user-count and company type
    RoomData[ROOM_COUNT] private rooms;

    event BookedRoom(uint8 room, address booker, Company company);
    event CanceledReservation(uint8 room, address booker, Company company);

    modifier onlyBookedUser(address _addr) {
        if (
            userRoom[_addr] < uint8(0x0)
            || userRoom[_addr] >= ROOM_COUNT
        ) {
            revert("Not booked yet");
        }
        _;
    }

    modifier onlyLimitedRooms(uint8 _roomNumber) {
        if (
            _roomNumber >= ROOM_COUNT
            || _roomNumber < 0
        ) {
            revert("Room is not exist");
        }
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
        returns (UserData[] memory roomUsers, uint8 userCount, Company company)
    {
        UserData[] memory _roomUsers = new UserData[](
            rooms[_roomNumber].userCount
        );

        uint8 _roomUserCount = 0;
        for (uint256 i = 0; i < users.length; i++) {
            if ((userRoom[users[i].userAddress] - 1) == _roomNumber) {
                _roomUsers[_roomUserCount] = users[i];
                _roomUserCount++;
            }
        }

        return (_roomUsers, rooms[_roomNumber].userCount, rooms[_roomNumber].company);
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
        if (
            userRoom[msg.sender] != uint8(0x0)
            && userRoom[msg.sender] != 100
        ) {
            revert("Already booked a room");
        }

        rooms[_roomNumber].userCount++;
        rooms[_roomNumber].company = company;
        userRoom[msg.sender] = _roomNumber + 1;
        users.push(UserData({
            userAddress: msg.sender,
            bookedAt: uint32(block.timestamp)
        }));

        emit BookedRoom(_roomNumber, msg.sender, company);
    }

    // cancel reservation
    function cancelReservation() public onlyBookedUser(msg.sender) {
        RoomData storage targetRoom = rooms[userRoom[msg.sender] - 1];
        targetRoom.userCount--;
        
        // mark as deleted in userRoom
        userRoom[msg.sender] = 100;

        // remove from users list
        uint8 _userIndex;
        for (uint8 i = 0; i < users.length; i++) {
            if (users[i].userAddress == msg.sender) {
                _userIndex = i;
                break;
            }
        }
        users[_userIndex] = users[users.length - 1];
        users.pop();

        emit CanceledReservation(userRoom[msg.sender] - 1, msg.sender, targetRoom.company);
    }
}
