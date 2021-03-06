/**
 *Submitted for verification at Etherscan.io on 2019-08-05
*/

pragma solidity ^0.5.0;

/**
 * @title - Special Flag
 * ███████╗██╗      █████╗  ██████╗  ██████╗ ██╗███╗   ██╗ ██████╗
 * ██╔════╝██║     ██╔══██╗██╔════╝ ██╔════╝ ██║████╗  ██║██╔════╝
 * █████╗  ██║     ███████║██║  ███╗██║  ███╗██║██╔██╗ ██║██║  ███╗
 * ██╔══╝  ██║     ██╔══██║██║   ██║██║   ██║██║██║╚██╗██║██║   ██║
 * ██║     ███████╗██║  ██║╚██████╔╝╚██████╔╝██║██║ ╚████║╚██████╔╝
 * ╚═╝     ╚══════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝
 * ---
 *
 * POWERED BY
 *  __    ___   _     ___  _____  ___     _     ___
 * / /`  | |_) \ \_/ | |_)  | |  / / \   | |\ |  ) )
 * \_\_, |_| \  |_|  |_|    |_|  \_\_/   |_| \| _)_)
 *
 * Game at https://skullys.co/
 **/

interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract ERC721 is IERC165 {

    // IERC721
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;

    // IERC721Metadata
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) public view returns (string memory);

    // IERC721Enumerable
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
    
    function getSkully(uint256 _skullyId)
    external
    view
    returns (
        uint256 attack,
        uint256 defend,
        uint256 birthTime,
        string memory category,
        string memory URI,
        uint256 totalTradingTime
    );
}

contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public;
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract GameRole {
    using Roles for Roles.Role;

    event GameControllerAdded(address indexed account);
    event GameControllerRemoved(address indexed account);

    Roles.Role private _games;

    constructor () internal {
        _addGameController(msg.sender); // the controller of Game Contract address
    }

    modifier onlyGameController() {
        require(isGameController(msg.sender), "GameRole: caller does not have the Game role");
        _;
    }

    function isGameController(address account) public view returns (bool) {
        return _games.has(account);
    }

    function addGameController(address account) public onlyGameController {
        _addGameController(account);
    }

    function renounceGameController(address account) public onlyGameController {
        _removeGameController(account);
    }

    function _addGameController(address account) internal {
        _games.add(account);
        emit GameControllerAdded(account);
    }

    function _removeGameController(address account) internal {
        _games.remove(account);
        emit GameControllerRemoved(account);
    }
}

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is PauserRole {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

contract SpecialFlaggingAccessControl is Pausable {
     /// @dev The ERC-165 interface signature for ERC-721.
    ///  Ref: https://github.com/ethereum/EIPs/issues/165
    ///  Ref: https://github.com/ethereum/EIPs/issues/721
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x80ac58cd);
    ERC721 public nonFungibleContract;
    
    ERC20 po8Token;
    
    constructor(address _nftAddress, address po8Address) public {
        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721), "The candidate contract must supports ERC721");
        nonFungibleContract = candidateContract;
        
        ERC20 po8 = ERC20(po8Address);
        po8Token = po8;
    }
}

