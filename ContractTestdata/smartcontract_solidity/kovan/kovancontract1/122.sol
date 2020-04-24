/**
 *Submitted for verification at Etherscan.io on 2019-02-19
*/

pragma solidity ^0.5.2;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
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
    function isOwner() public view returns (bool) {
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

// File: contracts/Common.sol

contract Common {
    struct Order {
        // 0: maker
        // 1: taker
        // 2: makerToken
        // 3: takerToken
        // 4: reseller
        // 5: [placeholder]
        // 6: verifier
        // 7: makerTokenBank
        // 8: takerTokenBank
        address[9] orderAddresses;
        // 0: makerAmount
        // 1: takerAmount
        // 2: expires
        // 3: nonce
        // 4: minimumTakerAmount
        uint256[5] orderValues;
        bytes makerData;
        bytes takerData;
    }

    struct OrderInfo {
        uint8 orderStatus;
        bytes32 orderHash;
        uint256 filledTakerAmount;
    }

    struct FillResults {
        uint256 makerFilledAmount;
        uint256 makerFeeExchange;
        uint256 makerFeeReseller;
        uint256 takerFilledAmount;
        uint256 takerFeeExchange;
        uint256 takerFeeReseller;
    }

    struct MatchedFillResults {
        FillResults left;
        FillResults right;
        uint256 spreadAmount;
    }
}

// File: contracts/Verifier.sol

pragma experimental ABIEncoderV2;


/// An abstract Contract of Verifier.
contract Verifier is Common {

    /// Verifies trade for KYC purposes.
    /// @param order Order object.
    /// @param takerAmountToFill Desired amount of takerToken to sell.
    /// @param taker Taker address.
    /// @return Whether the trade is valid.
    function verify(
        Order memory order,
        uint256 takerAmountToFill,
        address taker
    )
    public
    view
    returns (bool);

    /// Verifies user address for KYC purposes.
    /// @param user User address.
    /// @return Whether the user address is valid.
    function verifyUser(address user)
    external
    view
    returns (bool);
}

// File: contracts/DefaultVerifier.sol


/// A collection of trusted verifiers.
contract DefaultVerifier is Ownable, Verifier {

    address[] public trustedVerifiers;

    event SetVerifiers(address[] verifiers);

    /// Trusts an array of verifier addresses. Only contract owner can call this function.
    /// @param verifiers An array of verifier addresses.
    function setVerifiers(address[] memory verifiers) public onlyOwner {
        trustedVerifiers = verifiers;
        emit SetVerifiers(verifiers);
    }

    /// Verifies trade in all trusted verifiers.
    /// @param order Order object.
    /// @param takerAmountToFill Desired amount of takerToken to sell.
    /// @param taker Taker address.
    /// @return True if the trade passes at least one verifier.
    function verify(
        Order memory order,
        uint256 takerAmountToFill,
        address taker
    )
    public
    view
    returns (bool) {
        for (uint256 i = 0; i < trustedVerifiers.length; i++) {
            if (Verifier(trustedVerifiers[i]).verify(order, takerAmountToFill, taker)) {
                return true;
            }
        }
        return false;
    }

    /// Verifies user address in all trusted verifiers.
    /// @param user User address.
    /// @return True if the user address passes at least one verifier.
    function verifyUser(address user)
    external
    view
    returns (bool) {
        for (uint256 i = 0; i < trustedVerifiers.length; i++) {
            if (Verifier(trustedVerifiers[i]).verifyUser(user)) {
                return true;
            }
        }
        return false;
    }
}
