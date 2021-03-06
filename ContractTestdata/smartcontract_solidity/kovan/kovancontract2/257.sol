/**
 *Submitted for verification at Etherscan.io on 2019-07-23
*/

pragma solidity 0.5.4;


interface Token {

    /// @return total amount of tokens
    function totalSupply() external view returns (uint256 supply);

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // Optionally implemented function to show the number of decimals for the token
    function decimals() external view returns (uint8 decimals);
}

/// @title Utils
/// @notice Utils contract for various helpers used by the Raiden Network smart
/// contracts.
contract Utils {
    enum MessageTypeId {
        None,
        BalanceProof,
        BalanceProofUpdate,
        Withdraw,
        CooperativeSettle,
        IOU,
        MSReward
    }

    /// @notice Check if a contract exists
    /// @param contract_address The address to check whether a contract is
    /// deployed or not
    /// @return True if a contract exists, false otherwise
    function contractExists(address contract_address) public view returns (bool) {
        uint size;

        assembly {
            size := extcodesize(contract_address)
        }

        return size > 0;
    }
}

contract Deposit {
    // This contract holds ERC20 tokens as deposit until a predetemined point of time.

    // The ERC20 token contract that the deposit is about.
    Token public token;

    // The address that can withdraw the deposit after the release time.
    address public withdrawer;

    // The timestamp after which the withdrawer can withdraw the deposit.
    uint256 public release_at;

    /// @param _token The address of the ERC20 token contract where the deposit is accounted.
    /// @param _release_at The timestap after which the withdrawer can withdraw the deposit.
    /// @param _withdrawer The address that can withdraw the deposit after the release time.
    constructor(address _token, uint256 _release_at, address _withdrawer) public {
        token = Token(_token);
        // Don't care even if it's in the past.
        release_at = _release_at;
        withdrawer = _withdrawer;
    }

    // In order to make a deposit, transfer the ERC20 token into this contract.
    // If you transfer a wrong kind of ERC20 token or ETH into this contract,
    // these tokens will be lost forever.

    /// @notice Withdraws the tokens that have been deposited.
    /// Only `withdrawer` can call this.
    /// @param _to The address where the withdrawn tokens should go.
    function withdraw(address payable _to) external {
        uint256 balance = token.balanceOf(address(this));
        require(msg.sender == withdrawer, "the caller is not the withdrawer");
        require(now >= release_at, "deposit not released yet");
        require(balance > 0, "nothing to withdraw");
        require(token.transfer(_to, balance), "token didn't transfer");
        selfdestruct(_to); // The contract can disappear.
    }
}


contract ServiceRegistryConfigurableParameters {
    address public controller;

    modifier onlyController() {
        require(msg.sender == controller);
        _;
    }

    // After a price is set to set_price at timestamp set_price_at,
    // the price decays according to decayed_price().
    uint256 public set_price;
    uint256 public set_price_at;

    /// The amount of time (in seconds) till the price decreases to roughly 1/e.
    uint256 public decay_constant = 200 days;

    // Once the price is at min_price, it can't decay further.
    uint256 public min_price = 1000;

    // Whenever a deposit comes in, the price is multiplied by numerator / denominator.
    uint256 public price_bump_numerator = 1;
    uint256 public price_bump_denominator = 1;

    // The duration of service registration/extension in seconds
    uint256 public registration_duration = 180 days;

    // If true, new deposits are no longer accepted.
    bool public deprecation_switch = false;

    function set_deprecation_switch() public onlyController returns (bool _success) {
        deprecation_switch = true;
        return true;
    }

    function change_parameters(
            uint256 _price_bump_numerator,
            uint256 _price_bump_denominator,
            uint256 _decay_constant,
            uint256 _min_price,
            uint256 _registration_duration
    ) public onlyController returns (bool _success) {
        change_parameters_internal(
            _price_bump_numerator,
            _price_bump_denominator,
            _decay_constant,
            _min_price,
            _registration_duration
        );
        return true;
    }

    function change_parameters_internal(
            uint256 _price_bump_numerator,
            uint256 _price_bump_denominator,
            uint256 _decay_constant,
            uint256 _min_price,
            uint256 _registration_duration
    ) internal {
        refresh_price();
        set_price_bump_parameters(_price_bump_numerator, _price_bump_denominator);
        set_min_price(_min_price);
        set_decay_constant(_decay_constant);
        set_registration_duration(_registration_duration);
    }

    // Updates set_price to be current_price() and set_price_at to be now
    function refresh_price() private {
        set_price = current_price();
        set_price_at = now;
    }

    function set_price_bump_parameters(
            uint256 _price_bump_numerator,
            uint256 _price_bump_denominator
    ) private {
        require(_price_bump_denominator > 0, "divide by zero");
        require(_price_bump_numerator >= _price_bump_denominator, "price dump instead of bump");
        require(_price_bump_numerator < 2 ** 40, "price dump numerator is too big");
        price_bump_numerator = _price_bump_numerator;
        price_bump_denominator = _price_bump_denominator;
    }

    function set_min_price(uint256 _min_price) private {
        // No checks.  Even allowing zero.
        min_price = _min_price;
        // No checks or modifications on set_price.
        // Even if set_price is smaller than min_price, current_price() function returns min_price.
    }

    function set_decay_constant(uint256 _decay_constant) private {
        require(_decay_constant > 0, "attempt to set zero decay constant");
        require(_decay_constant < 2 ** 40, "too big decay constant");
        decay_constant = _decay_constant;
    }

    function set_registration_duration(uint256 _registration_duration) private {
        // No checks.  Even allowing zero (when no new registrations are possible).
        registration_duration = _registration_duration;
    }


    /// @notice The amount to deposit for registration or extension.
    /// Note: the price moves quickly depending on what other addresses do.
    /// The current price might change after you send a `deposit()` transaction
    /// before the transaction is executed.
    function current_price() public view returns (uint256) {
        require(now >= set_price_at, "An underflow in price computation");
        uint256 seconds_passed = now - set_price_at;

        return decayed_price(set_price, seconds_passed);
    }


    /// @notice Calculates the decreased price after a number of seconds.
    /// @param _set_price The initial price.
    /// @param _seconds_passed The number of seconds passed since the initial
    /// price was set.
    function decayed_price(uint256 _set_price, uint256 _seconds_passed) public
        view returns (uint256) {
        // We are here trying to approximate some exponential decay.
        // exp(- X / A) where
        //   X is the number of seconds since the last price change
        //   A is the decay constant (A = 200 days corresponds to 0.5% decrease per day)

        // exp(- X / A) ~~ P / Q where
        //   P = 24 A^4
        //   Q = 24 A^4 + 24 A^3X + 12 A^2X^2 + 4 AX^3 + X^4
        // Note: swap P and Q, and then think about the Taylor expansion.

        uint256 X = _seconds_passed;

        if (X >= 2 ** 40) { // The computation below overflows.
            return min_price;
        }

        uint256 A = decay_constant;

        uint256 P = 24 * (A ** 4);
        uint256 Q = P + 24*(A**3)*X + 12*(A**2)*(X**2) + 4*A*(X**3) + X**4;

        // The multiplication below is not supposed to overflow because
        // _set_price should be at most 2 ** 90 and
        // P should be at most 24 * (2 ** 40).
        uint256 price = _set_price * P / Q;

        // Not allowing a price smaller than min_price.
        // Once it's too low it's too low forever.
        if (price < min_price) {
            price = min_price;
        }
        return price;
    }
}