contract SpecialFlagging is SpecialFlaggingAccessControl, GameRole {
    /// Nearest day the skull have geo flagging action
    mapping (uint256 => uint256) internal nearestDateFlagging;
    
    ///uint256 fee;
    
    uint256 exchangeRate;
    
    uint256 rate; // 86400s = 8.64 po8 - 1s = 0.00001 po8
    
    /// Special Location structure
    struct SpecialLocation {
        uint256 locationId;
        uint256 lat;
        uint256 long;
        uint256 creater;
        uint256 createdTime;
        uint256 owner;
        uint256 takenTime;
        uint256 price; // wei ETH
        uint256 radius; // meter
    }
    
    SpecialLocation[] allSpecialLocations;
    
    mapping(uint256 => uint256) totalSpLsOfSkully;
    
    event SpecialLocationCreated(uint256 locationId, uint256 latitude, uint256 longitude, uint256 creater, uint256 timeCreated, uint256 price, uint256 radius);
    event SpecialLocationAttackSussess(uint256 locationId, uint256 attacker, uint256 timeAttacked);
    event SpecialLocationAttackFail(uint256 locationId, uint256 attacker, uint256 timeAttacked);
    event PO8ClaimedByLocation(uint256 locationId, uint256 skullyId, address indexed whoClaimed, uint256 totalClaimed, address indexed caller);
    event AllPO8ClaimedBySkully(uint256 skullyId, address indexed whoClaimed, uint256[] locationsId, uint256 totalClaimed);
    event PO8ClaimedBySkullyWithSomeLocations(uint256 skullyId, address indexed whoClaimed, uint256[] locationsId, uint256 totalClaimed);
    event AllPO8Claimed(address indexed caller, address indexed whoClaimed, uint256[] skullysId, uint256 totalClaimed);
    event NewPriceUpdated(uint256 locationId, uint256 newPrice);
    event ExchangeRateUpdated(uint256 _newExchangeRate);
    
    constructor(address _nftAddress, address po8Address) public SpecialFlaggingAccessControl(_nftAddress, po8Address) {
        allSpecialLocations.push(
            SpecialLocation(
                {locationId: 0,
                lat: 0,
                long: 0,
                creater: 0,
                createdTime: now,
                owner: 0,
                takenTime: 0,
                price: 0,
                radius: 0
                }));
        rate = 1e13;
        exchangeRate = 23000; // base-on ETH price
    }
    
    /* */
    function setPO8TokenContractAdress(address po8Address) external onlyGameController returns (bool) {
        ERC20 po8 = ERC20(po8Address);
        po8Token = po8;
        return true;
    }
    
    /// @dev The Owner can set the new exchange rate between ETH and PO8 token.
    function setExchangeRate(uint256 _newExchangeRate) external onlyGameController returns (uint256) {
        exchangeRate = _newExchangeRate;

        emit ExchangeRateUpdated(_newExchangeRate);

        return _newExchangeRate;
    }

    /* */
    function createSpecialLocation(uint256 skullyId, uint256 lat, uint256 long, uint256 price, uint256 radius) public onlyGameController {
        uint256 locationId = allSpecialLocations.length;
        allSpecialLocations.push(
            SpecialLocation(
                {locationId: locationId,
                lat: lat,
                long: long,
                creater: skullyId,
                createdTime: now,
                owner: skullyId,
                takenTime: now,
                price: price,
                radius: radius
                }));
        emit SpecialLocationCreated(locationId, lat, long, skullyId, now, price, radius);
    }
    
    /* */
    function getSpecialLocationInformation(uint256 locationId) public view returns (
        uint256 _locationId, 
        uint256 latitude, 
        uint256 longitude, 
        uint256 creater, 
        uint256 createdTime, 
        uint256 owner, 
        uint256 takenTime,
        uint256 price,
        uint256 radius) {
        SpecialLocation storage sl = allSpecialLocations[locationId];
        return (
            sl.locationId,
            sl.lat,
            sl.long,
            sl.creater,
            sl.createdTime,
            sl.owner,
            sl.takenTime,
            sl.price,
            sl.radius);
    }
    
    /* */
    function pinNewSpecialLocationByPO8(uint256 skullyId, uint256 lat, uint256 long, uint256 price, uint256 radius) external whenNotPaused {
        //require(now - nearestDateFlagging[skullyId] >= 86400);
        uint256 fee = price * exchangeRate; // price in wei ETH
        require(po8Token.balanceOf(msg.sender) >= fee); // must approved before do this action
        
        po8Token.transferFrom(msg.sender, address(this), fee);
        
        uint256 locationId = allSpecialLocations.length;
        
        allSpecialLocations.push(SpecialLocation(
            {locationId: locationId,
            lat: lat, long: long,
            creater: skullyId,
            createdTime: now,
            owner: skullyId,
            takenTime: now,
            price: price,
            radius: radius
            }));
        
        totalSpLsOfSkully[skullyId]++;
        
        emit SpecialLocationCreated(locationId, lat, long, skullyId, now, price, radius);
    }
    
    /* */
    function pinNewSpecialLocationByETH(uint256 skullyId, uint256 lat, uint256 long, uint256 price, uint256 radius) external payable whenNotPaused {
        require(price == msg.value);
        
        uint256 locationId = allSpecialLocations.length;
        
        allSpecialLocations.push(SpecialLocation(
            {locationId: locationId,
            lat: lat, long: long,
            creater: skullyId,
            createdTime: now,
            owner: skullyId,
            takenTime: now,
            price: price,
            radius: radius
            }));
        
        totalSpLsOfSkully[skullyId]++;
        
        emit SpecialLocationCreated(locationId, lat, long, skullyId, now, price, radius);
    }
    
    /* */
    function setLocationPrice(uint256 locationId, uint256 newPrice) public onlyGameController returns (uint256) {
        allSpecialLocations[locationId].price = newPrice;
    }
    
    /* */
    function setLocationRadius(uint256 locationId, uint256 newRadius) public onlyGameController returns (uint256) {
        allSpecialLocations[locationId].radius = newRadius;
    }
    
    /* */
    function setLocationLatLong(uint256 locationId, uint256 newLat, uint256 newLong) public onlyGameController returns (uint256) {
        allSpecialLocations[locationId].lat = newLat;
        allSpecialLocations[locationId].long = newLong;
    }
    
    /* */
    function _successAttack(uint256 locationId, uint256 attacker) external onlyGameController {
        allSpecialLocations[locationId].owner = attacker;
        allSpecialLocations[locationId].takenTime = now;
    }
    
    /* */
    function claimPO8ByLocationId(uint256 locationId) public whenNotPaused {
        uint256 locationOwner = allSpecialLocations[locationId].owner; //skullyId
        
        po8Token.transfer(nonFungibleContract.ownerOf(locationOwner), (now - allSpecialLocations[locationId].takenTime) * rate);
        
        allSpecialLocations[locationId].takenTime = now;
        
        emit PO8ClaimedByLocation(
            locationId, 
            locationOwner, 
            nonFungibleContract.ownerOf(locationOwner), 
            (now - allSpecialLocations[locationId].takenTime) * rate, 
            msg.sender);
    }
    
    /* */
    function claimPO8BySkullyWithLocations(uint256 skullyId, uint256[] memory locationsId) public whenNotPaused {
        uint256 locationOwner = allSpecialLocations[locationsId[0]].owner;
        uint256 totalPO8;
        for(uint256 i = 0; i < locationsId.length; i++) {
            assert(locationOwner == allSpecialLocations[locationsId[i]].owner); //skullyId
        
            totalPO8 += (now - allSpecialLocations[locationsId[i]].takenTime) * rate;
        
            allSpecialLocations[locationsId[i]].takenTime = now;
        }
        po8Token.transfer(nonFungibleContract.ownerOf(locationOwner), totalPO8);
        emit PO8ClaimedBySkullyWithSomeLocations(skullyId, msg.sender, locationsId, totalPO8);
    }
    
    /* */
    function claimAllPO8BySkully(uint256 skullyId) public whenNotPaused {
        uint256[] memory allLocationsId = getAllLocationsIdOfSkully(skullyId);
        uint256 locationOwner = allSpecialLocations[allLocationsId[0]].owner;
        uint256 totalPO8;
        
        for(uint256 i = 0; i < allLocationsId.length; i++) {
            assert(locationOwner == allSpecialLocations[allLocationsId[i]].owner); //skullyId
        
            totalPO8 += (now - allSpecialLocations[allLocationsId[i]].takenTime) * rate;
            
            allSpecialLocations[allLocationsId[i]].takenTime = now;
        }
        po8Token.transfer(nonFungibleContract.ownerOf(locationOwner), totalPO8);
        emit AllPO8ClaimedBySkully(skullyId, msg.sender, allLocationsId, totalPO8);
    }
    
    /* @dev User can claim all PO8 belong to Special Flags of all skully they have by put the skully into array and make a transaction  
     * @param skullysId Array skully, which was choosen to claim PO8 with their Special Flags
     */
    function claimAllPO8(uint256[] memory skullysId) public whenNotPaused {
        address caller = nonFungibleContract.ownerOf(skullysId[0]);
        uint256 totalPO8;
        uint256[] memory allLocationsId;
        uint256 locationOwner;
        
        for(uint256 i = 0; i < skullysId.length; i++) {
            assert(caller == nonFungibleContract.ownerOf(skullysId[i]));
            
            allLocationsId = getAllLocationsIdOfSkully(skullysId[i]);
            locationOwner = allSpecialLocations[allLocationsId[0]].owner;
            for(uint256 j = 0; j < allLocationsId.length; j++) {
                assert(locationOwner == allSpecialLocations[allLocationsId[j]].owner); //skullyId
            
                totalPO8 += (now - allSpecialLocations[allLocationsId[j]].takenTime) * rate;
                
                allSpecialLocations[allLocationsId[j]].takenTime = now;
            }
        }
        po8Token.transfer(caller, totalPO8);
        emit AllPO8Claimed(caller, msg.sender, skullysId, totalPO8);
    }
    
    /* */
    function getAllLocationsIdOfSkully(uint256 skullyId) public view returns (uint256[] memory) {
        uint256[] memory allLocationsId = new uint256[](totalSpLsOfSkully[skullyId]);
        uint256 count;
        for(uint256 i = 1; i < allSpecialLocations.length; i++) {
            if(allSpecialLocations[i].owner == skullyId) {
                allLocationsId[count] = i;
                count++;
            }
        }
        return allLocationsId;
    }
    
    /* */
    function getBackERC20Token(address tokenAddress) external onlyGameController {
        ERC20 token = ERC20(tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
    
    /* */
    function withdrawBalance(uint256 amount) external onlyGameController {
        msg.sender.transfer(amount);
    }
}
