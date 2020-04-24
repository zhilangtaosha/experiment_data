/**
 *Submitted for verification at Etherscan.io on 2018-12-28
*/

pragma solidity ^0.5.1;

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
}

contract Owner {

	/// @dev `owner` is the only address that can call a function with this
	/// modifier
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	address public owner;

	/// @notice The Constructor assigns the message sender to be `owner`
	constructor() public {
		owner = msg.sender;
	}

	address public newOwner;

	/// @notice `owner` can step down and assign some other address to this role
	/// @param _newOwner The address of the new owner. 0x0 can be used to create
	///  an unowned neutral vault, however that cannot be undone
	function changeOwner(address _newOwner) public onlyOwner {
		newOwner = _newOwner;
	}


	function acceptOwnership() public {
		if (msg.sender == newOwner) {
			owner = newOwner;
		}
	}

}
contract FutureGame is Owner {

    using SafeMath for uint256;

    event Invest(address indexed _from, uint256 _value, bool _direction);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event StandardPrice(uint256 _price, uint256 _timestamp);
    event ResetTimer(uint256 lockTime, uint256 settlementTime, bool status);
    
    // Balances for each account
    mapping(address => uint256) public longBalances;
    mapping(address => uint256) public shortBalances;
    mapping(address => uint256) public balances;
    
    mapping(address => uint256) public totalIncome;
    mapping(address => uint256) public lastIncome;
    
    address[] public longInvestor;
    address[] public shortInvestor;
    mapping(address => uint256) public longInvestorIndex;
    mapping(address => uint256) public shortInvestorIndex;

    bool public status = true;   
    uint public investInterval = 1 minutes;  //invest time
    uint public lockInterval = 1 minutes;     //lock time can't invest      
    mapping(uint256 => uint256) public lockTime;
    mapping(uint256 => uint256) public settlementTime;
    string public name;
    uint256 public constant decimals = 18;
    
    mapping(uint256 => uint256) public standardPrice;
    mapping(uint256 => uint256) public settlementPrice;
    uint256 public unitIncome;
    mapping(uint256 => uint256) public longPool;
    mapping(uint256 => uint256) public shortPool;
    uint256 public round = 1;
    mapping(address => bool) public whiteList;
    // need set Owner
    // Owner of account approves the transfer of an amount to another account
    
    modifier onlyWhiteList() {
        require(whiteList[msg.sender]);
        _;
    }

    constructor(uint256 _timestamp) public {
        name = "test";
        whiteList[msg.sender] = true;
        lockTime[round] = _timestamp.add(investInterval);
        settlementTime[round] = lockTime[round].add(lockInterval);
    }
 
    function invest(bool _direction) payable public {
        require(status);
        require(now < lockTime[round]);
        require(msg.value > 0);
        if (_direction) {
            longBalances[msg.sender] = longBalances[msg.sender].add(msg.value);
            longPool[round] = longPool[round].add(msg.value);
            
            if (longInvestorIndex[msg.sender] == 0) {
                longInvestorIndex[msg.sender] = longInvestor.push(msg.sender);
            }

        } else {
            shortBalances[msg.sender] = longBalances[msg.sender].add(msg.value);
            shortPool[round] = shortPool[round].add(msg.value);
            
            if (shortInvestorIndex[msg.sender] == 0) {
                shortInvestorIndex[msg.sender] = shortInvestor.push(msg.sender);
            }
        }
        emit Invest(msg.sender, msg.value, _direction);
    }
    
    function updateTimer() public onlyWhiteList {
        status = true;
        lockTime[round] = now.add(investInterval);
        settlementTime[round] = lockTime[round].add(lockInterval);
        emit ResetTimer(lockTime[round], settlementTime[round], status);
    }
    
    function updateIncome(uint _unitIncome, bool _direction) internal {
        //TODO check the long number and short number
        if (_unitIncome > 0) {
            if (_direction) {
                for (uint i = 0; i < longInvestor.length; i++) {
                    address hold = longInvestor[i];
                    lastIncome[hold] = _unitIncome.mul(longBalances[hold]).div(10**decimals);
                    totalIncome[hold] = totalIncome[hold].add(lastIncome[hold]);
                    balances[hold] = balances[hold].add(longBalances[hold]);
                    longBalances[hold] = 0;
                }
                for (uint i = 0; i < shortInvestor.length; i++) {
                    address hold = shortInvestor[i];
                    lastIncome[hold] = 0;
                    shortBalances[hold] = 0;
                }
            } else {
                for (uint i = 0; i < shortInvestor.length; i++) {
                    address hold = shortInvestor[i];
                    lastIncome[hold] = _unitIncome.mul(shortBalances[hold]).div(10**decimals);
                    totalIncome[hold] = totalIncome[hold].add(lastIncome[hold]);
                    balances[hold] = balances[hold].add(shortBalances[hold]);
                    shortBalances[hold] = 0;
                }
                for (uint i = 0; i < longInvestor.length; i++) {
                    address hold = longInvestor[i];
                    lastIncome[hold] = 0;
                    longBalances[hold] = 0;
                }
            }
        } else {
                for (uint i = 0; i < shortInvestor.length; i++) {
                    address hold = shortInvestor[i];
                    balances[hold] = balances[hold].add(shortBalances[hold]);
                    lastIncome[hold] = 0;
                    shortBalances[hold] = 0;
                }
                for (uint i = 0; i < longInvestor.length; i++) {
                    address hold = longInvestor[i];
                    balances[hold] = balances[hold].add(longBalances[hold]);
                    lastIncome[hold] = 0;
                    longBalances[hold] = 0;
                }
        }

    }
    function getUnitIncome(bool _direction) internal view returns (uint) {
        if (_direction) {
            if (longPool[round] == 0)
                return 0;
            else 
                return shortPool[round].mul(10**decimals).div(longPool[round]);
        } else {
            if (longPool[round] == 0)
                return 0;
            else
                return longPool[round].mul(10**decimals).div(shortPool[round]);
        }
    }
    
    function setStandardPrice(uint _standardPrice, uint _timestamp) public onlyWhiteList {
        require(_timestamp >= lockTime[round]);
        standardPrice[round] = _standardPrice;
        status = false;
        emit StandardPrice(_standardPrice, _timestamp);
    }
    
    function setSettlementPrice(uint _settlementPrice, uint _timestamp) public onlyWhiteList {
        require(_timestamp >= settlementTime[round]);
        settlementPrice[round] = _settlementPrice;
            if (settlementPrice[round] > standardPrice[round]) {
                unitIncome = getUnitIncome(true);
                updateIncome(unitIncome, true);
            } else if(settlementPrice[round] < standardPrice[round]) {
                unitIncome = getUnitIncome(false);
                updateIncome(unitIncome, false);
            } else {
                unitIncome = 0;
                updateIncome(unitIncome, true);
            }
        round++;
        updateTimer();
    }
    
    function setWhiteList(address _addr) public onlyOwner {
        whiteList[_addr] = true;
    }
    function delWhiteList(address _addr) public onlyOwner {
        whiteList[_addr] = false;
    }
    
    function balanceOf(address _investor) public view returns (uint, uint, uint) {
        return (longBalances[_investor], shortBalances[_investor], balances[_investor]);
    }
    
    function income(address _investor) public view returns (uint, uint) {
        return (lastIncome[_investor], totalIncome[_investor]);
    }
    
    function withdraw() public {
        uint totalMoney = totalIncome[msg.sender].add(balances[msg.sender]);
        require(totalMoney > 0);
        msg.sender.transfer(totalMoney);
        totalIncome[msg.sender] = 0;
        balances[msg.sender] = 0;
    }
    
    function kill() public onlyOwner {
        selfdestruct(0x3807dd654C0ecB35b39758c8eCE66437929548Db);
    }
    
}
