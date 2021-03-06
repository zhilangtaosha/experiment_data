/**
 *Submitted for verification at Etherscan.io on 2019-01-31
*/

pragma solidity ^0.5.0;

// File: contracts/parents/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: contracts/parents/PrivateAccessible.sol

//import "../token/SafeMath.sol";

contract PrivateAccessible is Ownable {
//    using SafeMath for uint256;

    // a list of system managers' addresses
    address[] public managers;
    mapping (address => bool) _isManager;

    event SystemManagerAdded(address indexed newManager);
    event SystemManagerChanged(address indexed previousManager, address newManager);
    event SystemManagerDeleted(address indexed deletedManager);


    /*
    struct FakeBlock {
        uint timestamp;
    }
    FakeBlock block;
    uint now;

    function setBlockTime(uint val) public {
        now = val;
        block.timestamp = val;
    }
    //*/
    modifier onlyManagers() {
        require(_isManager[msg.sender]);
        _;
    }

    function getNumManagers() public view returns (uint256) {
        return managers.length;
    }

    function isManager(address _manager) public view returns (bool) {
        return _isManager[_manager];
    }

    /**
    * Add new Manager to the list of system Managers
    *
    * @param _manager ethereum address of the Manager
    */
    function addManager(address _manager) public onlyOwner {
        require(!_isManager[_manager]);
        emit SystemManagerAdded(_manager);
        managers.push(_manager);
        _isManager[_manager] = true;
    }

    /**
    * Set the existing system manager's ethereum address
    *
    * @param i an index of existing system manager
    * @param _manager new ethereum address of the manager
    */
    function changeManager(uint16 i, address _manager) public onlyOwner {
        require(managers.length > i);
        emit SystemManagerChanged(managers[i], _manager);
        _isManager[managers[i]] = false;
        _isManager[_manager] = true;
        managers[i] = _manager;
    }

    /**
    * Delete the existing system manager's ethereum address from the list of system managers
    *
    * @param i an index of existing system manager
    */
    function deleteManager(uint16 i) public onlyManagers {
        require(managers[i] != address(0));
        emit SystemManagerDeleted(managers[i]);
        managers[i] = address(0);
        _isManager[managers[i]] = false;
    }
}

// File: contracts/token/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: contracts/parents/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is PrivateAccessible {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

// File: contracts/token/IERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: contracts/parents/TokenManager.sol

//import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";




contract TokenManager is Pausable {

    /**
    * @dev Details of each transfer
    * @param contract_ contract address of ER20 token to transfer
    * @param to_ receiving account
    * @param amount_ number of tokens to transfer to_ account
    * @param failed_ if transfer was successful or not
    */
    struct Transfer {
        address contract_;
        address to_;
        uint amount_;
        bool failed_;
    }

    /**
    * @dev a mapping from transaction ID's to the sender address
    * that initiates them. Owners can create several transactions
    */
    mapping(address => uint[]) public transactionIndexesToSender;


    /**
    * @dev a list of all transfers successful or unsuccessful
    */
    Transfer[] public transactions;

//    address public owner;

    /**
    * @dev list of all supported tokens for transfer
    * @param string token symbol
    * @param address contract address of token
    */
    mapping(bytes32 => address) public tokens;

    IERC20 public ERC20Interface;

    /**
    * @dev Event to notify if transfer successful or failed
    * after account approval verified
    */
    event TransferSuccessful(address indexed from_, address indexed to_, uint256 amount_);

    event TransferFailed(address indexed from_, address indexed to_, uint256 amount_);

    /**
    * @dev add address of token to list of supported tokens using
    * token symbol as identifier in mapping
    */
    function addNewToken(bytes32 symbol_, address address_) public onlyOwner returns (bool) {
        tokens[symbol_] = address_;

        return true;
    }

    /**
    * @dev remove address of token we no more support
    */
    function getToken(bytes32 symbol_) public view returns (address) {
        require(tokens[symbol_] != address(0x0));

        return tokens[symbol_];
    }

    /**
    * @dev remove address of token we no more support
    */
    function removeToken(bytes32 symbol_) public onlyOwner returns (bool) {
        require(tokens[symbol_] != address(0x0));

        delete(tokens[symbol_]);

        return true;
    }

    /**
    * @dev method that handles transfer of ERC20 tokens to other address
    * it assumes the calling address has approved this contract
    * as spender
    * @param symbol_ identifier mapping to a token contract address
    * @param to_ beneficiary address
    * @param amount_ numbers of token to transfer
    */
    function transferTokens(bytes32 symbol_, address to_, uint256 amount_) public whenNotPaused{
        require(tokens[symbol_] != address(0x0));
        require(amount_ > 0);

        address contract_ = tokens[symbol_];
        address from_ = msg.sender;

        ERC20Interface =  IERC20(contract_);

        uint256 transactionId = transactions.push(
            Transfer({
            contract_:  contract_,
            to_: to_,
            amount_: amount_,
            failed_: true
            })
        );

        transactionIndexesToSender[from_].push(transactionId - 1);

        if(amount_ > ERC20Interface.allowance(from_, address(this))) {
            emit TransferFailed(from_, to_, amount_);
            revert();
        }

        ERC20Interface.transferFrom(from_, to_, amount_);

        transactions[transactionId - 1].failed_ = false;

        emit TransferSuccessful(from_, to_, amount_);
    }

    /**
    * @dev allow contract to receive funds
    */
    function() external payable {}

    /**
    * @dev withdraw funds from this contract
    * @param beneficiary address to receive ether
    */
    function withdraw(address payable beneficiary) public payable onlyOwner whenNotPaused {
        beneficiary.transfer(address(this).balance);
    }
}

