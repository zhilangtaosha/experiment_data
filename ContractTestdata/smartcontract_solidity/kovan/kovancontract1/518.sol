/**
 *Submitted for verification at Etherscan.io on 2019-01-21
*/

pragma solidity ^0.4.25;


/** @title IArbitrable
 *  Arbitrable interface.
 *  When developing arbitrable contracts, we need to:
 *  -Define the action taken when a ruling is received by the contract. We should do so in executeRuling.
 *  -Allow dispute creation. For this a function must:
 *      -Call arbitrator.createDispute.value(_fee)(_choices,_extraData);
 *      -Create the event Dispute(_arbitrator,_disputeID,_rulingOptions);
 */
interface IArbitrable {
    /** @dev To be emmited when meta-evidence is submitted.
     *  @param _metaEvidenceID Unique identifier of meta-evidence.
     *  @param _evidence A link to the meta-evidence JSON.
     */
    event MetaEvidence(uint indexed _metaEvidenceID, string _evidence);

    /** @dev To be emmited when a dispute is created to link the correct meta-evidence to the disputeID
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _metaEvidenceID Unique identifier of meta-evidence.
     */
    event Dispute(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _metaEvidenceID);

    /** @dev To be raised when evidence are submitted. Should point to the ressource (evidences are not to be stored on chain due to gas considerations).
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _party The address of the party submiting the evidence. Note that 0x0 refers to evidence not submitted by any party.
     *  @param _evidence A URI to the evidence JSON file whose name should be its keccak256 hash followed by .json.
     */
    event Evidence(Arbitrator indexed _arbitrator, uint indexed _disputeID, address indexed _party, string _evidence);

    /** @dev To be raised when a ruling is given.
     *  @param _arbitrator The arbitrator giving the ruling.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling The ruling which was given.
     */
    event Ruling(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _ruling);

