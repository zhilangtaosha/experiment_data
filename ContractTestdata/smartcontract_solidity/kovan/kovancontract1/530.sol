/**
 *Submitted for verification at Etherscan.io on 2019-01-20
*/

pragma solidity ^0.5.0;



contract testmap {

    mapping(address => address) public i;
     mapping(address => bool) public ii;
    constructor() public {
        i[msg.sender] = 0x7218522a731eC98311f1702C23BCa45EC21152cB;
       ii[msg.sender] = true;
}



    function mm() public payable{
        ii[msg.sender] = false;
    
    }

}