// File: contracts/SocuBank.sol

//import "./token/IERC20.sol";



contract SocuBank is TokenManager {
    using SafeMath for uint256;

    address etherAddress = 0x0000000000000000000000000000000000000000;

    struct Account {
        uint256 balance;
        address[] tokens;
        mapping(address => bool) tokensInUse;
    }

    mapping(address => Account) accounts;
    mapping (address => uint256) blockSizes;

    event Deposit(address indexed _owner, uint256 _amount, uint256 _time);
    event Withdrawal(address indexed _owner, uint256 _amount, uint256 _time);
//    event DepositTransfer(address indexed _token, address indexed _from, address indexed _to, uint256 _amount, uint256 _time);

    function setBlockSize(address _token, uint256 _size) public onlyOwner {
        blockSizes[_token] = _size;
    }

    function getBlockSize(address _token) public view returns (uint256) {
        if (blockSizes[_token] == 0 ) {
            return 5000;
        }
        return blockSizes[_token];
    }

    function redeem(uint256 value) public {
        if (value == 0) {revert();}

        if (value > accounts[msg.sender].balance) {revert();}

        accounts[msg.sender].balance = accounts[msg.sender].balance.sub(value);
        msg.sender.transfer(value);
        emit Withdrawal(msg.sender, value, now);
    }

//    function redeem(address token, uint256 value) public {
//        if (value == 0) {revert();}
//
//        if (value > accounts[msg.sender].balances[token]) {revert();}
//
//        accounts[msg.sender].balances[token] = accounts[msg.sender].balances[token].sub(value);
//        // ETH transfers and token transfers need to be handled differently
//        if (token == etherAddress) {
//            msg.sender.transfer(value);
//        } else {
//            IERC20(token).transfer(msg.sender, value);
//        }
//        emit Withdrawal(token, msg.sender, value, now);
//    }
//
//    function balanceOf(address user) public view returns (uint256) {
//        return accounts[user].balance;
//    }

    function getCommittedAmount(address user, address token) public view returns (uint256) {
        if (token == etherAddress) {
            return accounts[user].balance;
        }
        IERC20 ERC20Interface = IERC20(token);
        uint256 allowance = ERC20Interface.allowance(user, address(this));
        uint256 balance = ERC20Interface.balanceOf(user);
        if (allowance < balance) {
            return allowance;
        }
        return balance;
    }

    function transfer(address _from, address _to, address _token, uint256 _value) public {
        require(_isManager[msg.sender] || msg.sender == _from);
        require(_value > 0);
        if (_token == etherAddress) {
            require(accounts[_from].balance >= _value);
            accounts[_from].balance = accounts[_from].balance.sub(_value);
            accounts[_to].balance = accounts[_to].balance.add(_value);
        } else {
//            require(IERC20(_token).allowance(_from, address(this)) >= _value);

            IERC20 ERC20Interface = IERC20(_token);

            uint256 transactionId = transactions.push(
                Transfer({
                contract_:  _token,
                to_: _to,
                amount_: _value,
                failed_: true
                })
            );

            transactionIndexesToSender[_from].push(transactionId - 1);

            if(_value > ERC20Interface.allowance(_from, address(this))) {
                emit TransferFailed(_from, _to, _value);
                revert();
            }

            ERC20Interface.transferFrom(_from, _to, _value);

            transactions[transactionId - 1].failed_ = false;

            emit TransferSuccessful(_from, _to, _value);
        }
//        emit Transfer(_from, _to, _value, now);
    }

//    function transfer(address _from, address _to, address _token, uint256 _value) public onlyManagers {
//        require(accounts[_from].balances[_token] >= _value);
//        accounts[_from].balances[_token] = accounts[_from].balances[_token].sub(_value);
//        accounts[_to].balances[_token] = accounts[_to].balances[_token].add(_value);
//        emit DepositTransfer(_token, _from, _to, _value, now);
//    }
//
//    function transfer(address _to, address _token, uint256 _value) public {
//        require(accounts[msg.sender].balances[_token] >= _value);
//        accounts[msg.sender].balances[_token] = accounts[msg.sender].balances[_token].sub(_value);
//        accounts[_to].balances[_token] = accounts[_to].balances[_token].add(_value);
//        emit DepositTransfer(_token, msg.sender, _to, _value, now);
//    }

    // deposits
    // we're not using the third argument so we comment it out
    // to silence solidity linter warnings
//    function tokenFallback(address _from, uint _value, bytes memory _data) public {
//        // ERC223 token deposit handler
//        accounts[_from].balances[msg.sender] = accounts[_from].balances[msg.sender].add(_value);
//        _addToken(_from, msg.sender);
//        emit Deposit(msg.sender, _from, _value, now);
//    }

    function fund() public payable {
        // ETH deposit handler
        accounts[msg.sender].balance = accounts[msg.sender].balance.add(msg.value);
        _addToken(msg.sender, etherAddress);
        emit Deposit(msg.sender, msg.value, now);
    }

    function _addToken(address _owner, address _token) internal {
        if ( accounts[_owner].tokensInUse[_token] ) {
            return;
        }
        accounts[_owner].tokens.push(_token);
        accounts[_owner].tokensInUse[_token] = true;
    }

    function addToken(address _token) public {
        require(!accounts[msg.sender].tokensInUse[_token]);
        accounts[msg.sender].tokens.push(_token);
        accounts[msg.sender].tokensInUse[_token] = true;
    }

    function removeToken(address _token) public {
        require(accounts[msg.sender].tokensInUse[_token]);
        accounts[msg.sender].tokensInUse[_token] = false;
        accounts[msg.sender].tokens.push(_token);
    }

    function getTokens(address _user) public view returns (address[] memory) {
        return accounts[_user].tokens;
    }

    function getNumTokens(address _user) public view returns (uint256) {
        return accounts[_user].tokens.length;
    }

}

