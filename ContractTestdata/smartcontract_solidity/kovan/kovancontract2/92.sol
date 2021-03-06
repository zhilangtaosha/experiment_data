/**
 *Submitted for verification at Etherscan.io on 2019-08-03
*/

pragma solidity ^0.5.7;


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


contract CredEth {

    using SafeMath for uint256;
    
    uint256 public constant INITIAL_REP = 1000;
    uint256 public constant PER_DAY_VOUCHE_COUNT = 3;
    uint256 public constant DAO_CAP = 1000000;
    uint256 public constant LOCKDROP_CAP = 1000000;

    uint256 public distributedByDao;
    uint256 public distributedByLockdrop;
    address public daoAddress;

    modifier onlyDAO() {
        require(msg.sender == daoAddress, "Not Authorised");
        _;
    }

    struct Reputation {
        uint256 rep;
        uint256 lastVouchTime;
        uint256 vouchCount;
    }

    address[] members;

    mapping(address => Reputation) public addressToReputation;

    event Vouched(address indexed _vouchee, address indexed _voucher, uint256 _vouchedAmount);
    event DaoDistribution(address indexed _to, uint256 _reputation);
    event Signaled();
    event IssueReputation(address indexed _to, uint256 _reputation);

    constructor (address _daoAddress) public {
        require(_daoAddress != address(0), "Invalid address");
        daoAddress = _daoAddress;
    }

    function vouch(address _vouchee) external {
        require(_vouchee != msg.sender, "Not allowed");
        Reputation storage voucher = addressToReputation[msg.sender];
        if (now.sub(voucher.lastVouchTime) > 24 hours) {
            voucher.lastVouchTime = now;
            voucher.vouchCount = 0;
        }
        voucher.vouchCount++;
        require(voucher.vouchCount <= PER_DAY_VOUCHE_COUNT, "Exceeding limit");
        uint256 voucherRep = getReputation(msg.sender);
        _addNewMember(_vouchee);
        uint256 voucheeRep = getReputation(_vouchee);
        uint256 vouchedGiven = log_2(voucherRep * voucherRep);
        addressToReputation[_vouchee].rep = voucheeRep.add(vouchedGiven);
        emit Vouched(_vouchee, msg.sender, vouchedGiven);
    }

    function daoDistribution(address _to, uint256 _rep) external onlyDAO {
        require(_to != address(0), "Invalid address");
        require(_rep > 0, "Invalid reputation");
        require(DAO_CAP > distributedByDao.add(_rep), "Exceeding cap limit");
        distributedByDao = distributedByDao.add(_rep);
        _addNewMember(_to);
        uint256 currentReputation = getReputation(_to);
        addressToReputation[_to].rep = currentReputation.add(_rep);
        emit DaoDistribution(_to, _rep);
    }

    function signal() external {
        emit Signaled();
    }

    function issueReputation(address _to, uint256 _reputation) external onlyDAO {
        require(_to != address(0), "Invalid address");
        require(_reputation > 0, "Invalid reputation");
        require(LOCKDROP_CAP > distributedByLockdrop.add(_reputation), "Exceeding cap limit");
        distributedByLockdrop = distributedByLockdrop.add(_reputation);
        _addNewMember(_to);
        uint256 currentReputation = getReputation(_to);
        addressToReputation[_to].rep = currentReputation.add(_reputation);
        emit IssueReputation(_to, _reputation);
    }

    function getReputation(address _of) public view returns(uint256 reputation) {
        reputation = addressToReputation[_of].rep == 0 ? 1000 : addressToReputation[_of].rep;
    }

    function _addNewMember(address _holder) internal {
        if (addressToReputation[_holder].rep == 0)
            members.push(_holder);
    }

    function getAllMembers() public view returns(address[] memory, uint256[] memory) {
        uint256[] memory reputations = new uint256[](members.length);
        for (uint256 i = 0; i < members.length; i++) {
            reputations[i] = addressToReputation[members[i]].rep;
        }
        return (members, reputations);
    }


    /**
     * @notice function used to calculate the celing of logn for base 2
     * @dev referenced from https://ethereum.stackexchange.com/a/30168/15915
     */
    function log_2(uint x) public pure returns (uint y){
        assembly {
            let arg := x
            x := sub(x,1)
            x := or(x, div(x, 0x02))
            x := or(x, div(x, 0x04))
            x := or(x, div(x, 0x10))
            x := or(x, div(x, 0x100))
            x := or(x, div(x, 0x10000))
            x := or(x, div(x, 0x100000000))
            x := or(x, div(x, 0x10000000000000000))
            x := or(x, div(x, 0x100000000000000000000000000000000))
            x := add(x, 1)
            let m := mload(0x40)
            mstore(m,           0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
            mstore(add(m,0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
            mstore(add(m,0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
            mstore(add(m,0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
            mstore(add(m,0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
            mstore(add(m,0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
            mstore(add(m,0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
            mstore(add(m,0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
            mstore(0x40, add(m, 0x100))
            let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
            let shift := 0x100000000000000000000000000000000000000000000000000000000000000
            let a := div(mul(x, magic), shift)
            y := div(mload(add(m,sub(255,a))), shift)
            y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
        }  
    }
}
