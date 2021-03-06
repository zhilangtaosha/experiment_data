/**
 *Submitted for verification at Etherscan.io on 2019-01-20
*/

pragma solidity ^0.4.18;
contract Ownable {
  address public owner;
  address public owner2;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event OwnershipAdd(address indexed newOwner);

  /**
   * @dev Ownable constructor ตั้งค่าบัญชีของ sender ให้เป็น owner ดั้งเดิมของ contract 
   *
   */
   constructor() public {
    owner = msg.sender;
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

 // ถ้าคนที่เรียกใช้ไม่ใช่คนสร้าง smart contract จะหยุดทำงานและคืนค่า gas
  modifier onlyOwner(){
    require(msg.sender == owner || msg.sender == owner2);
    _;
  }
// ตรวจสอบว่า ไม่ใช่ contract address 

  function transferOwnership(address newOwner) public onlyOwner{
    require(isContract(newOwner) == false); // ตรวจสอบว่าไม่ได้เผลอเอา contract address มาใส่
    emit OwnershipTransferred(owner,newOwner);
    owner = newOwner;

  }
  function addOwnership(address newOwner) public onlyOwner{
    require(isContract(newOwner) == false); // ตรวจสอบว่าไม่ได้เผลอเอา contract address มาใส่
    emit OwnershipAdd(newOwner);
    owner2 = newOwner;
  }
}

contract AdisakConstract is Ownable {
    uint balance;
//    address public owner;
    
    constructor() public {
        balance = 1000;
        owner = msg.sender;
    }
    function setBalance(uint newBalance) public onlyOwner {
//        require(owner == msg.sender);
        balance = newBalance;
    }
    function getBalance() public view returns (uint) {
        return balance;
    }
    function setOwner(address _owner) public onlyOwner {
//        require(owner == msg.sender);
        owner = _owner;
    }
/*
    function setBalanceOwner1(uint newBalance) public {
        require(owner == msg.sender);
        balance = newBalance;
    }
    function setBalanceOwner2(uint newBalance) public returns (bool) {
        if(owner == msg.sender) {
            balance = newBalance;
            return true;
        }
        return false;
    }
    */
}