    /** @dev Give a ruling for a dispute. Must be called by the arbitrator.
     *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint _disputeID, uint _ruling) public;
}


/** @title Arbitrable
 *  Arbitrable abstract contract.
 *  When developing arbitrable contracts, we need to:
 *  -Define the action taken when a ruling is received by the contract. We should do so in executeRuling.
 *  -Allow dispute creation. For this a function must:
 *      -Call arbitrator.createDispute.value(_fee)(_choices,_extraData);
 *      -Create the event Dispute(_arbitrator,_disputeID,_rulingOptions);
 */
contract Arbitrable is IArbitrable {
    Arbitrator public arbitrator;
    bytes public arbitratorExtraData; // Extra data to require particular dispute and appeal behaviour.

    modifier onlyArbitrator {require(msg.sender == address(arbitrator), "Can only be called by the arbitrator."); _;}

    /** @dev Constructor. Choose the arbitrator.
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _arbitratorExtraData Extra data for the arbitrator.
     */
    constructor(Arbitrator _arbitrator, bytes _arbitratorExtraData) public {
        arbitrator = _arbitrator;
        arbitratorExtraData = _arbitratorExtraData;
    }

    /** @dev Give a ruling for a dispute. Must be called by the arbitrator.
     *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint _disputeID, uint _ruling) public onlyArbitrator {
        emit Ruling(Arbitrator(msg.sender),_disputeID,_ruling);

        executeRuling(_disputeID,_ruling);
    }


    /** @dev Execute a ruling of a dispute.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function executeRuling(uint _disputeID, uint _ruling) internal;
}


/** @title Arbitrator
 *  Arbitrator abstract contract.
 *  When developing arbitrator contracts we need to:
 *  -Define the functions for dispute creation (createDispute) and appeal (appeal). Don't forget to store the arbitrated contract and the disputeID (which should be unique, use nbDisputes).
 *  -Define the functions for cost display (arbitrationCost and appealCost).
 *  -Allow giving rulings. For this a function must call arbitrable.rule(disputeID,ruling).
 */
contract Arbitrator{

    enum DisputeStatus {Waiting, Appealable, Solved}

    modifier requireArbitrationFee(bytes _extraData) {
        require(msg.value >= arbitrationCost(_extraData), "Not enough ETH to cover arbitration costs.");
        _;
    }
    modifier requireAppealFee(uint _disputeID, bytes _extraData) {
        require(msg.value >= appealCost(_disputeID, _extraData), "Not enough ETH to cover appeal costs.");
        _;
    }

    /** @dev To be raised when a dispute is created.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(uint indexed _disputeID, Arbitrable indexed _arbitrable);

    /** @dev To be raised when a dispute can be appealed.
     *  @param _disputeID ID of the dispute.
     */
    event AppealPossible(uint indexed _disputeID, Arbitrable indexed _arbitrable);

    /** @dev To be raised when the current ruling is appealed.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event AppealDecision(uint indexed _disputeID, Arbitrable indexed _arbitrable);

    /** @dev Create a dispute. Must be called by the arbitrable contract.
     *  Must be paid at least arbitrationCost(_extraData).
     *  @param _choices Amount of choices the arbitrator can make in this dispute.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return disputeID ID of the dispute created.
     */
    function createDispute(uint _choices, bytes _extraData) public requireArbitrationFee(_extraData) payable returns(uint disputeID) {}

    /** @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return fee Amount to be paid.
     */
    function arbitrationCost(bytes _extraData) public view returns(uint fee);

    /** @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give extra info on the appeal.
     */
    function appeal(uint _disputeID, bytes _extraData) public requireAppealFee(_disputeID,_extraData) payable {
        emit AppealDecision(_disputeID, Arbitrable(msg.sender));
    }

    /** @dev Compute the cost of appeal. It is recommended not to increase it often, as it can be higly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return fee Amount to be paid.
     */
    function appealCost(uint _disputeID, bytes _extraData) public view returns(uint fee);

    /** @dev Compute the start and end of the dispute's current or next appeal period, if possible.
     *  @param _disputeID ID of the dispute.
     *  @return The start and end of the period.
     */
    function appealPeriod(uint _disputeID) public view returns(uint start, uint end) {}

    /** @dev Return the status of a dispute.
     *  @param _disputeID ID of the dispute to rule.
     *  @return status The status of the dispute.
     */
    function disputeStatus(uint _disputeID) public view returns(DisputeStatus status);

    /** @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     *  @param _disputeID ID of the dispute.
     *  @return ruling The ruling which has been given or the one which will be given if there is no appeal.
     */
    function currentRuling(uint _disputeID) public view returns(uint ruling);
}


/**
 *  @title Permission Interface
 *  This is a permission interface for arbitrary values. The values can be cast to the required types.
 */
interface PermissionInterface{
    /* External */

    /**
     *  @dev Return true if the value is allowed.
     *  @param _value The value we want to check.
     *  @return allowed True if the value is allowed, false otherwise.
     */
    function isPermitted(bytes32 _value) external view returns (bool allowed);
}


/**
 * @title CappedMath
 * @dev Math operations with caps for under and overflow.
 */
library CappedMath {
    uint constant private UINT_MAX = 2**256 - 1;

    /**
    * @dev Adds two unsigned integers, returns 2^256 - 1 on overflow.
    */
    function addCap(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint c = _a + _b;
        return c >= _a ? c : UINT_MAX;
    }

    /**
    * @dev Multiplies two unsigned integers, returns 2^256 - 1 on overflow.
    */
    function mulCap(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring '_a' not being zero, but the
        // benefit is lost if '_b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0)
            return 0;

        uint256 c = _a * _b;
        return c / _a == _b ? c : UINT_MAX;
    }
}


/**
 *  @title ArbitrableTokenList
 *  This contract is arbitrable token curated list for tokens, sometimes referred to as a Token² Curated List. Users can send requests to register or remove tokens from the list which can, in turn, be challenged by parties that disagree with the request.
 *  A crowdsourced insurance system allows parties to contribute to arbitration fees and win rewards if the side they backed ultimatly wins a dispute.
 */
contract ArbitrableTokenList is PermissionInterface, Arbitrable {
    using CappedMath for uint;
    /* solium-disable max-len*/
    /* solium-disable operator-whitespace*/

    /* Enums */

    enum TokenStatus {
        Absent, // The token is not on the list.
        Registered, // The token is on the list.
        RegistrationRequested, // The token has a request to be added to the list.
        ClearingRequested // The token has a request to be removed from the list.
    }

    enum RulingOption {
        Other, // Arbitrator did not rule or refused to rule.
        Accept, // Execute request. Rule in favor of requester.
        Refuse // Refuse request. Rule in favor of challenger.
    }

    enum Party {
        None,
        Requester, // Party that placed a request to change a token status.
        Challenger // Party challenging a request.
    }

    // ************************ //
    // *  Request Life Cycle  * //
    // ************************ //
    // Changes to the token status are made via requests for either listing or removing a token from the Token² Curated List.
    // The total cost a request vary depending on whether a party challenges that request and on the number of appeals.
    // To place or challenge a request, a party must place value at stake. This value will rewarded to the party that ultimatly wins the dispute. If no one challenges the request, the value will be reimbursed to the requester.
    // Additionally to the challenge reward, in the case a party challenges a request, both sides must fully pay the amount of arbitration fees required to raise a dispute. The party that ultimatly wins the case will be reimbursed.
    // Finally, arbitration fees can be crowdsourced. To incentivise insurers, an additional value must placed at stake. Contributors that fund the side that ultimatly win a dispute will be reimbursed and rewarded with the other side's fee stake proportinally to their contribution.
    // In summary, costs for placing or challenging a request are the following:
    // - A challenge reward given to the party that wins a potential dispute.
    // - Arbitration fees used to pay jurors.
    // - Fee stake that is distributed among contributors of the side that ultimatly wins a dispute.

    /* Structs */
    struct Token {
        string name; // The token name (e.g. Pinakion).
        string ticker; // The token ticker (e.g. PNK).
        address addr; // The Ethereum address of the token, if it is running on an EVM based network.
        string symbolMultihash; // The multihash of the token symbol.
        string networkID; // The ID of the network. Can be used for listing tokens from other blockchains. 'ETH' if the token is deployed on the Ethereum mainnet.
        TokenStatus status;
        Request[] requests; // List of status change requests made for the token.
    }

    // Arrays of that have 3 elements to map with the Party enum for better readability:
    // - 0 is unused, matches Party.None.
    // - 1 for Party.Requester.
    // - 2 for Party.Challenger.
    struct Request {
        bool disputed; // True if a dispute was raised.
        uint disputeID; // ID of the dispute, if any.
        uint submissionTime; // Time when the request was made. Used to track when the challenge period ends.
        uint challengeRewardBalance; // The summation of requester's and challenger's deposit. This value will be given to the party that ultimatly wins a potential dispute, or be reimbursed to the requester if no one challenges.
        uint challengerDepositTime; // The time when a challenger placed his deposit. Used to track when the request left the challenge period and entered the arbitration fees funding period.
        uint feeRewards; // Summation of reimbursable fees and stake rewards available to the parties that made contributions to the side that ultimatly wins a dispute.
        bool resolved; // True if the request was executed and/or any disputes raised were resolved.
        address[3] parties; // Address of requester and challenger, if any.
        Round[] rounds; // Tracks each round of a dispute.
        mapping(address => uint[3]) contributions; // Maps contributors to their contributions for each side, if any.
        uint[3] totalContributed; // The total amount contributed for each side. Used for calculating rewards.
    }

    struct Round {
        bool appealed; // True if this round was appealed.
        uint oldWinnerTotalCost; // Governance changes on the second half of the appeal funding period create a difference between the amount that must be contributed by the winner and the loser. This variable tracks the amount that was required of the winner in the first round, before a change that happened on the second half of the funding period. It is used to calculate the amount that must be paid by the winner to fully fund his side, which is max(old total cost, new appeal cost).
        uint[3] paidFees; // Tracks the fees paid by each side on this round.
        uint[3] requiredForSide; // The total amount required to fully fund each side. It is the summation of the dispute or appeal cost and the fee stake. The fourth element is used to track whether the required value for each side has been set, with 1 for true and 0 for false.
        bool requiredForSideSet; // Tracks if the required amount has been set. False if no one made any contributions after the arbitrator gave a ruling.
    }

    /* Modifiers */

    modifier onlyGovernor {require(msg.sender == governor, "The caller is not the governor."); _;}

    /* Events */

    /**
     *  @dev Emitted when a party places a request, dispute or appeals are raised or when a request is resolved.
     *  @param _requester Address of the party that submitted the request.
     *  @param _challenger Address of the party that challenged the request, if any.
     *  @param _tokenID The token ID. It is the keccak256 hash of it's data.
     *  @param _status The status of the token.
     *  @param _disputed Whether the token is disputed.
     */
    event TokenStatusChange(
        address indexed _requester,
        address indexed _challenger,
        bytes32 indexed _tokenID,
        TokenStatus _status,
        bool _disputed
    );

    /** @dev Emitted when a party makes contribution.
     *  @param _tokenID The ID of the token that the contribution was made to.
     *  @param _contributor The address that sent the contribution.
     *  @param _side The side the contribution was made to.
     *  @param _value The value of the contribution.
     */
    event Contribution(bytes32 indexed _tokenID, address indexed _contributor, Party indexed _side, uint _value);

    /** @dev Emitted when a deposit is made to challenge a request.
     *  @param _tokenID The ID of the token that with the challenged request.
     *  @param _challenger The address that placed the deposit.
     */
    event ChallengeDepositPlaced(bytes32 indexed _tokenID, address indexed _challenger);

    /** @dev Emitted when a reimbursements and/or contribution rewards are withdrawn.
     *  @param _tokenID The ID of the token from which the withdrawal was made.
     *  @param _request The request from which the withdrawal was made.
     *  @param _contributor The address that sent the contribution.
     *  @param _value The value of the reward.
     */
    event RewardWithdrawal(bytes32 indexed _tokenID, uint indexed _request, address indexed _contributor, uint _value);

    /* Storage */

    // Settings
    uint public challengeReward; // The deposit required for placing and/or challenging a request. A party that wins a disputed request will be reimbursed and will receive the other's deposit.
    uint public challengePeriodDuration; // The time before a request becomes executable if not challenged.
    uint public arbitrationFeesWaitingTime; // The time available to fund arbitration fees and fee stake for a potential dispute.
    address public governor; // The address that can make governance changes to the parameters of the Token² Curated List.

    // The required fee stake that a party must pay depends on who won the previous round and is proportional to the arbitration cost such that the fee stake for a round is stake multiplier * arbitration cost for that round.
    // The value is the percentage in 2 digits precision (e.g. a multiplier of 5000 results the fee stake being 50% of the arbitration cost for that round).
    uint public winnerStakeMultiplier; // Multiplier for calculating the fee stake paid by the party that won the previous round.
    uint public loserStakeMultiplier; // Multiplier for calculating the fee stake paid by the party that lost the previous round.
    uint public sharedStakeMultiplier; // Multiplier for calculating the fee stake that be must paid in the case where the previous round does not have a winner (e.g. when it's the first round or the arbitrator ruled refused to rule/could not rule).
    uint public constant MULTIPLIER_PRECISION = 10000; // Precision parameter for multipliers.

    // Registry data.
    mapping(bytes32 => Token) public tokens; // Maps the token ID to the token data.
    mapping(uint => bytes32) public disputeIDToTokenID; // Maps a dispute ID to the affected token's ID.
    bytes32[] public tokensList; // List of IDs of submitted tokens.

    // Token list
    mapping(address => bytes32[]) public addressToSubmissions; // Maps addresses to submitted token IDs.

    /* Constructor */

    /**
     *  @dev Constructs the arbitrable token curated list.
     *  @param _arbitrator The chosen arbitrator.
     *  @param _arbitratorExtraData Extra data for the arbitrator contract.
     *  @param _metaEvidence The URI of the meta evidence object.
     *  @param _governor The governor of this contract.
     *  @param _arbitrationFeesWaitingTime The maximum time to wait for arbitration fees if the dispute is raised.
     *  @param _challengeReward The amount in weis required to submit or a challenge a request.
     *  @param _challengePeriodDuration The time in seconds, parties have to challenge a request.
     *  @param _sharedStakeMultiplier Percentage of the arbitration cost that each party must pay as fee stake for a round when there isn't a winner/loser in the previous round (e.g. when it's the first round or the arbitrator refused to or did not rule). Value in 2 digits precision (e.g. 2500 results in 25% of the arbitration cost value of that round).
     *  @param _winnerStakeMultiplier Percentage of the arbitration cost that the winner has to pay as fee stake for a round. Value in 2 digits precision (e.g. 5000 results in 50% of the arbitration cost value of that round).
     *  @param _loserStakeMultiplier Percentage of the arbitration cost that the loser has to pay as fee stake for a round. Value in 2 digits precision (e.g. 10000 results in 100% of the arbitration cost value of that round).
     */
    constructor(
        Arbitrator _arbitrator,
        bytes _arbitratorExtraData,
        string _metaEvidence,
        address _governor,
        uint _arbitrationFeesWaitingTime,
        uint _challengeReward,
        uint _challengePeriodDuration,
        uint _sharedStakeMultiplier,
        uint _winnerStakeMultiplier,
        uint _loserStakeMultiplier
    ) Arbitrable(_arbitrator, _arbitratorExtraData) public {
        emit MetaEvidence(0, _metaEvidence);
        governor = _governor;
        arbitrationFeesWaitingTime = _arbitrationFeesWaitingTime;
        challengeReward = _challengeReward;
        challengePeriodDuration = _challengePeriodDuration;
        sharedStakeMultiplier = _sharedStakeMultiplier;
        winnerStakeMultiplier = _winnerStakeMultiplier;
        loserStakeMultiplier = _loserStakeMultiplier;
    }

    /* Public */

    // ************************ //
    // *       Requests       * //
    // ************************ //

    /** @dev Submit a request to change a token status. Accepts enough ETH to fund a potential dispute considering the current required amount and reimburses the rest.
     *  @param _name The token name (e.g. Pinakion).
     *  @param _ticker The token ticker (e.g. PNK).
     *  @param _addr The Ethereum address of the token, if it is running on an EVM based network.
     *  @param _symbolMultihash The multihash of the token symbol.
     *  @param _networkID The ID of the network. Can be used for listing tokens from other blockchains. 'ETH' if the token is on the Ethereum mainnet.
     */
    function requestStatusChange(
        string _name,
        string _ticker,
        address _addr,
        string _symbolMultihash,
        string _networkID
    )
        external
        payable
    {
        require(msg.value >= challengeReward, "Not enough ETH.");
        bytes32 tokenID = keccak256(
            abi.encodePacked(
                _name,
                _ticker,
                _addr,
                _symbolMultihash,
                _networkID
            )
        );

        Token storage token = tokens[tokenID];
        if (token.requests.length == 0) {
            // Initial token registration
            token.name = _name;
            token.ticker = _ticker;
            token.addr = _addr;
            token.symbolMultihash = _symbolMultihash;
            token.networkID = _networkID;
            tokensList.push(tokenID);
            addressToSubmissions[_addr].push(tokenID);
        }

        // Update token status.
        if (token.status == TokenStatus.Absent)
            token.status = TokenStatus.RegistrationRequested;
        else if (token.status == TokenStatus.Registered)
            token.status = TokenStatus.ClearingRequested;
        else
            revert("Token in wrong status for request.");

        // Setup request.
        token.requests.length++;
        Request storage request = token.requests[token.requests.length - 1];
        request.parties[uint(Party.Requester)] = msg.sender;
        request.submissionTime = now;
        request.rounds.length++;
        request.challengeRewardBalance = challengeReward;

        // Calculate and save the total amount required to fully fund the each side.
        Round storage round = request.rounds[request.rounds.length - 1];
        round.requiredForSide = calculateRequiredForSide(tokenID, round.oldWinnerTotalCost, round.requiredForSideSet);
        round.requiredForSideSet = true;

        // Take up to the amount necessary to fund the current round at the current costs.
        uint contribution;
        uint remainingETH = msg.value - challengeReward;
        (contribution, remainingETH) = calculateContribution(remainingETH, round.requiredForSide[uint(Party.Requester)]);
        request.contributions[msg.sender][uint(Party.Requester)] = contribution;
        request.totalContributed[uint(Party.Requester)] = contribution;
        round.paidFees[uint(Party.Requester)] = contribution;
        request.feeRewards += contribution;
        if (contribution > 0)
            emit Contribution(tokenID, msg.sender, Party.Requester, contribution);

        // Reimburse leftover ETH.
        msg.sender.send(remainingETH); // Deliberate use of send in order to not block the contract in case of reverting fallback.

        emit TokenStatusChange(
            request.parties[uint(Party.Requester)],
            address(0x0),
            tokenID,
            token.status,
            false
        );
    }

    /** @dev Challenges the latest request of a token. Accepts enough ETH to fund a potential dispute considering the current required amount and reimburses the rest.
     *  @param _tokenID The tokenID of the token with the request to execute.
     */
    function challengeRequest(bytes32 _tokenID) external payable {
        Token storage token = tokens[_tokenID];
        require(
            token.status == TokenStatus.RegistrationRequested || token.status == TokenStatus.ClearingRequested,
            "Token does not have any pending requests."
        );
        Request storage request = token.requests[token.requests.length - 1];
        require(now - request.submissionTime < challengePeriodDuration, "The challenge period has already passed.");
        require(request.challengerDepositTime == 0, "Request should have only the requester's deposit.");
        require(msg.value >= request.challengeRewardBalance, "Not enough ETH. Party starting dispute must place a deposit in full.");

        // Take the deposit and save the challenger's address.
        uint remainingETH = msg.value - request.challengeRewardBalance;
        request.challengeRewardBalance += request.challengeRewardBalance;
        request.parties[uint(Party.Challenger)] = msg.sender;
        request.challengerDepositTime = now; // Save the start of the first round arbitration fees funding period.
        emit ChallengeDepositPlaced(_tokenID, msg.sender);

        // Calculate and save the total amount required to fully fund the each side.
        Round storage round = request.rounds[request.rounds.length - 1];
        round.requiredForSide = calculateRequiredForSide(_tokenID, round.oldWinnerTotalCost, round.requiredForSideSet);
        round.requiredForSideSet = true;

        // Take up to the amount necessary to fund the current round at the current costs.
        uint contribution;
        (contribution, remainingETH) = calculateContribution(remainingETH, round.requiredForSide[uint(Party.Challenger)]);
        request.contributions[msg.sender][uint(Party.Challenger)] = contribution;
        request.totalContributed[uint(Party.Challenger)] = contribution;
        round.paidFees[uint(Party.Challenger)] = contribution;
        request.feeRewards += contribution;
        if (contribution > 0)
            emit Contribution(_tokenID, msg.sender, Party.Challenger, contribution);

        // Reimburse leftover ETH.
        msg.sender.send(remainingETH); // Deliberate use of send in order to not block the contract in case of reverting fallback.

        // Raise dispute if both sides are fully funded.
        if (round.paidFees[uint(Party.Requester)] >= round.requiredForSide[uint(Party.Requester)] &&
            round.paidFees[uint(Party.Challenger)] >= round.requiredForSide[uint(Party.Challenger)]) {

            uint arbitrationCost = arbitrator.arbitrationCost(arbitratorExtraData);
            request.disputeID = arbitrator.createDispute.value(arbitrationCost)(2, arbitratorExtraData);
            disputeIDToTokenID[request.disputeID] = _tokenID;
            request.disputed = true;

            request.rounds.length++;
            request.feeRewards -= arbitrationCost;
        }

        emit TokenStatusChange(
            request.parties[uint(Party.Requester)],
            request.parties[uint(Party.Challenger)],
            _tokenID,
            token.status,
            request.disputed
        );
    }

    /** @dev Takes up to the total required to fund a side of the latest round, reimburses the rest.
     *  @param _tokenID The IDtIDokenID of the token with the request to execute.
     *  @param _side The recipient of the contribution.
     */
    function fundLatestRound(bytes32 _tokenID, Party _side) external payable {
        require(
            _side == Party.Requester || _side == Party.Challenger,
            "Side must be either the requester or challenger."
        );
        Token storage token = tokens[_tokenID];
        require(
            token.status == TokenStatus.RegistrationRequested || token.status == TokenStatus.ClearingRequested,
            "Token does not have any pending requests."
        );
        Request storage request = token.requests[token.requests.length - 1];
        require(request.challengerDepositTime > 0, "A party must have placed a deposit.");

        // Calculate and save the total amount required to fully fund the each side.
        Round storage round = request.rounds[request.rounds.length - 1];
        round.requiredForSide = calculateRequiredForSide(_tokenID, round.oldWinnerTotalCost, round.requiredForSideSet);
        round.requiredForSideSet = true;

        // Check if the contribution is within time restrictions, if there are any.
        Party loser;
        if(!request.disputed && request.challengerDepositTime > 0) { // First round.
            require(
                now - request.challengerDepositTime < arbitrationFeesWaitingTime,
                "The arbitration fees funding period of the first round has already passed."
            );
        } else { // Later round.
            (uint appealPeriodStart, uint appealPeriodEnd) = arbitrator.appealPeriod(request.disputeID);
            if(appealPeriodEnd > appealPeriodStart && RulingOption(arbitrator.currentRuling(request.disputeID)) != RulingOption.Other) {
                // Appeal period is known and there is a winner and loser.
                // Contributions are time restricted to the first half if the beneficiary is the loser.
                if(RulingOption(arbitrator.currentRuling(request.disputeID)) == RulingOption.Refuse)
                    loser = Party.Requester;
                else
                    loser = Party.Challenger;

                // The losing side must fully fund in the first half of the appeal period.
                if(_side == loser)
                    require(
                        now - appealPeriodStart < (appealPeriodEnd - appealPeriodStart) / 2,
                        "Appeal period for funding the losing side ended."
                    );
                else {
                    require(now < appealPeriodEnd, "Appeal period ended."); // Winner can only receive contributions in the appeal period.
                    // Beneficiary is the winning side.
                    // If in the first half of the appeal period, update the old total cost to the winner.
                    // This is required to calculate the amount the winner has to pay when governance changes are made in the second half of the appeal period.
                    if (now - appealPeriodStart < (appealPeriodEnd - appealPeriodStart) / 2) // First half of appeal period.
                        round.oldWinnerTotalCost = round.requiredForSide[uint(_side)];
                }
            }
        }

        // Take only the necessary ETH.
        uint contribution;
        uint remainingETH = msg.value;
        uint amountStillRequired = round.requiredForSide[uint(_side)] - round.paidFees[uint(_side)];
        (contribution, remainingETH) = calculateContribution(remainingETH, amountStillRequired);
        request.contributions[msg.sender][uint(_side)] += contribution;
        request.totalContributed[uint(_side)] += contribution;
        round.paidFees[uint(_side)] += contribution;
        request.feeRewards += contribution;
        if (contribution > 0)
            emit Contribution(_tokenID, msg.sender, _side, contribution);

        // Reimburse leftover ETH.
        msg.sender.send(remainingETH); // Deliberate use of send in order to not block the contract in case of reverting fallback.

        // Raise dispute or appeal if both sides are fully funded.
        if (round.paidFees[uint(Party.Requester)] >= round.requiredForSide[uint(Party.Requester)] &&
            round.paidFees[uint(Party.Challenger)] >= round.requiredForSide[uint(Party.Challenger)]) {

            uint cost = !request.disputed // First round.
                ? arbitrator.arbitrationCost(arbitratorExtraData)
                : arbitrator.appealCost(request.disputeID, arbitratorExtraData);

            if(!request.disputed) {
                // First round, raise dispute.
                request.disputeID = arbitrator.createDispute.value(cost)(2, arbitratorExtraData);
                disputeIDToTokenID[request.disputeID] = _tokenID;
                request.disputed = true;
            } else {
                // Later round, raise an appeal.
                arbitrator.appeal.value(cost)(request.disputeID, arbitratorExtraData);
                round.appealed = true;
            }

            request.rounds.length++;
            request.feeRewards -= cost;

            emit TokenStatusChange(
                request.parties[uint(Party.Requester)],
                request.parties[uint(Party.Challenger)],
                _tokenID,
                token.status,
                request.disputed
            );
        }
    }

    /** @dev Reimburses caller's contributions if no disputes were raised. If a dispute was raised,  withdraws the rewards and reimbursements proportional to the contribtutions made to the winner of a dispute.
     *  @param _tokenID The ID of the token from which to withdraw.
     *  @param _request The request from which to withdraw.
     */
    function withdrawFeesAndRewards(bytes32 _tokenID, uint _request) external {
        Token storage token = tokens[_tokenID];
        Request storage request = token.requests[_request];
        require(
            request.resolved,
            "The request was not executed and/or there are disputes pending resolution."
        );

        uint reward;
        if (!request.disputed || RulingOption(arbitrator.currentRuling(request.disputeID)) == RulingOption.Other) {
            // No disputes were raised, or there isn't a winner and and loser. Reimburse contributions.
            reward = request.contributions[msg.sender][uint(Party.Requester)] + request.contributions[msg.sender][uint(Party.Challenger)];
            request.contributions[msg.sender][uint(Party.Requester)] = 0;
            request.contributions[msg.sender][uint(Party.Challenger)] = 0;
        } else {
            Party winner;
            if(RulingOption(arbitrator.currentRuling(request.disputeID)) == RulingOption.Accept)
                winner = Party.Requester;
            else
                winner = Party.Challenger;

            // Take rewards for funding the winner.
            uint share = request.contributions[msg.sender][uint(winner)] * MULTIPLIER_PRECISION / request.totalContributed[uint(winner)];
            reward = (share * request.feeRewards) / MULTIPLIER_PRECISION;
            request.contributions[msg.sender][uint(winner)] = 0;
        }

        emit RewardWithdrawal(_tokenID, _request, msg.sender, reward);
        msg.sender.transfer(reward);
    }

    /** @dev Execute a request if no disputes were raised within the allowed period.
     *  @param _tokenID The ID of the token with the request to execute.
     */
    function timeout(bytes32 _tokenID) external {
        Token storage token = tokens[_tokenID];
        Request storage request = token.requests[token.requests.length - 1];
        if(request.challengerDepositTime == 0) {
            // No one placed a challenge deposit.
            require(
                now - request.submissionTime > challengePeriodDuration,
                "The time to challenge has not passed yet."
            );

            if (token.status == TokenStatus.RegistrationRequested)
                token.status = TokenStatus.Registered;
            else if (token.status == TokenStatus.ClearingRequested)
                token.status = TokenStatus.Absent;
            else
                revert("Token in wrong status for executing request.");

            // Deliberate use of send in order to not block the contract in case of reverting fallback.
            request.parties[uint(Party.Requester)].send(request.challengeRewardBalance);
        } else {
            require(!request.disputed, "A dispute must have not been raised.");
            require(
                now - request.challengerDepositTime > arbitrationFeesWaitingTime,
                "There is still time to place a contribution."
            );

            // Rule in favor of requester if he paid more or the same amount of the challenger. Rule in favor of challenger otherwise.
            Round storage round = request.rounds[request.rounds.length - 1];
            Party winner;
            if (round.paidFees[uint(Party.Requester)] >= round.paidFees[uint(Party.Challenger)])
                winner = Party.Requester;
            else
                winner = Party.Challenger;

            // Update token state
            if (winner == Party.Requester) // Execute Request
                if (token.status == TokenStatus.RegistrationRequested)
                    token.status = TokenStatus.Registered;
                else
                    token.status = TokenStatus.Absent;
            else // Revert to previous state.
                if (token.status == TokenStatus.RegistrationRequested)
                    token.status = TokenStatus.Absent;
                else if (token.status == TokenStatus.ClearingRequested)
                    token.status = TokenStatus.Registered;

            // Send token balance.
            // Deliberate use of send in order to not block the contract in case the recipient refuses payments.
            if (winner == Party.Challenger)
                request.parties[uint(Party.Challenger)].send(request.challengeRewardBalance);
            else
                request.parties[uint(Party.Requester)].send(request.challengeRewardBalance);
        }

        request.challengeRewardBalance = 0;
        request.resolved = true;

        emit TokenStatusChange(
            request.parties[uint(Party.Requester)],
            request.parties[uint(Party.Challenger)],
            _tokenID,
            token.status,
            false
        );
    }

    /** @dev Give a ruling for a dispute. Can only be called by the arbitrator.
     *  Overrides parent function to account for the situation where the winner loses a case due to paying less appeal fees than expected.
     *  @param _disputeID ID of the dispute in the arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint _disputeID, uint _ruling) public onlyArbitrator {
        Party winner;
        Party loser;
        RulingOption resultRuling = RulingOption(_ruling);
        if(resultRuling == RulingOption.Accept) {
            winner = Party.Requester;
            loser = Party.Challenger;
        } else if (resultRuling == RulingOption.Refuse) {
            winner = Party.Challenger;
            loser = Party.Requester;
        } // Respect ruling if there aren't a winner and loser.

        // Invert ruling if there are a winner and loser and the loser fully funded but the winner did not. Respect the ruling otherwise.
        bytes32 tokenID = disputeIDToTokenID[_disputeID];
        Token storage token = tokens[tokenID];
        Request storage request = token.requests[token.requests.length - 1];
        Round storage round = request.rounds[request.rounds.length - 1];
        if(resultRuling != RulingOption.Other &&
            round.paidFees[uint(loser)] >= round.requiredForSide[uint(loser)] &&
            round.requiredForSideSet) // Check that the amount required for each side has been set, if respect ruling otherwise.
        {
            // Loser is fully funded but the winner is not. Rule in favor of the loser.
            if (resultRuling == RulingOption.Accept)
                resultRuling = RulingOption.Refuse;
             else
                resultRuling = RulingOption.Accept;
        }

        emit Ruling(Arbitrator(msg.sender), _disputeID, uint(resultRuling));
        executeRuling(_disputeID, uint(resultRuling));
    }

    /** @dev Submit a reference to evidence. EVENT.
     *  @param _evidence A link to an evidence using its URI.
     */
    function submitEvidence(bytes32 _tokenID, string _evidence) external {
        Token storage token = tokens[_tokenID];
        Request storage request = token.requests[token.requests.length - 1];
        require(request.disputed, "The request is not disputed.");

        emit Evidence(arbitrator, request.disputeID, msg.sender, _evidence);
    }

    // ************************ //
    // *      Governance      * //
    // ************************ //

    /** @dev Change the duration of the challenge period.
     *  @param _challengePeriodDuration The new duration of the challenge period.
     */
    function changeTimeToChallenge(uint _challengePeriodDuration) external onlyGovernor {
        challengePeriodDuration = _challengePeriodDuration;
    }

    /** @dev Change the required deposit required to place or challenge a request.
     *  @param _challengeReward The new amount of wei required to place or challenge a request.
     */
    function changeChallengeReward(uint _challengeReward) external onlyGovernor {
        challengeReward = _challengeReward;
    }

    /** @dev Change the governor of the Token² Curated List.
     *  @param _governor The address of the new governor.
     */
    function changeGovernor(address _governor) external onlyGovernor {
        governor = _governor;
    }

    /** @dev Change duration of the arbitration fees funding period.
     *  @param _arbitrationFeesWaitingTime The new duration of the arbitration fees funding period in seconds.
     */
    function changeArbitrationFeesWaitingTime(uint _arbitrationFeesWaitingTime) external onlyGovernor {
        arbitrationFeesWaitingTime = _arbitrationFeesWaitingTime;
    }

    /** @dev Change the percentage of arbitration fees that must be paid as fee stake by parties when there wasn't a winner or loser in the previous round.
     *  @param _sharedStakeMultiplier The new percentage of arbitration fees that must be paid as fee stake with 2 digits precision (e.g. a value of 1000 will result in 10% of the arbitration fees required in that round).
     */
    function changeSharedStakeMultiplier(uint _sharedStakeMultiplier) external onlyGovernor {
        sharedStakeMultiplier = _sharedStakeMultiplier;
    }

    /** @dev Change the percentage of arbitration fees that must be paid as fee stake by winner of the previous round.
     *  @param _winnerStakeMultiplier The new percentage of arbitration fees that must be paid as fee stake with 2 digits precision (e.g. a value of 5000 will result in 50% of the arbitration fees required in that round).
     */
    function changeWinnerStakeMultiplier(uint _winnerStakeMultiplier) external onlyGovernor {
        winnerStakeMultiplier = _winnerStakeMultiplier;
    }

    /** @dev Change the percentage of arbitration fees that must be paid as fee stake by party that lost the previous round.
     *  @param _loserStakeMultiplier The new percentage of arbitration fees that must be paid as fee stake with 2 digits precision (e.g. a value of 10000 will result in 100% of the arbitration fees required in that round).
     */
    function changeLoserStakeMultiplier(uint _loserStakeMultiplier) external onlyGovernor {
        loserStakeMultiplier = _loserStakeMultiplier;
    }

    /* Public Views */

    /** @dev Return true if the token is on the list.
     *  @param _tokenID The ID of the token to be queried.
     *  @return allowed True if the token is allowed, false otherwise.
     */
    function isPermitted(bytes32 _tokenID) external view returns (bool allowed) {
        Token storage token = tokens[_tokenID];
        return token.status == TokenStatus.Registered || token.status == TokenStatus.ClearingRequested;
    }

    /* Internal */

    /**
     *  @dev Execute the ruling of a dispute.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function executeRuling(uint _disputeID, uint _ruling) internal {
        bytes32 tokenID = disputeIDToTokenID[_disputeID];
        Token storage token = tokens[tokenID];
        Request storage request = token.requests[token.requests.length - 1];

        Party winner;
        if(RulingOption(_ruling) == RulingOption.Accept)
            winner = Party.Requester;
        else if (RulingOption(_ruling) == RulingOption.Refuse)
            winner = Party.Challenger;

        // Update token state
        if (winner == Party.Requester) // Execute Request
            if (token.status == TokenStatus.RegistrationRequested)
                token.status = TokenStatus.Registered;
            else
                token.status = TokenStatus.Absent;
        else // Revert to previous state.
            if (token.status == TokenStatus.RegistrationRequested)
                token.status = TokenStatus.Absent;
            else if (token.status == TokenStatus.ClearingRequested)
                token.status = TokenStatus.Registered;

        // Send challenge reward.
        // Deliberate use of send in order to not block the contract in case of reverting fallback.
        if (winner == Party.Challenger)
            request.parties[uint(Party.Challenger)].send(request.challengeRewardBalance);
        else if (winner == Party.Requester)
            request.parties[uint(Party.Requester)].send(request.challengeRewardBalance);
        else {
            // Reimburse parties.
            request.parties[uint(Party.Requester)].send(request.challengeRewardBalance / 2);
            request.parties[uint(Party.Challenger)].send(request.challengeRewardBalance / 2);
        }

        request.challengeRewardBalance = 0;
        request.resolved = true;

        emit TokenStatusChange(
            request.parties[uint(Party.Requester)],
            request.parties[uint(Party.Challenger)],
            tokenID,
            token.status,
            false
        );
    }

    /** @dev Returns the amount that must be paid by each side to fully fund a dispute or appeal.
     *  Capped math is used to deal with overflows since the arbitrator can return high values for appeal and arbitration cost to denote unpayable amounts.
     *  @param _tokenID The dispute ID to be queried.
     *  @param _oldWinnerTotalCost The total amount of fees the winner had to pay before a governance change in the second half of an appeal period. If the appeal period is not known or the arbitrator does not support appeal period, this parameter is unused.
     *  @param _requiredForSideSet Whether the required amount for each side has been set previously.
     *  @return The amount of ETH required for each side.
     */
    function calculateRequiredForSide(bytes32 _tokenID, uint _oldWinnerTotalCost, bool _requiredForSideSet)
        internal
        view
        returns(uint[3] requiredForSide)
    {
        Token storage token = tokens[_tokenID];
        Request storage request = token.requests[token.requests.length - 1];

        if(!request.disputed) { // First round of a dispute.
            uint arbitrationCost = arbitrator.arbitrationCost(arbitratorExtraData);
            requiredForSide[uint(Party.Requester)] =
                arbitrationCost.addCap((arbitrationCost.mulCap(sharedStakeMultiplier)) / MULTIPLIER_PRECISION);
            requiredForSide[uint(Party.Challenger)] =
                arbitrationCost.addCap((arbitrationCost.mulCap(sharedStakeMultiplier)) / MULTIPLIER_PRECISION);
            return;
        }

        Party winner;
        Party loser;
        RulingOption ruling = RulingOption(arbitrator.currentRuling(request.disputeID));
        if(ruling == RulingOption.Accept) {
            winner = Party.Requester;
            loser = Party.Challenger;
        } else if (ruling == RulingOption.Refuse) {
            winner = Party.Challenger;
            loser = Party.Requester;
        }

        uint appealCost = arbitrator.appealCost(request.disputeID, arbitratorExtraData);
        if(uint(winner) > 0) {
            // Arbitrator gave a decisive ruling.
            // Set the required amount for the winner.
            requiredForSide[uint(winner)] = appealCost.addCap((appealCost.mulCap(winnerStakeMultiplier)) / MULTIPLIER_PRECISION);

            (uint appealPeriodStart, uint appealPeriodEnd) = arbitrator.appealPeriod(request.disputeID);
            if(appealPeriodEnd > appealPeriodStart){ // The appeal period is known.
                // Fee changes in the second half of the appeal period may create a difference between the amount paid by the winner and the amount paid by the loser.
                // To deal with this case, the amount that must be paid by the winner is max(old appeal cost + old winner stake, new appeal cost).
                if (now - appealPeriodStart > (appealPeriodEnd - appealPeriodStart) / 2) // In second half of appeal period.
                    requiredForSide[uint(winner)] = _oldWinnerTotalCost > appealCost ? _oldWinnerTotalCost : appealCost;

                // Set the required amount for the loser.
                if(!_requiredForSideSet)
                    requiredForSide[uint(loser)] = appealCost.addCap((appealCost.mulCap(loserStakeMultiplier)) / MULTIPLIER_PRECISION);

                // The required amount for the loser may only be updated by governance/fee changes made in the first half of the appeal period. Otherwise, increases would cause the loser to lose the case due to being underfunded.
                if (now - appealPeriodStart < (appealPeriodEnd - appealPeriodStart) / 2) // In first half of appeal period.
                    requiredForSide[uint(loser)] = appealCost.addCap((appealCost.mulCap(loserStakeMultiplier)) / MULTIPLIER_PRECISION);
            } else // Arbitration period is not known or the arbitrator does not support appeal period. Update loser's required value as well.
                requiredForSide[uint(loser)] = appealCost.addCap((appealCost.mulCap(loserStakeMultiplier)) / MULTIPLIER_PRECISION);
        } else {
            // Arbitrator did not rule or refused to rule.
            requiredForSide[uint(Party.Requester)] =
                appealCost.addCap((appealCost.mulCap(sharedStakeMultiplier)) / MULTIPLIER_PRECISION);
            requiredForSide[uint(Party.Challenger)] =
                appealCost.addCap((appealCost.mulCap(sharedStakeMultiplier)) / MULTIPLIER_PRECISION);
        }
    }

     /** @dev Returns the contribution value and remainder from available ETH and required amount.
     *  @param _available The amount of ETH available for the contribution.
     *  @param _requiredAmount The amount of ETH required for the contribution.
     *  @return The amount of ETH taken.
     *  @return The amount of ETH left from the contribution.
     */
    function calculateContribution(uint _available, uint _requiredAmount)
        internal
        pure
        returns(uint taken, uint remainder)
    {
        if (_requiredAmount > _available)
            return (_available, 0); // Take whatever is available, return 0 as leftover ETH.

        remainder = _available - _requiredAmount;
        return (_requiredAmount, remainder);
    }

    /* Interface Views */

    /** @dev Returns token information. Includes length of requests array.
     *  @param _tokenID The ID of the queried token.
     *  @return The token information.
     */
    function getTokenInfo(bytes32 _tokenID)
        external
        view
        returns (
            string name,
            string ticker,
            address addr,
            string symbolMultihash,
            string networkID,
            TokenStatus status,
            uint numberOfRequests
        )
    {
        Token storage token = tokens[_tokenID];
        return (
            token.name,
            token.ticker,
            token.addr,
            token.symbolMultihash,
            token.networkID,
            token.status,
            token.requests.length
        );
    }

    /** @dev Gets information on a request made for a token.
     *  @param _tokenID The ID of the queried token.
     *  @param _request The request to be queried.
     *  @return The information.
     */
    function getRequestInfo(bytes32 _tokenID, uint _request)
        external
        view
        returns (
            bool disputed,
            uint disputeID,
            uint submissionTime,
            uint challengeRewardBalance,
            uint challengerDepositTime,
            uint balance,
            bool resolved,
            address[3] parties,
            uint[3] totalContributed,
            uint numberOfRounds
        )
    {
        Token storage token = tokens[_tokenID];
        Request storage request = token.requests[_request];
        return (
            request.disputed,
            request.disputeID,
            request.submissionTime,
            request.challengeRewardBalance,
            request.challengerDepositTime,
            request.feeRewards,
            request.resolved,
            request.parties,
            request.totalContributed,
            request.rounds.length
        );
    }

    /** @dev Gets the information on a round of a request.
     *  @param _tokenID The ID of the queried token.
     *  @param _request The request to be queried.
     *  @param _round The round to be queried.
     *  @return The information.
     */
    function getRoundInfo(bytes32 _tokenID, uint _request, uint _round)
        external
        view
        returns (
            bool appealed,
            uint oldWinnerTotalCost,
            uint[3] paidFees,
            uint[3] requiredForSide
        )
    {
        Token storage token = tokens[_tokenID];
        Request storage request = token.requests[_request];
        Round storage round = request.rounds[_round];
        return (
            round.appealed,
            round.oldWinnerTotalCost,
            round.paidFees,
            round.requiredForSide
        );
    }

    /** @dev Gets the contributions made by a party for a given request.
     *  @param _tokenID The ID of the token.
     *  @param _request The position of the request.
     *  @param _contributor The address of the contributor.
     *  @return The contributions.
     */
    function getContributions(
        bytes32 _tokenID,
        uint _request,
        address _contributor
    ) external view returns(uint[3] contributions) {
        Token storage token = tokens[_tokenID];
        Request storage request = token.requests[_request];
        contributions = request.contributions[_contributor];
    }

    /** @dev Return the numbers of tokens that were submitted. Includes tokens that never made it to the list or were later removed.
     *  @return The numbers of tokens in the list.
     */
    function tokenCount() external view returns (uint count) {
        return tokensList.length;
    }

    /** @dev Return the numbers of tokens with each status. This function is O(n) at worst, where n is the number of tokens. This could exceed the gas limit, therefore this function should only be used for interface display and not by other contracts.
     *  @return The numbers of tokens in the list per status.
     */
    function countByStatus()
        external
        view
        returns (
            uint disputed,
            uint absent,
            uint registered,
            uint registrationRequested,
            uint clearingRequested
        )
    {
        for (uint i = 0; i < tokensList.length; i++) {
            Token storage token = tokens[tokensList[i]];
            Request storage request = token.requests[token.requests.length - 1];

            if (uint(token.status) > 1 && request.disputed) disputed++;
            if (token.status == TokenStatus.Absent) absent++;
            else if (token.status == TokenStatus.Registered) registered++;
            else if (token.status == TokenStatus.RegistrationRequested) registrationRequested++;
            else if (token.status == TokenStatus.ClearingRequested) clearingRequested++;
        }
    }

    /** @dev Return the values of the tokens the query finds. This function is O(n) at worst, where n is the number of tokens. This could exceed the gas limit, therefore this function should only be used for interface display and not by other contracts.
     *  @param _cursor The ID of the token from which to start iterating. To start from either the oldest or newest item.
     *  @param _count The number of tokens to return.
     *  @param _filter The filter to use. Each element of the array in sequence means:
     *  - Include absent tokens in result.
     *  - Include registered tokens in result.
     *  - Include tokens with registration requests that are not disputed in result.
     *  - Include tokens with clearing requests that are not disputed in result.
     *  - Include disputed tokens with registration requests in result.
     *  - Include disputed tokens with clearing requests in result.
     *  - Include tokens submitted by the caller.
     *  - Include tokens challenged by the caller.
     *  @param _oldestFirst Whether to sort from oldest to the newest item.
     *  @param _tokenAddr A token addess. If set, will query all submissions for that address.
     *  @return The values of the tokens found and whether there are more tokens for the current filter and sort.
     */
    function queryTokens(bytes32 _cursor, uint _count, bool[8] _filter, bool _oldestFirst, address _tokenAddr)
        external
        view
        returns (bytes32[] values, bool hasMore)
    {
        uint cursorIndex;
        values = new bytes32[](_count);
        uint index = 0;

        bytes32[] storage list = _tokenAddr == address(0x0)
            ? tokensList
            : addressToSubmissions[_tokenAddr];

        if (_cursor == 0)
            cursorIndex = 0;
        else {
            for (uint j = 0; j < list.length; j++) {
                if (list[j] == _cursor) {
                    cursorIndex = j;
                    break;
                }
            }
            require(cursorIndex != 0, "The cursor is invalid.");
        }

        for (
                uint i = cursorIndex == 0 ? (_oldestFirst ? 0 : 1) : (_oldestFirst ? cursorIndex + 1 : list.length - cursorIndex + 1);
                _oldestFirst ? i < list.length : i <= list.length;
                i++
            ) { // Oldest or newest first.
            bytes32 tokenID = list[_oldestFirst ? i : list.length - i];
            Token storage token = tokens[tokenID];
            Request storage request = token.requests[token.requests.length - 1];
            if (
                /* solium-disable operator-whitespace */
                (_filter[0] && token.status == TokenStatus.Absent) ||
                (_filter[1] && token.status == TokenStatus.Registered) ||
                (_filter[2] && token.status == TokenStatus.RegistrationRequested && !request.disputed) ||
                (_filter[3] && token.status == TokenStatus.ClearingRequested && !request.disputed) ||
                (_filter[4] && token.status == TokenStatus.RegistrationRequested && request.disputed) ||
                (_filter[5] && token.status == TokenStatus.ClearingRequested && request.disputed) ||
                (_filter[6] && request.parties[uint(Party.Requester)]== msg.sender) || // My Submissions.
                (_filter[7] && request.parties[uint(Party.Challenger)]== msg.sender) // My Challenges.
                /* solium-enable operator-whitespace */
            ) {
                if (index < _count) {
                    values[index] = list[_oldestFirst ? i : list.length - i];
                    index++;
                } else {
                    hasMore = true;
                    break;
                }
            }
        }
    }
}
