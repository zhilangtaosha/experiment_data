/**
 *Submitted for verification at Etherscan.io on 2019-08-06
*/

pragma solidity ^0.4.25;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract ERC20Basic {
    uint256 public totalSupply;

    bool public transfersEnabled;

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 {
    uint256 public totalSupply;

    bool public transfersEnabled;

    function balanceOf(address _owner) public constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    /**
    * @dev protection against short address attack
    */
    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    }


    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public onlyPayloadSize(2) returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(transfersEnabled);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

}

contract StandardToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) internal allowed;

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3) returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(transfersEnabled);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public onlyPayloadSize(2) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract UbOOOToken is StandardToken {
    string public constant name = "UbOOOToken";
    string public constant symbol = "UBOOO";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 2 * 100000000 * (10**uint256(decimals));
	
	uint256 public priceWei = (10**uint256(decimals)) * 1 / 20000;

    address public owner;
    bool public saleToken = true;

    event OwnerChanged(address indexed previousOwner, address indexed newOwner);
    event BuyTokens(address indexed beneficiary, uint256 value, uint256 amount);
 	//event Burn(address indexed _from, uint256 value);  

    constructor() public {
        totalSupply = INITIAL_SUPPLY;
        owner = msg.sender; 
        balances[owner] = INITIAL_SUPPLY;
        transfersEnabled = true;
    }

    function() payable public {
       buyTokens();
    }

    function buyTokens() public payable returns (uint256){
        require(msg.sender != address(0));
        require(saleToken);
		
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.div(priceWei).mul(10**uint256(decimals));
		
        if (tokens == 0) {revert();}
        _buy(msg.sender, tokens, owner);
        emit BuyTokens(msg.sender, weiAmount, tokens);
		
		// transfer ETH to owner
        owner.transfer(weiAmount);
        return tokens;
    }


    function _buy(address _to, uint256 _amount, address _owner) internal returns (bool) {
        require(_to != address(0));
        require(_amount <= balances[_owner]);
		
		balances[_owner] = balances[_owner].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        
        emit Transfer(_owner, _to, _amount);
        return true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
	
	function setPrice(uint256 newPriceWei) public onlyOwner{
        priceWei = newPriceWei;
    }
	
	function getPrice() public constant returns (uint256){
        return priceWei;
    }
	
	function mintToken(address target, uint256 mintedAmount) public onlyOwner{
		require(transfersEnabled);
        totalSupply = totalSupply.add(mintedAmount);
        emit Transfer(0, owner, mintedAmount);
		
		balances[target] = balances[target].add(mintedAmount);
        emit Transfer(owner, target, mintedAmount);
    }
	
	function burn(uint256 _value) public returns (bool) {
		// Check if the sender has enough
        require(balances[msg.sender] >= _value);  
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
		emit Transfer(msg.sender, 0, _value);
        //emit Burn(msg.sender, _value);
        return true;
    }
	
 
    function changeOwner(address _newOwner) public onlyOwner returns (bool){
        require(_newOwner != address(0));
        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
        return true;
    }

    function startSale() public onlyOwner {
        saleToken = true;
    }

    function stopSale() public onlyOwner {
        saleToken = false;
    }

    function enableTransfers(bool _transfersEnabled) public onlyOwner{
        transfersEnabled = _transfersEnabled;
    }
}