contract ServiceRegistry is Utils, ServiceRegistryConfigurableParameters {
    Token public token;

    mapping(address => uint256) public service_valid_till;
    mapping(address => string) public urls;  // URLs of services for HTTP access

    // @param service The address of the registered service provider
    // @param valid_till The timestamp of the moment when the registration expires
    // @param deposit_amount The amount of deposit transferred
    // @param deposit The address of Deposit instance where the deposit is stored.
    event RegisteredService(address indexed service, uint256 valid_till, uint256 deposit_amount, Deposit deposit_contract);

    // @param _token_for_registration The address of the ERC20 token contract that services use for registration fees
    constructor(
            address _token_for_registration,
            address _controller,
            uint256 _initial_price,
            uint256 _price_bump_numerator,
            uint256 _price_bump_denominator,
            uint256 _decay_constant,
            uint256 _min_price,
            uint256 _registration_duration
    ) public {
        require(_token_for_registration != address(0x0), "token at address zero");
        require(contractExists(_token_for_registration), "token has no code");
        require(_initial_price >= min_price, "initial price too low");
        require(_initial_price <= 2 ** 90, "intiial price too high");

        token = Token(_token_for_registration);
        // Check if the contract is indeed a token contract
        require(token.totalSupply() > 0, "total supply zero");
        controller = _controller;

        // Set up the price and the set price timestamp
        set_price = _initial_price;
        set_price_at = now;

        // Set the parameters
        change_parameters_internal(_price_bump_numerator, _price_bump_denominator, _decay_constant, _min_price, _registration_duration);
    }

    // @notice Locks tokens and registers a service or extends the registration.
    // @param _limit_amount The biggest amount of tokens that the caller is willing to deposit.
    // The call fails if the current price is higher (this is always possible
    // when other parties have just called `deposit()`).
    function deposit(uint _limit_amount) public returns (bool _success) {
        require(! deprecation_switch, "this contract was deprecated");

        uint256 amount = current_price();
        require(_limit_amount >= amount, "not enough limit");

        // Extend the service position.
        uint256 valid_till = service_valid_till[msg.sender];
        if (valid_till < now) { // a first time joiner or an expired service.
            valid_till = now;
        }
        // Check against overflow.
        require(valid_till < valid_till + registration_duration, "overflow during extending the registration");
        valid_till = valid_till + registration_duration;
        assert(valid_till > service_valid_till[msg.sender]);
        service_valid_till[msg.sender] = valid_till;

        // Record the price
        set_price = amount * price_bump_numerator / price_bump_denominator;
        if (set_price > 2 ** 90) {
            set_price = 2 ** 90; // Preventing overflows.
        }
        set_price_at = now;

        // Move the deposit in a new Deposit contract.
        Deposit depo = new Deposit(address(token), valid_till, msg.sender);
        require(token.transferFrom(msg.sender, address(depo), amount), "Token transfer for deposit failed");

        // Fire event
        emit RegisteredService(msg.sender, valid_till, amount, depo);

        return true;
    }

    /// @notice Sets the URL used to access a service via HTTP.
    /// Only a currently registered service can call this successfully.
    /// @param new_url The new URL string to be stored.
    function setURL(string memory new_url) public returns (bool _success)  {
        require(now < service_valid_till[msg.sender], "registration expired");
        require(bytes(new_url).length != 0, "new url is empty string");
        urls[msg.sender] = new_url;
        return true;
    }
}


// MIT License

// Copyright (c) 2018

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