// File: contracts/SocialCreditBureau.sol

contract SocialCreditBureau is PrivateAccessible {
    using SafeMath for uint256;

    struct User {
        uint256 id;
        string name;
        uint256 birthday;
        uint64 mobileNumber;
        uint64 legalId;
        uint8 gender;
        bool registered;
        bool delinquent;
        address[] claimers;
    }

    struct Debt {
        uint256 nextReceivable;
        uint256 receivable;
        uint256 revolving;
        uint256 overdue;
        uint256 settled;
        uint256 prevSettlementTime;
    }

    mapping (address => User) users;

    // Creditor => Borrower => Token => Debt
    mapping(address => mapping(address => mapping(address => Debt))) debts;

//    enum Status {NotExists, Created, Pending, Active, Done, Declined}
//    enum KycLevel {Undefined, Tier1, Tier2, Tier3, Tier4, Tier5}

    SocuBank public bank;

    function setBank(address payable bankAddress) public onlyOwner {
        bank = SocuBank(bankAddress);
    }

    function getBankAddress() public view returns (address) {
        return address(bank);
    }

    function getUser(address _user) public view returns (
        uint256 _id,
        string memory _name,
        uint256 _birthday,
        uint64 _mobileNumber,
        uint64 _legalId,
        uint8 _gender,
        bool _registered,
        bool _delinquent,
        uint256 _numClaimers
    ) {
        if (msg.sender == _user) {
            _id = users[msg.sender].id;
            _name = users[msg.sender].name;
            _birthday = users[msg.sender].birthday;
            _mobileNumber = users[msg.sender].mobileNumber;
            _legalId = users[msg.sender].legalId;
            _gender = users[msg.sender].gender;
            _registered = users[msg.sender].registered;
            _delinquent = users[msg.sender].delinquent;
            _numClaimers = users[msg.sender].claimers.length;
        } else {
            _id = 0;
            _name = "";
            _birthday = 0;
            _mobileNumber = 0;
            _legalId = 0;
            _gender = 0;
            _registered = users[msg.sender].registered;
            _delinquent = users[msg.sender].delinquent;
            _numClaimers = users[msg.sender].claimers.length;
        }
    }

    function getClaimers(uint256 _count, uint256 _offset) public view returns (address[] memory) {
        return users[msg.sender].claimers;
    }


    function getCreditLineUsedAmount(address _creditor, address _borrower, address _token, uint256 _revolvingRateInBP, uint256 _overdueRateInBP) public view onlyManagers returns (
        uint256 _used
    ) {
        Debt storage debt = debts[_creditor][_borrower][_token];
        uint256 elapsedDays = (now - debt.prevSettlementTime) / 60 / 60 / 24;
        _used = debt.nextReceivable + debt.receivable + debt.revolving + debt.revolving.mul(_revolvingRateInBP).mul(elapsedDays).div(3650000) + debt.overdue + debt.overdue.mul(_overdueRateInBP).mul(elapsedDays).div(3650000);
    }

    function addReceivable(address _creditor, address _borrower, address _token, uint256 _value) public onlyManagers {
        debts[_creditor][_borrower][_token].receivable = debts[_creditor][_borrower][_token].receivable.add(_value);
    }

    function addNextReceivable(address _creditor, address _borrower, address _token, uint256 _value) public onlyManagers {
        debts[_creditor][_borrower][_token].nextReceivable = debts[_creditor][_borrower][_token].nextReceivable.add(_value);
    }

    function setDebtPrevSettlementTime(address _creditor, address _borrower, address _token, uint256 _now) public onlyManagers {
        debts[_creditor][_borrower][_token].prevSettlementTime = _now;
    }

    function getCreditLineIsOverdued(address _creditor, address _borrower, address _token) public view onlyManagers returns(bool){
        return debts[_creditor][_borrower][_token].overdue > 0;
    }

    function getOutstandingReceivable(address _creditor, address _borrower, address _token) public view onlyManagers returns (
        uint256 _receivable,
        uint256 _nextReceivable
    ) {
        Debt storage debt = debts[_creditor][_borrower][_token];
        _receivable = debt.receivable;
        _nextReceivable = debt.nextReceivable;
    }

    function getOutstandingRevolving(address _creditor, address _borrower, address _token, uint256 _revolvingRateInBP, uint256 _overdueRateInBP) public view onlyManagers returns (
        uint256 _revolving,
        uint256 _overdue
    ) {
        Debt storage debt = debts[_creditor][_borrower][_token];
        uint256 elapsedDays = (now - debt.prevSettlementTime) / 60 / 60 / 24;
        _revolving = debt.revolving + debt.revolving.mul(_revolvingRateInBP).mul(elapsedDays).div(3650000);
        _overdue = debt.overdue + debt.overdue.mul(_overdueRateInBP).mul(elapsedDays).div(3650000);
    }

    function repayFromTo(address _borrower, address _creditor, address _token, uint256 _amount, uint256 _revolvingRateInBP, uint256 _overdueRateInBP) public onlyManagers {
        Debt storage debt = debts[_creditor][_borrower][_token];
        uint256 elapsedDays = (now - debt.prevSettlementTime) / 60 / 60 / 24;
        uint256 revolvingAmount = debt.revolving + debt.revolving.mul(_revolvingRateInBP).mul(elapsedDays).div(3650000);
        uint256 overdueAmount = debt.overdue + debt.overdue.mul(_overdueRateInBP).mul(elapsedDays).div(3650000);

        uint256 available = _amount;
        if (available < overdueAmount) {
            overdueAmount = overdueAmount.sub(available);
            bank.transfer(_borrower, _creditor, _token, available);

        } else if (available < overdueAmount.add(revolvingAmount)){
            bank.transfer(_borrower, _creditor, _token, available);
            revolvingAmount = revolvingAmount.add(overdueAmount).sub(available);
            overdueAmount = 0;
        } else if (available < overdueAmount.add(revolvingAmount).add(debt.receivable)) {
            bank.transfer(_borrower, _creditor, _token, available);
            debt.receivable = debt.receivable.add(revolvingAmount).add(overdueAmount).sub(available);
            revolvingAmount = 0;
            overdueAmount = 0;
        } else if (available < overdueAmount.add(revolvingAmount).add(debt.receivable).add(debt.nextReceivable)) {
            bank.transfer(_borrower, _creditor, _token, available);
            debt.nextReceivable = debt.nextReceivable.add(debt.receivable).add(revolvingAmount).add(overdueAmount).sub(available);
            debt.receivable = 0;
            revolvingAmount = 0;
            overdueAmount = 0;
        } else {
            bank.transfer(_borrower, _creditor, _token, overdueAmount.add(revolvingAmount).add(debt.receivable).add(debt.nextReceivable));
            debt.nextReceivable = 0;
            debt.receivable = 0;
            revolvingAmount = 0;
            overdueAmount = 0;
        }
        debt.overdue = overdueAmount;
        debt.revolving = revolvingAmount;
        debt.prevSettlementTime = now;
    }
}

