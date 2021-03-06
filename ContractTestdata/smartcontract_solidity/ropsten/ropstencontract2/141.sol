/**
 *Submitted for verification at Etherscan.io on 2019-08-10
*/

pragma solidity ^0.4.24;

contract PeterBebe {

    struct Pago{
        address user;
        uint256 value;
        uint256 date;
        string razon;
    }

    address public owner;
    address public sraRosa;
    address public luis;
    uint256 paymentBalance;
    uint256 public EntryPrice = 300000000000000000;
    string public razon;
    uint256 now2 = now + 3 minutes;
    uint256 percent;
    
    bool public stopped = false;
    mapping (address => Pago) public Pagos;
    address[] public pagos;

    constructor() public{
        owner = msg.sender;
        sraRosa = msg.sender;
        luis = msg.sender;
    }


    modifier onlyOwner{
        require(owner == msg.sender);
        _;
    }


    modifier onlysraRosa{
      require(now >= now2);
        require(sraRosa == msg.sender);
        _;
    }
    
    modifier onlyLuis{
        require(luis == msg.sender);
        _;
    }
    
     modifier balanceOff{
        require(address(this).balance > 0);
        _;
    }
    
    

    modifier isRunning {
        require(!stopped);
        _;
    }

    modifier validAddress {
        require(0x0 != msg.sender);
        _;
    }

    function stop() onlyOwner public {
        stopped = true;
    }


    function start() onlyOwner public {
        stopped = false;
    }

    function setSraRosa(address _SraRosa) onlyOwner isRunning public returns (bool success){
        sraRosa = _SraRosa;
        return true;
    }
    
    function setLuis(address _luis) onlyOwner isRunning public returns (bool success){
        luis = _luis;
        return true;
    }

    function setRetiro() onlysraRosa balanceOff isRunning public returns (bool success){
      	paymentBalance = address(this).balance;
        return true;
    }
    
    function aproveRetiro(int status) onlyLuis isRunning public returns (bool success){
        require(paymentBalance > 0);
        if(status == 1) {
            percent = (address(this).balance * 5 ) / 100;
            luis.transfer(percent);
            sraRosa.transfer(address(this).balance);
            paymentBalance = 0;
  	        emit RetiroEvent(luis, paymentBalance, now);
            return true;
        } else {
            paymentBalance = 0;
            return true;
        }
    }

    function Pay(string _razon) payable isRunning validAddress public {
        require(owner != msg.sender);
        uint256 value = msg.value;
        if( value >= EntryPrice ){
            Pagos[msg.sender].user = msg.sender;
            Pagos[msg.sender].value = value;
            Pagos[msg.sender].date = now;
            Pagos[msg.sender].razon = _razon;
            pagos.push(msg.sender);
            emit PagoEvent(msg.sender, value, now, razon);
        } else {
            revert();
        }
    }
  
    function getBalance() view public returns (uint256 balance){
        return address(this).balance;
    }
  
    event PagoEvent(address indexed _user, uint256 indexed _value, uint256 indexed _date, string _razon);
    event RetiroEvent(address indexed _user, uint256 indexed _value, uint256 indexed _date);
}
