pragma solidity 0.4.22;
contract Overflow{
uint256  amount
function batchTransfer(address[] _receivers, uint256 _value) public returns (bool) {
uint  cnt = _receivers.length;
amount = uint256(cnt) * _value;
require(amount /cnt == _value, "SafeMath: multiplication overflow");
    require(cnt > 0 && cnt <= 20);
    require(_value > 0 && balances[msg.sender] >= amount);
    balances[msg.sender] = balances[msg.sender].sub(amount);
    for (uint i = 0; i < cnt; i++) {
        balances[_receivers[i]] = balances[_receivers[i]].add(_value);
        Transfer(msg.sender, _receivers[i], _value);
    }
    return true;
 }
 }
