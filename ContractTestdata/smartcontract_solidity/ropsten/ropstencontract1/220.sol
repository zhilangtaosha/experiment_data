/**
 *Submitted for verification at Etherscan.io on 2019-02-21
*/

pragma solidity ^0.4.23;

contract Maxidice {
    uint public minNumber = 1;
    uint public maxNumber = 6;
    uint public maxRoomPlayers = 6;

    struct Player {
        uint numberSelected;
        uint256 amountBet;
    }

    struct Room {
        string roomId;
        uint currentPlayers;
        uint256 totalAmountBetting;
        uint wonNumber;
        address[] players;
        address roomMaster;
        mapping (address => Player) playersInfo;
    }

    mapping (string => Room) rooms;
    string[] roomIds;

    function createRoom(string roomId) public returns(bool) {
        Room memory nRoom;
        nRoom.roomId = roomId;
        nRoom.totalAmountBetting = 0;
        nRoom.currentPlayers = 0;
        nRoom.roomMaster = msg.sender;
        nRoom.currentPlayers = 1;
        rooms[roomId] = nRoom;
        rooms[roomId].players.push(msg.sender);
        rooms[roomId].playersInfo[msg.sender].numberSelected = 0;
        rooms[roomId].playersInfo[msg.sender].amountBet = 0;
        roomIds.push(roomId);
        return true;
    }

    function getRooms() public view returns(string) {
        string memory rIds;
        if (roomIds.length < 1) {
            return rIds;
        }
        for (uint256 i = 0; i < roomIds.length; i++) {
            string memory roomId = roomIds[i];
            Room memory room = rooms[roomId];
            string memory roomLabel = string(abi.encodePacked(roomId, ":", uint2str(room.currentPlayers)));
            if (i > 0) {
                rIds = string(abi.encodePacked(rIds, ","));
            }
            rIds = string(abi.encodePacked(rIds, roomLabel));
        }
        return rIds;
    }

    function getRoomBasicInfo(string roomId) public view returns(string, uint, uint256) {
        if (checkRoomExists(roomId) == false) {
            return ("", 0, 0);
        }
        Room memory r = rooms[roomId];
        return (r.roomId, r.currentPlayers, r.totalAmountBetting);
    }

    function getRoomPlayers(string roomId) public view returns(string) {
        string memory result = "";
        if (checkRoomExists(roomId) == false) {
            return result;
        }
        for (uint i = 0; i < rooms[roomId].players.length; i++) {
            string memory playerStr = addressToString(rooms[roomId].players[i]);
            Player memory p = rooms[roomId].playersInfo[rooms[roomId].players[i]];
            playerStr = string(abi.encodePacked(playerStr, ":", uint2str(p.numberSelected)));
            if (i > 0) {
                result = string(abi.encodePacked(result, ","));
            }
            result = string(abi.encodePacked(result, playerStr));
        }
        return result;
    }

    function checkRoomExists(string roomId) public view returns(bool) {
        if (keccak256(rooms[roomId].roomId) == keccak256(roomId)) {
            return true;
        }
        return false;
    }
    
    function joinRoom(string roomId) public view returns(bool) {
        if (checkRoomExists(roomId) == false) {
            return false;
        }
        rooms[roomId].players.push(msg.sender);
        rooms[roomId].playersInfo[msg.sender].numberSelected = 0;
        rooms[roomId].playersInfo[msg.sender].amountBet = 0;
    }

    function bet(uint256 numberSelected, string roomId) public payable returns(bool){
        require(checkRoomExists(roomId), "room is not exist");
        require(numberSelected >=1 && numberSelected <= 6, "only select number from 1 to 6");
        rooms[roomId].playersInfo[msg.sender].amountBet = msg.value;
        rooms[roomId].playersInfo[msg.sender].numberSelected = numberSelected;
        rooms[roomId].currentPlayers += 1;
        rooms[roomId].totalAmountBetting += msg.value;
        rooms[roomId].players.push(msg.sender);
    }

    function startGame(string memory roomId) public {
        uint256 numberGenerated = block.number % 6 + 1;
        distributePrizes(roomId, numberGenerated);
    }

    function distributePrizes(string roomId, uint256 numberWinner) public {
        address[100] memory winners;
        Room storage room = rooms[roomId];
        uint256 totalBetWon = 0;
        uint count = 0;
        for (uint256 i = 0; i < room.players.length; i++) {
            address playerAddr = room.players[i];
            if (room.playersInfo[playerAddr].numberSelected == numberWinner) {
                winners[count] = playerAddr;
                totalBetWon += room.playersInfo[playerAddr].amountBet;
                count++;
            }
        }
        uint256 totalBetLose = ((room.totalAmountBetting - totalBetWon) * 98) / 100;
        for (uint256 j = 0; j < count; j++) {
            address wonAddr = winners[j];
            uint256 paybackAmount = room.playersInfo[wonAddr].amountBet;
            paybackAmount += (paybackAmount / totalBetWon) * totalBetLose;
            wonAddr.transfer(paybackAmount);
        }
    }
    
    function addressToString(address x) internal pure returns(string) {
        bytes memory b = new bytes(20);
        for (uint i = 0; i < 20; i++)
            b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
        return string(b);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}
