/**
 *Submitted for verification at Etherscan.io on 2019-11-29
*/

pragma solidity ^0.5.0;

contract Mytest {
    uint256 data;
    address owner;
    
    constructor (uint256 initData) public {
        data = initData;
        owner = msg.sender;
    }
    
    function getData() public view returns(uint256 rData) {
        return data;
    }
}
