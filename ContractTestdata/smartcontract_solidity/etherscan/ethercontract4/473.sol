/**
 *Submitted for verification at Etherscan.io on 2019-11-30
*/

/**
 *Submitted for verification at Etherscan.io on 2019-09-09
 * BEB dapp for www.betbeb.com
*/
pragma solidity^0.4.24;  
interface tokenTransfer {
    function transfer(address receiver, uint amount);
    function transferFrom(address _from, address _to, uint256 _value);
    function balanceOf(address receiver) returns(uint256);
}

contract Ownable {
  address public owner;
 
    function Ownable () public {
        owner = msg.sender;
    }
 
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
 
    /**
     * @param  newOwner address
     */
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }
}

contract LUCKen is Ownable{
    address[] public bebdsds;
    uint256 _min;
    uint256 _max;
tokenTransfer public bebTokenTransfer; //代币 
    function LUCKen(address _tokenAddress){
         bebTokenTransfer = tokenTransfer(_tokenAddress);
     }
     function present(address[] nanee,uint256 _hsgsg)onlyOwner{
      bebdsds=nanee;
      //bebTokenTransfer.transfer(msg.sender,888*10**18);

     }
     function minmax(uint256 _hsgsg,uint256 werdd)onlyOwner{
      _min=_hsgsg;
      _max=werdd;
      //bebTokenTransfer.transfer(msg.sender,888*10**18);

     }
     function presentaddress(address _tokenAddress)onlyOwner{
      bebTokenTransfer=tokenTransfer(_tokenAddress);
      //bebTokenTransfer.transfer(msg.sender,888*10**18);
     }
     function presentto()public{
      for(uint i=_min;i<bebdsds.length;i++){
       bebTokenTransfer.transfer(bebdsds[i],88888*10**18);
        }
      //bebTokenTransfer.transfer(msg.sender,888*10**18);

     }
     function getSumAmount() public view returns(uint256){
        return bebdsds.length;
    }
    function ()payable{
    }
}
