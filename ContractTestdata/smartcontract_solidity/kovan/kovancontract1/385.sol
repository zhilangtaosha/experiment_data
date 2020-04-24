/**
 *Submitted for verification at Etherscan.io on 2019-02-01
*/

pragma solidity ^0.4.25;

contract Ownable {


  string [] ownerName;

  mapping (address=>bool) owners;
  mapping (address=>uint256) ownerToProfile;
  address owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event AddOwner(address newOwner,string name);
  event RemoveOwner(address owner);
  /**
   * @dev Ownable constructor ตั้งค่าบัญชีของ sender ให้เป็น `owner` ดั้งเดิมของ contract 
   *
   */
   constructor() public {
    owner = msg.sender;
    owners[msg.sender] = true;
    uint256 idx = ownerName.push("ICOINIZE CO.,Ltd.");
    ownerToProfile[msg.sender] = idx;

  }

  function isContract(address _addr) internal view returns(bool){
     uint256 length;
     assembly{
      length := extcodesize(_addr)
     }
     if(length > 0){
       return true;
    }
    else {
      return false;
    }

  }

 // For Single Owner
  modifier onlyOwner(){
    require(msg.sender == owner);
    _;
  }


  function transferOwnership(address newOwner,string newOwnerName) public onlyOwner{
    require(isContract(newOwner) == false); // Owner can be only wallet address can't use contract address
    uint256 idx;
    if(ownerToProfile[newOwner] == 0)
    {
    	idx = ownerName.push(newOwnerName);
    	ownerToProfile[newOwner] = idx;
    }


    emit OwnershipTransferred(owner,newOwner);
    owner = newOwner;

  }

  //For multiple Owner
  modifier onlyOwners(){
    require(owners[msg.sender] == true);
    _;
  }

  function addOwner(address newOwner,string newOwnerName) public onlyOwners{
    require(owners[newOwner] == false);
    require(newOwner != msg.sender);
    if(ownerToProfile[newOwner] == 0)
    {
    	uint256 idx = ownerName.push(newOwnerName);
    	ownerToProfile[newOwner] = idx;
    }
    owners[newOwner] = true;
    emit AddOwner(newOwner,newOwnerName);
  }

  function removeOwner(address _owner) public onlyOwners{
    require(_owner != msg.sender);  // can't remove your self
    owners[_owner] = false;
    emit RemoveOwner(_owner);
  }

  function isOwner(address _owner) public view returns(bool){
    return owners[_owner];
  }

  function getOwnerName(address ownerAddr) onlyOwners public view returns (string){
  	require(ownerToProfile[ownerAddr] > 0);
  	
  	return ownerName[ownerToProfile[ownerAddr] - 1];
  }
}

contract WhitelistAddr is Ownable{
  mapping (address=>uint256)  whitelists;

  event CreateWhitelist(address indexed _addr);


  function addAddress(address _addr,uint256 invesType) public onlyOwners returns(bool){
     require(whitelists[_addr] == 0);
     require(invesType > 0);

     whitelists[_addr] = invesType;
     return true;
  }

  function haveWhitelist(address _addr) public onlyOwners view returns(uint256){
    return whitelists[_addr];
  }


}
