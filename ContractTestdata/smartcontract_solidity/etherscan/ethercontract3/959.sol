/**
 *Submitted for verification at Etherscan.io on 2019-03-12
*/

pragma solidity ^0.4.25;

contract SafeMath {
  function safeMul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assertz(bool assertion) internal pure {
    require (assertion);
  }
}

contract Token {
  /// @return total amount of tokens
  function totalSupply() view public returns (uint256 supply);

  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) view public returns (uint256 balance);

  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) public returns (bool success);

  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

  /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of wei to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) public returns (bool success);

  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
}

contract AccountLevels {
  //given a user, returns an account level
  //0 = regular user (pays take fee and make fee)
  //1 = market maker silver (pays take fee, no make fee, gets rebate)
  //2 = market maker gold (pays take fee, no make fee, gets entire counterparty's take fee as rebate)
  function accountLevel(address user) view public returns(uint);
}

contract AccountLevelsTest is AccountLevels {
  mapping (address => uint) public accountLevels;

  function setAccountLevel(address user, uint level) public{
    accountLevels[user] = level;
  }

  function accountLevel(address user) view public returns(uint) {
    return accountLevels[user];
  }
}

contract EtherDelta is SafeMath {
  address public admin; //the admin address
  address public feeAccount; //the account that will receive fees
  address public accountLevelsAddr; //the address of the AccountLevels contract
  uint public feeMake; //percentage times (1 ether)
  uint public feeTake; //percentage times (1 ether)
  uint public feeRebate; //percentage times (1 ether)
  mapping (address => mapping (address => uint)) public tokens; //mapping of token addresses to mapping of account balances (token=0 means Ether)
  mapping (address => mapping (bytes32 => bool)) public orders; //mapping of user accounts to mapping of order hashes to booleans (true = submitted by user, equivalent to offchain signature)
  mapping (address => mapping (bytes32 => uint)) public orderFills; //mapping of user accounts to mapping of order hashes to uints (amount of order that has been filled)

  event Order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user,uint singleTokenValue, string orderType, uint blockNo);
  event Cancel(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user,string orderId);
  event Trade(address tokenGet, uint amountGet,uint amountReceived, address tokenGive, uint amountGive,uint amountSent, address get, address give,string orderId,uint orderFills);
  event Deposit(address token, address user, uint amount, uint balance);
  event Withdraw(address token, address user, uint amount, uint balance);

  constructor(address admin_, address feeAccount_, address accountLevelsAddr_, uint feeMake_, uint feeTake_, uint feeRebate_) public{
    admin = admin_;
    feeAccount = feeAccount_;
    accountLevelsAddr = accountLevelsAddr_;
    feeMake = feeMake_;
    feeTake = feeTake_;
    feeRebate = feeRebate_;
  }

  function() public{
    require(false);
  }

  function changeAdmin(address admin_) public{
    require (msg.sender == admin);
    admin = admin_;
  }

  function changeAccountLevelsAddr(address accountLevelsAddr_) public{
    require (msg.sender == admin);
    accountLevelsAddr = accountLevelsAddr_;
  }

  function changeFeeAccount(address feeAccount_) public{
    require (msg.sender == admin);
    feeAccount = feeAccount_;
  }

  function changeFeeMake(uint feeMake_) public{
    require (msg.sender == admin);
    require (feeMake_ < feeMake);
    feeMake = feeMake_;
  }

  function changeFeeTake(uint feeTake_) public{
    require (msg.sender == admin);
    require (feeTake_ < feeTake && feeTake_ > feeRebate);
    feeTake = feeTake_;
  }

  function changeFeeRebate(uint feeRebate_) public{
    require (msg.sender == admin);
    require (feeRebate_ > feeRebate && feeRebate_ < feeTake) ;
    feeRebate = feeRebate_;
  }

  function deposit() payable public{
    tokens[0][msg.sender] = safeAdd(tokens[0][msg.sender], msg.value);
    emit Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
  }

  function withdraw(uint amount)public {
    require (tokens[0][msg.sender] >= amount);
    tokens[0][msg.sender] = safeSub(tokens[0][msg.sender], amount);
    require (msg.sender.call.value(amount)()) ;
    emit Withdraw(0, msg.sender, amount, tokens[0][msg.sender]);
  }

  function depositToken(address token, uint amount) public{
    //remember to call Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
    require (token!=0) ;
    require (Token(token).transferFrom(msg.sender, this, amount));
    tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
    emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
  }

  function withdrawToken(address token, uint amount) public {
    require (token!=0) ;
    require (tokens[token][msg.sender] >= amount) ;
    tokens[token][msg.sender] = safeSub(tokens[token][msg.sender], amount);
    require (Token(token).transfer(msg.sender, amount)) ;
    emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
  }

  function balanceOf(address token, address user) view public returns (uint) {
    return tokens[token][user];
  }

  function order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, 
      uint expires, uint nonce,uint singleTokenValue, string orderType) public{
    bytes32 hash = sha256(abi.encodePacked(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
    orders[msg.sender][hash] = true;
    emit Order(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender,singleTokenValue,orderType,block.number);
  }

  function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, 
            uint amount, uint oldBlockNumber,string orderId) public {
    //amount is in amountGet terms
    bytes32 hash = sha256(abi.encodePacked(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
 
    require (orders[user][hash] && block.number <= (oldBlockNumber + expires) && safeAdd(orderFills[user][hash], amount) <= amountGet);
    
    tradeBalances(tokenGet, amountGet, tokenGive, amountGive, user, amount);
    orderFills[user][hash] = safeAdd(orderFills[user][hash], amount);
    uint orderFilled = orderFills[user][hash];
    uint amountSent = (amountGive * amount / amountGet);
    emit Trade(tokenGet, amountGet, amount, tokenGive, amountGive, amountSent, user, msg.sender, orderId, orderFilled);
    // anjali
  }

  function tradeBalances(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount) private {
    uint feeMakeXfer = safeMul(amount, feeMake) / (1 ether);
    uint feeTakeXfer = safeMul(amount, feeTake) / (1 ether);
    uint feeRebateXfer = 0;
    if (accountLevelsAddr != 0x0) {
      uint accountLevel = AccountLevels(accountLevelsAddr).accountLevel(user);
      if (accountLevel==1) feeRebateXfer = safeMul(amount, feeRebate) / (1 ether);
      if (accountLevel==2) feeRebateXfer = feeTakeXfer;
    }
    tokens[tokenGet][msg.sender] = safeSub(tokens[tokenGet][msg.sender], safeAdd(amount, feeTakeXfer));
    tokens[tokenGet][user] = safeAdd(tokens[tokenGet][user], safeSub(safeAdd(amount, feeRebateXfer), feeMakeXfer));
    tokens[tokenGet][feeAccount] = safeAdd(tokens[tokenGet][feeAccount], safeSub(safeAdd(feeMakeXfer, feeTakeXfer), feeRebateXfer));
    tokens[tokenGive][user] = safeSub(tokens[tokenGive][user], safeMul(amountGive, amount) / amountGet);
    tokens[tokenGive][msg.sender] = safeAdd(tokens[tokenGive][msg.sender], safeMul(amountGive, amount) / amountGet);
  }

  function testTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, address sender) view public returns(bool) {
    if (!(
      tokens[tokenGet][sender] >= amount &&
      availableVolume(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user, v, r, s) >= amount
    )) return false;
    return true;
  }

  function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) view public returns(uint) {
    bytes32 hash = sha256(abi.encodePacked(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
    if (!(
      (orders[user][hash] || ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),v,r,s) == user) &&
      block.number <= expires
    )) return 0;
    uint available1 = safeSub(amountGet, orderFills[user][hash]);
    uint available2 = safeMul(tokens[tokenGive][user], amountGet) / amountGive;
    if (available1<available2) return available1;
    return available2;
  }

  function amountFilled(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user) view public returns(uint) {
    bytes32 hash = sha256(abi.encodePacked(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
    return orderFills[user][hash];
  }

  function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, string orderId) public{
    bytes32 hash = sha256(abi.encodePacked(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
    require (orders[msg.sender][hash]);
    orderFills[msg.sender][hash] = amountGet;
    emit Cancel(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender,orderId);
  }
}