// File: contracts/SocialCreditUnion.sol

//import "./SocialCreditBureau.sol";

contract SocialCreditUnion is PrivateAccessible {
    using SafeMath for uint256;

    struct Membership {
        uint256[] hostingUnions;
        uint256[] joinedUnions;
        uint256[] creditUnions;
    }

    struct CreditLine {
        bool isActive;
        uint256 individualLimit;
        uint256 unionLimit;
    }

    struct Union {
        uint256 id;
        address host;
        string name;
        uint256 turn;
        uint256 prevSettlementTime;
        uint32 revolvingRateInBP; // per annum, ACT/365
        uint32 overdueRateInBP; // per annum, ACT/365
        uint32 minPaymentRateInPercent; // per annum, ACT/365
        uint32 color;
        address[] members;
        address[] creditors;
        mapping(address => bool) isMember;
        mapping(address => bool) isCreditor;

        // Creditor => Token => CreditLine
        mapping(address => mapping(address => CreditLine)) creditLines;
    }

    SocuBank public bank;
    SocialCreditBureau public bureau;
    Union[] internal unions;
    mapping (address => Membership) memberships;

    event NewUnionCreated(uint256 indexed _unionId, address indexed _host, uint256 _time);
    event Borrow(uint256 indexed _unionId, address indexed _token, address indexed _borrower, uint256 _amount, uint256 _time);
    event Repay(uint256 indexed _unionId, address indexed _token, address indexed _borrower, uint256 _amount, uint256 _time);
    event NewMemberAdded(uint indexed _unionId, address indexed _member);
    event MemberExpelled(uint indexed _unionId, address indexed _member);
    event Revolve(uint256 indexed _unionId, uint256 _turn);

    function setBank(address payable bankAddress) public onlyOwner {
        bank = SocuBank(bankAddress);
    }

//    function getBankAddress() public view returns (address) {
//        return address(bank);
//    }

    function setBureau(address bureauAddress) public onlyOwner {
        bureau = SocialCreditBureau(bureauAddress);
    }

//    function getBureauAddress() public view returns (address) {
//        return address(bureau);
//    }

    function createUnion(string memory _name, uint32 color) public {
        address[] memory members = new address[](1);
        address[] memory creditors = new address[](1);
        members[0] = msg.sender;
        creditors[0] = msg.sender;
        Union memory union = Union(unions.length,
            msg.sender,
            _name,
            0,
            0,
            0,
            2490,
            10,
            color,
            members,
            creditors
        );
        uint256 unionId = unions.push(union) - 1;
        unions[unionId].isMember[msg.sender] = true;
        unions[unionId].isCreditor[msg.sender] = true;
        addUnion(msg.sender, unionId);
        emit NewUnionCreated(unionId, msg.sender, now);
    }

    function getUnionsLength() public view returns (uint) {
        return unions.length;
    }

    function getUnionDetail(uint256 _unionId) public view returns (
        uint256 _id,
        address _host,
        string memory _name,
        uint256 _turn,
        uint256 _prevSettlementTime,
        uint32 _revolvingRateInBP,
        uint32 _overdueRateInBP,
        uint32 _minPaymentRateInPercent,
        uint32 _color,
        uint256 _numMembers,
        uint256 _numCreditors
    ) {
        _id = unions[_unionId].id;
        _host = unions[_unionId].host;
        _name = unions[_unionId].name;
        _turn = unions[_unionId].turn;
        _prevSettlementTime = unions[_unionId].prevSettlementTime;
        _revolvingRateInBP = unions[_unionId].revolvingRateInBP;
        _overdueRateInBP =  unions[_unionId].overdueRateInBP;
        _minPaymentRateInPercent = unions[_unionId].minPaymentRateInPercent;
        _color = unions[_unionId].color;
        _numMembers = unions[_unionId].members.length;
        _numCreditors = unions[_unionId].creditors.length;
    }

    function getCreditor(uint256 _unionId, uint256 i) public view returns (address) {
        require(i < unions[_unionId].creditors.length);
        return unions[_unionId].creditors[i];
    }

    function getMember(uint256 _unionId, uint256 i) public view returns (address) {
        require(i < unions[_unionId].members.length);
        return unions[_unionId].members[i];
    }

    function start(uint256 _unionId) public {
        Union storage union = unions[_unionId];
        require(union.turn == 0);
        require(union.host == msg.sender);
        union.turn = 1;
        union.prevSettlementTime = now + 14 days;
    }

    function addMember(uint256 _unionId, address newMember) public {
        Union storage union = unions[_unionId];
        require(msg.sender == union.host || _isManager[msg.sender]);
        require(!union.isMember[newMember]);
        union.members.push(newMember);
        union.isMember[newMember] = true;
        addUnion(newMember, _unionId);
        emit NewMemberAdded(_unionId, newMember);
    }

    function expelMember(uint256 _unionId, address member) public {
        Union storage union = unions[_unionId];
        require(msg.sender == union.host || _isManager[msg.sender]);
        require(union.isMember[member]);
        union.isMember[member] = false;
        emit MemberExpelled(_unionId, member);
    }

    function setCreditLine(uint256 _unionId, address _token, uint256 _individualLimit, uint256 _unionLimit) public {
        require(_individualLimit <= _unionLimit);
        Union storage union = unions[_unionId];
        CreditLine storage creditLine = union.creditLines[msg.sender][_token];
        require(!(creditLine.individualLimit == _individualLimit && creditLine.unionLimit == _unionLimit));
        creditLine.individualLimit = _individualLimit;
        creditLine.unionLimit = _unionLimit;
    }

    function _getCreditLineLendableAmount(address _creditor, uint256 _unionId, address _token) internal view returns (
        uint256 _availableAmount
    ) {
        CreditLine storage creditLine = unions[_unionId].creditLines[_creditor][_token];
        uint256 balance = bank.getCommittedAmount(_creditor, _token);
        if (!creditLine.isActive) {
            return 0;
        }
        _availableAmount = creditLine.individualLimit > balance ? balance : creditLine.individualLimit;
    }

    function getCreditLine(uint256 _unionId, address _token) public view returns (
        bool _isActive,
        uint256 _individualLimit,
        uint256 _unionLimit
    ) {
        Union storage union = unions[_unionId];
        CreditLine storage creditLine = union.creditLines[msg.sender][_token];
        _isActive = creditLine.isActive;
        _individualLimit = creditLine.individualLimit;
        _unionLimit = creditLine.unionLimit;
    }

    function activateCreditLine(uint256 _unionId, address _token) public {
        Union storage union = unions[_unionId];
        CreditLine storage creditLine = union.creditLines[msg.sender][_token];
        require(!creditLine.isActive);
        if (!union.isCreditor[msg.sender]) {
            union.isCreditor[msg.sender] = true;
            union.creditors.push(msg.sender);
            addUnion(msg.sender, _unionId);
        }
        creditLine.isActive = true;
    }

    function inactivateCreditLine(uint256 _unionId, address _token) public {
        Union storage union = unions[_unionId];
        require(union.isCreditor[msg.sender]);
        CreditLine storage creditLine = union.creditLines[msg.sender][_token];
        require(creditLine.isActive);
        creditLine.isActive = false;
    }



    function _getMarginalAvg(uint256 _amount, uint256 _numCreditors, address _token) internal view returns (uint256) {
        uint256 blockSize = bank.getBlockSize(_token);
        return uint256(uint256(_amount / (_numCreditors) + blockSize - 1) / blockSize) * blockSize;
    }

    function borrow(uint256 _unionId, address _token, uint256 value) public {
        emit Borrow(_unionId, _token, msg.sender, value, now);
        require(value > 0);
        Union storage union = unions[_unionId];
        require(union.isMember[msg.sender]);
        uint256 i = 0;
        bool[] memory confirmed = new bool[](union.creditors.length);
        bool allAboveAvg = false;
        uint256 numConfirmedCreditLines;

        if (union.isCreditor[msg.sender]) {
            numConfirmedCreditLines = 1;
        } else {
            numConfirmedCreditLines = 0;
        }
        require(union.creditors.length > numConfirmedCreditLines);
        uint256 marginalAvg = _getMarginalAvg(value, union.creditors.length - numConfirmedCreditLines, _token);

        uint256 numPrevConfirmedCreditLines = numConfirmedCreditLines;
        while (value > 0) {
            if (!confirmed[i % union.creditors.length]) {
                address creditor = union.creditors[i % union.creditors.length];
                if (creditor != msg.sender) {
                    if (!union.creditLines[creditor][_token].isActive || bureau.getCreditLineIsOverdued(creditor, msg.sender, _token)) {
                        confirmed[i % union.creditors.length] = true;
                        numConfirmedCreditLines++;
                    } else {
                        uint availableAmount = _getCreditLineAvailableAmount(creditor, _unionId, msg.sender, _token);
                        if (availableAmount <= marginalAvg || allAboveAvg) {
                            uint lendingAmount = availableAmount > value ? value : availableAmount;

                            bank.transfer(creditor, msg.sender, _token, lendingAmount);
                            bureau.addReceivable(creditor, msg.sender, _token, lendingAmount);
                            value = value.sub(lendingAmount);
                            confirmed[i % union.creditors.length] = true;
                            numConfirmedCreditLines++;
                        }
                    }
                }
            }
            if (numConfirmedCreditLines == union.creditors.length) {
                break;
            }
            if ((i % union.creditors.length) == (union.creditors.length - 1)) {
                if (numPrevConfirmedCreditLines == numConfirmedCreditLines) {
                    allAboveAvg = true;
                } else {
                    numPrevConfirmedCreditLines = numConfirmedCreditLines;
                }
                marginalAvg = _getMarginalAvg(value, union.creditors.length - numConfirmedCreditLines, _token);
            }
            i++;
        }
        require(value == 0);
    }

    function _getCreditLineAvailableAmount(address _creditor, uint256 _unionId, address _borrower, address _token) internal view returns (
        uint256 _availableAmount
    ) {

        uint256 used = bureau.getCreditLineUsedAmount(_creditor, _borrower, _token, unions[_unionId].revolvingRateInBP, unions[_unionId].overdueRateInBP);
        CreditLine storage creditLine = unions[_unionId].creditLines[_creditor][_token];
//        uint256 balance = bank.balanceOf(_creditor, _token);
        uint256 balance = bank.getCommittedAmount(_creditor, _token);

        if (!creditLine.isActive || balance == 0 || bureau.getCreditLineIsOverdued(_creditor, _borrower, _token) || _creditor == _borrower) {
            return 0;
        }

        uint256 remaining = creditLine.individualLimit > used ? creditLine.individualLimit - used : 0;
        _availableAmount = remaining > balance ? balance : remaining;
    }

    function _addReceivable(address _creditor, uint256 _unionId, address _borrower, address _token, uint256 _value) internal {
        if (now < unions[_unionId].prevSettlementTime) {
            bureau.addReceivable(_creditor, _borrower, _token, _value);
            return;
        }
        if ((now - unions[_unionId].prevSettlementTime) / 60 / 60 / 24 < 14) {
            bureau.addReceivable(_creditor, _borrower, _token, _value);
        } else  {
            bureau.addNextReceivable(_creditor, _borrower, _token, _value);
        }
    }

    function getMembership(address _member) public view returns (
//        uint256 _numHostingUnions,
        uint256 _numJoinedUnions
//        uint256 _numCreditUnions
    ) {
//        _numHostingUnions = memberships[_member].hostingUnions.length;
        _numJoinedUnions = memberships[_member].joinedUnions.length;
//        _numCreditUnions = memberships[_member].creditUnions.length;
    }

    function getNumUnions(address _member) public view returns (
        uint256 _numUnions
    ) {
        _numUnions = memberships[_member].joinedUnions.length;
    }

    function getUnions(uint256 _count, uint256 _offset) public view returns (uint256[] memory) {
        return memberships[msg.sender].joinedUnions;
    }


//    function getHostingUnions(uint256 _count, uint256 _offset) public view returns (uint256[] memory) {
//        return memberships[msg.sender].hostingUnions;
//    }
//    function getJoinedUnions(uint256 _count, uint256 _offset) public view returns (uint256[] memory) {
//        return memberships[msg.sender].joinedUnions;
//    }
//    function getCreditUnions(uint256 _count, uint256 _offset) public view returns (uint256[] memory) {
//        return memberships[msg.sender].creditUnions;
//    }

//    function addHostingUnion(address _host, uint256 _unionId) internal {
//        memberships[_host].hostingUnions.push(_unionId);
//        memberships[_host].joinedUnions.push(_unionId);
//        memberships[_host].creditUnions.push(_unionId);
//    }

//    function addJoinedUnion(address _member, uint256 _unionId) internal {
//        memberships[_member].joinedUnions.push(_unionId);
//    }

//    function addCreditUnion(address _creditor, uint256 _unionId) internal {
//        memberships[_creditor].creditUnions.push(_unionId);
//    }
    function addUnion(address _creditor, uint256 _unionId) internal {
        memberships[_creditor].joinedUnions.push(_unionId);
    }

    function repay(uint256 _unionId, address _token, uint256 value) public {
        uint256 balance = bank.getCommittedAmount(msg.sender, _token);
        require(balance >= value && value > 0);
        _repayFrom(msg.sender, _unionId, _token, value);
        emit Repay(_unionId, _token, msg.sender, value, now);
    }

    function _repayFrom(address _borrower, uint256 _unionId, address _token, uint256 _amount) internal {
        uint256 toRepay = _amount;
        uint256 sumTotalPayableAmount = 0;
        uint256[] memory outstandingAmounts = new uint256[](unions[_unionId].creditors.length);

        for (uint256 i = 0; i < unions[_unionId].creditors.length; i++) {
            outstandingAmounts[i] = bureau.getCreditLineUsedAmount(unions[_unionId].creditors[i], _borrower, _token, unions[_unionId].revolvingRateInBP, unions[_unionId].overdueRateInBP);
            sumTotalPayableAmount = sumTotalPayableAmount.add(outstandingAmounts[i]);
        }

        if (sumTotalPayableAmount < toRepay) {
            toRepay = sumTotalPayableAmount;
        }

        for (uint256 i = 0; i < unions[_unionId].creditors.length; i++) {
            if (outstandingAmounts[i] > 0) {
                uint repayingAmount = outstandingAmounts[i] * toRepay / sumTotalPayableAmount;
                bureau.repayFromTo(_borrower, unions[_unionId].creditors[i], _token, repayingAmount, unions[_unionId].revolvingRateInBP, unions[_unionId].overdueRateInBP);
            } else {
                bureau.setDebtPrevSettlementTime(unions[_unionId].creditors[i], _borrower, _token, now);
            }
        }
    }

    function settle(uint _unionId, address _token) public {
        Union storage union = unions[_unionId];
        require(union.turn > 0);
        require(now >= union.prevSettlementTime + 28 days);

        for (uint256 i = 0; i < union.members.length; i++) {
            address borrower = union.members[i];
            uint256 balance = bank.getCommittedAmount(borrower, _token);
            _repayFrom(union.members[i], _unionId, _token, balance);
        }
        union.prevSettlementTime = now;
        emit Revolve(_unionId, union.turn);
        union.turn++;
    }

    function getUnionAvailable(uint256 _unionId, address _token) public view returns (
        uint256 _availableAmount
    ) {
        _availableAmount = 0;

        for (uint256 i = 0; i < unions[_unionId].creditors.length; i++) {
            address creditor = unions[_unionId].creditors[i];
            if (creditor == msg.sender)
                continue;

            uint256 availableAmount = _getCreditLineAvailableAmount(creditor, _unionId, msg.sender, _token);
            _availableAmount = _availableAmount.add(availableAmount);
        }
    }

    function getUnionPayable(uint256 _unionId, address _token) public view returns (
        uint256 _payable,
        uint256 _nextPayable
    ) {
        _payable = 0;
        _nextPayable = 0;

        for (uint256 i = 0; i < unions[_unionId].creditors.length; i++) {
            address creditor = unions[_unionId].creditors[i];
            if (creditor == msg.sender)
                continue;

            uint256 payableAmount;
            uint256 nextPayable;

            (payableAmount, nextPayable) = bureau.getOutstandingReceivable(creditor, msg.sender, _token);
            _payable = _payable.add(payableAmount);
            _nextPayable = _nextPayable.add(nextPayable);
        }
    }

    function getUnionRevolvingPayable(uint256 _unionId, address _token) public view returns (
        uint256 _revolvingPayable,
        uint256 _overduePayable
    ) {
        _revolvingPayable = 0;
        _overduePayable = 0;

        for (uint256 i = 0; i < unions[_unionId].creditors.length; i++) {
            address creditor = unions[_unionId].creditors[i];
            if (creditor == msg.sender)
                continue;

            uint256 revolvingPayable;
            uint256 overduePayable;

            (revolvingPayable, overduePayable) = bureau.getOutstandingRevolving(creditor, msg.sender, _token, unions[_unionId].revolvingRateInBP, unions[_unionId].overdueRateInBP);
            _revolvingPayable = _revolvingPayable.add(revolvingPayable);
            _overduePayable = _overduePayable.add(overduePayable);
        }
    }


    function getUnionTotalAvailableAmount(uint256 _unionId, address _token) public view returns (
        uint256 _availableAmount
    ) {
        _availableAmount = 0;

        for (uint256 i = 0; i < unions[_unionId].creditors.length; i++) {
            address creditor = unions[_unionId].creditors[i];
            if (creditor == msg.sender)
                continue;

            _availableAmount = _availableAmount.add(_getCreditLineLendableAmount(creditor, _unionId, _token));
        }
    }

    function getUnionReceivable(uint256 _unionId, address _token) public view returns (
        uint256 _receivableAmount,
        uint256 _nextReceivableAmount
    ) {
        _receivableAmount = 0;
        _nextReceivableAmount = 0;

        for (uint256 i = 0; i < unions[_unionId].members.length; i++) {
            address borrower = unions[_unionId].members[i];
            if (borrower == msg.sender)
                continue;

            uint256 receivable;
            uint256 nextReceivable;

            (receivable, nextReceivable) = bureau.getOutstandingReceivable(msg.sender, borrower, _token);

            _receivableAmount = _receivableAmount.add(receivable);
            _nextReceivableAmount = _nextReceivableAmount.add(nextReceivable);
        }
    }

    function getUnionRevolvingReceivable(uint256 _unionId, address _token) public view returns (
        uint256 _revolvingAmount,
        uint256 _overdueAmount
    ) {
        _revolvingAmount = 0;
        _overdueAmount = 0;

        for (uint256 i = 0; i < unions[_unionId].members.length; i++) {
            address borrower = unions[_unionId].members[i];
            if (borrower == msg.sender)
                continue;

            uint256 revolving;
            uint256 overdue;

            (revolving, overdue) = bureau.getOutstandingRevolving(msg.sender, borrower, _token, unions[_unionId].revolvingRateInBP, unions[_unionId].overdueRateInBP);

            _revolvingAmount = _revolvingAmount.add(revolving);
            _overdueAmount = _overdueAmount.add(overdue);
        }
    }
}
