/**
 *Submitted for verification at Etherscan.io on 2019-07-16
*/

/**
 *  @authors: []
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */
/* solium-disable max-len*/
pragma solidity ^0.5.10;


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
     *  @param _evidenceGroupID Unique identifier of the evidence group that is linked to this dispute.
     */
    event Dispute(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _metaEvidenceID, uint _evidenceGroupID);

    /** @dev To be raised when evidence are submitted. Should point to the ressource (evidences are not to be stored on chain due to gas considerations).
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _evidenceGroupID Unique identifier of the evidence group the evidence belongs to.
     *  @param _party The address of the party submiting the evidence. Note that 0x0 refers to evidence not submitted by any party.
     *  @param _evidence A URI to the evidence JSON file whose name should be its keccak256 hash followed by .json.
     */
    event Evidence(Arbitrator indexed _arbitrator, uint indexed _evidenceGroupID, address indexed _party, string _evidence);

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
    function rule(uint _disputeID, uint _ruling) external;
}

/** @title Arbitrator
 *  Arbitrator abstract contract.
 *  When developing arbitrator contracts we need to:
 *  -Define the functions for dispute creation (createDispute) and appeal (appeal). Don't forget to store the arbitrated contract and the disputeID (which should be unique, use nbDisputes).
 *  -Define the functions for cost display (arbitrationCost and appealCost).
 *  -Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
 */
contract Arbitrator {

    enum DisputeStatus {Waiting, Appealable, Solved}

    modifier requireArbitrationFee(bytes memory _extraData) {
        require(msg.value >= arbitrationCost(_extraData), "Not enough ETH to cover arbitration costs.");
        _;
    }
    modifier requireAppealFee(uint _disputeID, bytes memory _extraData) {
        require(msg.value >= appealCost(_disputeID, _extraData), "Not enough ETH to cover appeal costs.");
        _;
    }

    /** @dev To be raised when a dispute is created.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(uint indexed _disputeID, IArbitrable indexed _arbitrable);

    /** @dev To be raised when a dispute can be appealed.
     *  @param _disputeID ID of the dispute.
     */
    event AppealPossible(uint indexed _disputeID, IArbitrable indexed _arbitrable);

    /** @dev To be raised when the current ruling is appealed.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event AppealDecision(uint indexed _disputeID, IArbitrable indexed _arbitrable);

    /** @dev Create a dispute. Must be called by the arbitrable contract.
     *  Must be paid at least arbitrationCost(_extraData).
     *  @param _choices Amount of choices the arbitrator can make in this dispute.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return disputeID ID of the dispute created.
     */
    function createDispute(uint _choices, bytes memory _extraData) public requireArbitrationFee(_extraData) payable returns (uint disputeID) {}

    /** @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return fee Amount to be paid.
     */
    function arbitrationCost(bytes memory _extraData) public view returns (uint fee);

    /** @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give extra info on the appeal.
     */
    function appeal(uint _disputeID, bytes memory _extraData) public requireAppealFee(_disputeID, _extraData) payable {
        emit AppealDecision(_disputeID, IArbitrable(msg.sender));
    }

    /** @dev Compute the cost of appeal. It is recommended not to increase it often, as it can be higly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return fee Amount to be paid.
     */
    function appealCost(uint _disputeID, bytes memory _extraData) public view returns (uint fee);

    /** @dev Compute the start and end of the dispute's current or next appeal period, if possible.
     *  @param _disputeID ID of the dispute.
     *  @return The start and end of the period.
     */
    function appealPeriod(uint _disputeID) public view returns (uint start, uint end);

    /** @dev Return the status of a dispute.
     *  @param _disputeID ID of the dispute to rule.
     *  @return status The status of the dispute.
     */
    function disputeStatus(uint _disputeID) public view returns (DisputeStatus status);

    /** @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     *  @param _disputeID ID of the dispute.
     *  @return ruling The ruling which has been given or the one which will be given if there is no appeal.
     */
    function currentRuling(uint _disputeID) public view returns (uint ruling);
}

contract Arbitrable is IArbitrable {
    Arbitrator public arbitrator;
    bytes public arbitratorExtraData; // Extra data to require particular dispute and appeal behaviour.

    /** @dev Constructor. Choose the arbitrator.
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _arbitratorExtraData Extra data for the arbitrator.
     */
    constructor(Arbitrator _arbitrator, bytes memory _arbitratorExtraData) public {
        arbitrator = _arbitrator;
        arbitratorExtraData = _arbitratorExtraData;
    }

    /** @dev Give a ruling for a dispute. Must be called by the arbitrator.
     *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint _disputeID, uint _ruling) external {
        emit Ruling(Arbitrator(msg.sender), _disputeID, _ruling);

        executeRuling(_disputeID, _ruling);
    }


    /** @dev Execute a ruling of a dispute.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function executeRuling(uint _disputeID, uint _ruling) internal;
}

interface PermissionInterface {
    /* External */

    /**
     *  @dev Return true if the value is allowed.
     *  @param _value The value we want to check.
     *  @return allowed True if the value is allowed, false otherwise.
     */
    function isPermitted(bytes32 _value) external view returns (bool allowed);
}

library CappedMath {
    uint constant private UINT_MAX = 2**256 - 1;

    /**
     * @dev Adds two unsigned integers, returns 2^256 - 1 on overflow.
     */
    function addCap(uint _a, uint _b) internal pure returns (uint) {
        return (_a + _b) >= _a ? (_a + _b) : UINT_MAX;
    }

    /**
     * @dev Subtracts two integers, returns 0 on underflow.
     */
    function subCap(uint _a, uint _b) internal pure returns (uint) {
        return (_b > _a) ? 0 : _a - _b;
    }

    /**
     * @dev Multiplies two unsigned integers, returns 2^256 - 1 on overflow.
     */
    function mulCap(uint _a, uint _b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring '_a' not being zero, but the
        // benefit is lost if '_b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0)
            return 0;

        uint c = _a * _b;
        
        return c / _a == _b ? c : UINT_MAX;
    }
}

contract EthereumClaimsRegistry {

    mapping(address => mapping(address => mapping(bytes32 => bytes32))) public registry;

    event ClaimSet(
        address indexed issuer,
        address indexed subject,
        bytes32 indexed key,
        bytes32 value,
        uint updatedAt);

    event ClaimRemoved(
        address indexed issuer,
        address indexed subject,
        bytes32 indexed key,
        uint removedAt);

    // create or update clams
    function setClaim(address subject, bytes32 key, bytes32 value) public {
        registry[msg.sender][subject][key] = value;
        emit ClaimSet(msg.sender, subject, key, value, now);
    }

    function setSelfClaim(bytes32 key, bytes32 value) public {
        setClaim(msg.sender, key, value);
    }

    function getClaim(address issuer, address subject, bytes32 key) public view returns (bytes32) {
        return registry[issuer][subject][key];
    }

    function removeClaim(address issuer, address subject, bytes32 key) public {
        require(msg.sender == issuer);
        delete registry[issuer][subject][key];
        emit ClaimRemoved(msg.sender, subject, key, now);
    }
}

// ERC 780
interface EthereumClaimsRegistryInterface {
    // create or update clams
    function setClaim(address subject, bytes32 key, bytes32 value) external;

    function setSelfClaim(bytes32 key, bytes32 value) external;

    function getClaim(address issuer, address subject, bytes32 key) external view returns (bytes32);

    function removeClaim(address issuer, address subject, bytes32 key) external;
    
    /* events */
    event ClaimSet(
        address indexed issuer,
        address indexed subject,
        bytes32 indexed key,
        bytes32 value,
        uint updatedAt
    );

    event ClaimRemoved(
        address indexed issuer,
        address indexed subject,
        bytes32 indexed key,
        uint removedAt
    );
}

interface requestClaimRegistry {
    function requestPublicStatusChange(address issuer, address subject, bytes32 key) external; // can be challenged
    function challengePublicRequest() external;
    function requestPrivateStatusChange(address issuer, address subject, bytes32 key) external; // need arbitration cost
    
}

// Claim Curated Registry CCR
contract ClaimCuratedRegistry is PermissionInterface, EthereumClaimsRegistryInterface, Arbitrable {
    
    address public DONATION = 0x0c210a230AaaE919b82f22993c7261583Db075e8; // Feel free to send ETH to this address
    
    using CappedMath for uint; // Operations bounded between 0 and 2**256 - 1.

    /* Enums */

    enum ClaimStatus {
        Absent, // The claim is not in the registry.
        RegistrationRequested, // The claim has a request to be registered.
        Registered, // The claim is in the registry.
        ClearingRequested // The claim has a request to be removed from the registry.
    }

    enum Party {
        None,      // Party per default when there is no challenger or requester.
                   // Also used for unconclusive ruling.
        Requester, // Party that made the request to change a token status.
        Challenger // Party that challenges the request to change a token status.
    }
    
    enum DisputeStatus {
        None, // The claim is not disputed.
        Disputed, // The claim is disputed.
        Appealed, // The dispute of the claim is appealed.
        Resolved, // The dispute of the claim is resolved.
        ResolvedByTimeout // The dispute is resolved because one side does not fully funding in the time.
    }
    
    enum RequestType {
        NewSubmission, // The claim is new.
        RegistrationRequest, // The claim is for a registration.
        ClearingRequest // The claim is for clearing.
    }

    // ************************ //
    // *  Request Life Cycle  * //
    // ************************ //
    // Changes to the claim status are made via requests for either listing or removing a claim
    // from the Claim Curated Registry.
    // To make or challenge a request, a party must pay a deposit. This value will be rewarded to the 
    // party that ultimately wins a dispute. If no one challenges the public claim, the value will be 
    // reimbursed to the requester.
    // The user can also make a private claim. In this case, he must pay the arbitration fees.
    // Additionally to the challenge reward, in the case a party challenges a request, both sides must 
    // fully pay the amount of arbitration fees required to raise a dispute. The party that ultimately 
    // wins the case will be reimbursed.
    // Finally, arbitration fees can be crowdsourced. To incentivise insurers, an additional fee stake 
    // must be deposited. Contributors that fund the side that ultimately wins a dispute will be 
    // reimbursed and rewarded with the other side's fee stake proportionally to their contribution.
    // In summary, costs for placing or challenging a request are the following:
    // - A challenge reward given to the party that wins a potential dispute.
    // - Arbitration fees used to pay jurors.
    // - A fee stake that is distributed among insurers of the side that ultimately wins a dispute.

    /* Structs */
    
    // Some arrays below have 3 elements to map with the Party enums for better readability:
    // - 0: is unused, matches `Party.None`.
    // - 1: for `Party.Requester`.
    // - 2: for `Party.Challenger`.
    struct Request {
        DisputeStatus disputeStatus; // Status of dispute if any.
        uint disputeID; // ID of the dispute, if any.
        uint submissionTime; // Time when the request was made. Used to track when the challenge period ends.
        address[3] parties; // Address of requester and challenger, if any.
        Round[] rounds; // Tracks each round of a dispute.
        Party ruling; // The final ruling given, if any.
        Arbitrator arbitrator; // The arbitrator trusted to solve disputes for this request.
        bytes arbitratorExtraData; // The extra data for the trusted arbitrator of this request.
    }
    
    struct Round {
        uint[3] paidFees; // Tracks the fees paid by each side on this round.
        bool[3] hasPaid; // True when the side has fully paid its fee. False otherwise.
        uint feeRewards; // Sum of reimbursable fees and stake rewards available to the parties that made 
                         // contributions to the side that ultimately wins a dispute.
        mapping(address => uint[3]) contributions; // Maps contributors to their contributions for each side.
    }
    
    // Inpiration by EIP 1812
    // The issuer is always the 
    struct Claim {
        address issuer; // The address of the issuer. In the case of a resolved dispute, it's the arbitrator.
        address subject;
        bytes32 key;
        bytes32 value;
	    uint256 validFrom;
	    uint256 validTo;
	
        ClaimStatus status; // The status of the claim.
        Request[] requests; // List of status change requests made for the claim.
    }

    /* Storage */
    
    // Constants
    
    uint RULING_OPTIONS = 2; // The amount of non 0 choices the arbitrator can give.

    // Settings
    address public governor; // The address that can make governance changes to the parameters 
                             // of the Claim Curated Registry.
    uint public requesterBaseDeposit; // The base deposit to make a request.
    uint public challengerBaseDeposit; // The base deposit to challenge a request.
    uint public challengePeriodDuration; // The time before a request becomes executable if not challenged.
    uint public metaEvidenceUpdates; // The number of times the meta evidence has been updated. Used to 
                                     // track the latest meta evidence ID.

    // The required fee stake that a party must pay depends on who won the previous round and is proportional 
    // to the arbitration cost such that the fee stake for a round is stake multiplier * arbitration cost for 
    // that round.
    // Multipliers are in basis points.
    uint public winnerStakeMultiplier; // Multiplier for calculating the fee stake paid by the party that won 
                                       // the previous round.
    uint public loserStakeMultiplier; // Multiplier for calculating the fee stake paid by the party that lost 
                                      // the previous round.
    uint public sharedStakeMultiplier; // Multiplier for calculating the fee stake that must be paid in the 
                                       // case where there isn't a winner and loser (e.g. when it's the first 
                                       // round or the arbitrator ruled "refused to rule"/"could not rule").
    uint public constant MULTIPLIER_DIVISOR = 10000; // Divisor parameter for multipliers.

    // Registry data.
    mapping(bytes32 => Claim) public claims; // Maps the claim ID to the claim data.
    mapping(address => mapping(uint => bytes32)) public arbitratorDisputeIDToClaimID; // Maps a dispute ID to 
    // the ID of the claim with the disputed request. On the form arbitratorDisputeIDToClaimID[arbitrator][disputeID].
    bytes32[] public claimsList; // List of IDs of submitted claims.

    // Token list
    mapping(address => bytes32[]) public subjectToSubmissions; // Maps subjects to submitted claim IDs.

    /* Modifiers */

    modifier onlyGovernor {require(msg.sender == governor, "The caller must be the governor."); _;}

    /* Events */

    /**
     *  @dev Emitted when a party submits a new claim.
     */
    event ClaimSet(
        address indexed _issuer,
        address indexed _subject,
        bytes32 indexed _key,
        bytes32 _value,
        uint256 _validFrom,
	    uint256 _validTo,
        uint _updatedAt
    );

    event ClaimRemoved(
        address indexed _issuer,
        address indexed _subject,
        bytes32 indexed _key,
        uint _removedAt
    );

    /** @dev Emitted when a party makes a request to change a claim status.
     *  @param _claimID The ID of the affected claim.
     *  @param _type Type of the request.
     */
    event RequestSubmitted(
        bytes32 indexed _claimID, 
        RequestType _type
    );

    /**
     *  @dev Emitted when a party makes a request, dispute or appeals are raised, or when a request is resolved.
     *  @param _requester Address of the party that submitted the request.
     *  @param _challenger Address of the party that has challenged the request, if any.
     *  @param _identityID The claim ID. It is the keccak256 hash of it's data.
     *  @param _status The status of the claim.
     *  @param _disputeStatus The status of the dispute.
     */
    event ClaimStatusChange(
        address indexed _requester,
        address indexed _challenger,
        bytes32 indexed _identityID,
        ClaimStatus _status,
        DisputeStatus _disputeStatus
    );

    /** @dev Emitted when a reimbursements and/or contribution rewards are withdrawn.
     *  @param _claimID The ID of the token from which the withdrawal was made.
     *  @param _contributor The address that sent the contribution.
     *  @param _request The request from which the withdrawal was made.
     *  @param _round The round from which the reward was taken.
     *  @param _value The value of the reward.
     */
    event RewardWithdrawal(
        bytes32 indexed _claimID, 
        address indexed _contributor, 
        uint indexed _request, 
        uint _round, 
        uint _value
    );

    
    
    /* Constructor */

    /**
     *  @dev Constructs the arbitrable token curated registry.
     *  @param _arbitrator The trusted arbitrator to resolve potential disputes.
     *  @param _arbitratorExtraData Extra data for the trusted arbitrator contract.
     */
    constructor(
        Arbitrator _arbitrator,
        bytes memory _arbitratorExtraData
        // string _registrationMetaEvidence,
        // string _clearingMetaEvidence,
        // address _governor,
        // uint _requesterBaseDeposit,
        // uint _challengerBaseDeposit,
        // uint _challengePeriodDuration,
        // uint _sharedStakeMultiplier,
        // uint _winnerStakeMultiplier,
        // uint _loserStakeMultiplier
    ) Arbitrable(_arbitrator, _arbitratorExtraData) public {

    }
    
        
    /* External and Public */
    
    // ************************ //
    // *       Requests       * //
    // ************************ //

    /** @dev Submits a request to change a token status. Accepts enough ETH to fund a potential dispute considering the current required amount and reimburses the rest. TRUSTED.
     *  @param _subject The address of the target.
     *  @param _key The key.
     *  @param _value The value of the key.
     *  @param _validFrom The valid from.
     *  @param _validTo  The valid to.
     */
    function requestPublicStatusChange(
        address _subject,
        bytes32 _key,
        bytes32 _value,
        uint256 _validFrom,
	    uint256 _validTo
    )
        external
        payable
    {
        bytes32 claimID = keccak256(
            abi.encodePacked(
                _subject,
                _key,
                _value,
                _validFrom,
                _validTo
            )
        );

        Claim storage claim = claims[claimID];
        if (claim.requests.length == 0) {
            // Initial token registration.
            claim.issuer = msg.sender;
            claim.subject = _subject;
            claim.key = _key;
            claim.value = _value;
            claim.validFrom = _validFrom;
            claim.validTo = _validTo;
            claimsList.push(claimID);
            subjectToSubmissions[_subject].push(claimID);
            emit ClaimSet(
                msg.sender,
                _subject,
                _key,
                _value,
                _validFrom,
        	    _validTo,
                now
            );
            emit RequestSubmitted(
                claimID, 
                RequestType.NewSubmission
            );
        }

        // Update claim status.
        if (claim.status == ClaimStatus.Absent)
            claim.status = ClaimStatus.RegistrationRequested;
        else if (claim.status == ClaimStatus.Registered)
            claim.status = ClaimStatus.ClearingRequested;
        else
            revert("Claim already has a pending request.");

        // Setup request.
        Request storage request = claim.requests[claim.requests.length++];
        request.parties[uint(Party.Requester)] = msg.sender;
        request.submissionTime = now;
        request.arbitrator = arbitrator;
        request.arbitratorExtraData = arbitratorExtraData;
        Round storage round = request.rounds[request.rounds.length++];

        emit RequestSubmitted(
            claimID, 
            claim.status == ClaimStatus.RegistrationRequested ? RequestType.RegistrationRequest : RequestType.ClearingRequest
        );

        // Amount required to fully fund each side: requesterBaseDeposit + arbitration cost + (arbitration cost * multiplier).
        uint arbitrationCost = request.arbitrator.arbitrationCost(request.arbitratorExtraData);
        uint totalCost = arbitrationCost.addCap((arbitrationCost.mulCap(sharedStakeMultiplier)) / MULTIPLIER_DIVISOR).addCap(requesterBaseDeposit);
        // contribute(round, Party.Requester, msg.sender, msg.value, totalCost); // TODO: add this method
        require(round.paidFees[uint(Party.Requester)] >= totalCost, "You must fully fund your side.");
        round.hasPaid[uint(Party.Requester)] = true;
        
        emit ClaimStatusChange(
            request.parties[uint(Party.Requester)],
            address(0x0),
            claimID,
            claim.status,
            DisputeStatus.None
        );
    }
    
    function challengePublicRequest(bytes32 _claimID, string calldata _evidence) external payable {
        Claim storage claim = claims[_claimID];

        require(
            claim.status == ClaimStatus.RegistrationRequested || claim.status == ClaimStatus.ClearingRequested,
            "The claim must have a pending request."
        );

        Request storage request = claim.requests[claim.requests.length - 1];
        
        require(now - request.submissionTime <= challengePeriodDuration, "Challenges must occur during the challenge period.");
        require(request.disputeStatus == DisputeStatus.None, "The request should not have already been disputed.");

        // Take the deposit and save the challenger's address.
        request.parties[uint(Party.Challenger)] = msg.sender;

        Round storage round = request.rounds[request.rounds.length - 1];
        uint arbitrationCost = request.arbitrator.arbitrationCost(request.arbitratorExtraData);
        uint totalCost = arbitrationCost.addCap(
            arbitrationCost.mulCap(sharedStakeMultiplier) 
            / MULTIPLIER_DIVISOR
        ).addCap(challengerBaseDeposit);
        
        // contribute(round, Party.Challenger, msg.sender, msg.value, totalCost);
        
        require(round.paidFees[uint(Party.Challenger)] >= totalCost, "You must fully fund your side.");

        round.hasPaid[uint(Party.Challenger)] = true;
        
        // Raise a dispute.
        request.disputeID = request.arbitrator.createDispute.value(arbitrationCost)(RULING_OPTIONS, request.arbitratorExtraData);
        arbitratorDisputeIDToClaimID[address(request.arbitrator)][request.disputeID] = _claimID;
        request.disputeStatus = DisputeStatus.Disputed;
        request.rounds.length++;
        round.feeRewards = round.feeRewards.subCap(arbitrationCost);
        
        emit Dispute(
            request.arbitrator,
            request.disputeID,
            claim.status == ClaimStatus.RegistrationRequested
                ? 2 * metaEvidenceUpdates
                : 2 * metaEvidenceUpdates + 1,
            uint(keccak256(abi.encodePacked(_claimID, claim.requests.length - 1)))
        );
        emit ClaimStatusChange(
            request.parties[uint(Party.Requester)],
            request.parties[uint(Party.Challenger)],
            _claimID,
            claim.status,
            DisputeStatus.Disputed
        );

        if (bytes(_evidence).length > 0)
            emit Evidence(
                request.arbitrator, 
                uint(keccak256(abi.encodePacked(_claimID, claim.requests.length - 1))), 
                msg.sender,
                _evidence
            );
    }
    
    
    /** @dev Takes up to the total amount required to fund a side of an appeal. Reimburses the rest. 
     *  Creates an appeal if both sides are fully funded. TRUSTED.
     *  @param _claimID The ID of the claim with the request to fund.
     *  @param _side The recipient of the contribution.
     */
    function fundAppeal(bytes32 _claimID, Party _side) external payable {
        // Recipient must be either the requester or challenger.
        require(_side == Party.Requester || _side == Party.Challenger); // solium-disable-line error-reason
        Claim storage claim = claims[_claimID];
        require(
            claim.status == ClaimStatus.RegistrationRequested || claim.status == ClaimStatus.ClearingRequested,
            "The token must have a pending request."
        );

        Request storage request = claim.requests[claim.requests.length - 1];

        require(
            request.disputeStatus == DisputeStatus.Disputed, 
            "A dispute must have been raised to fund an appeal."
        );

        (uint appealPeriodStart, uint appealPeriodEnd) = request.arbitrator.appealPeriod(request.disputeID);

        require(
            now >= appealPeriodStart && now < appealPeriodEnd,
            "Contributions must be made within the appeal period."
        );
        

        // Amount required to fully fund each side: arbitration cost + (arbitration cost * multiplier)
        Round storage round = request.rounds[request.rounds.length - 1];
        Party winner = Party(request.arbitrator.currentRuling(request.disputeID));
        Party loser;
            
        loser = (winner == Party.Requester) ? Party.Challenger : (winner == Party.Challenger) ? Party.Requester : Party.None;

        require(
            !(_side==loser) || (now-appealPeriodStart < (appealPeriodEnd-appealPeriodStart)/2), 
            "The loser must contribute during the first half of the appeal period."
        );
        
        uint multiplier;
        if (_side == winner)
            multiplier = winnerStakeMultiplier;
        else if (_side == loser)
            multiplier = loserStakeMultiplier;
        else
            multiplier = sharedStakeMultiplier;
        uint appealCost = request.arbitrator.appealCost(request.disputeID, request.arbitratorExtraData);
        uint totalCost = appealCost.addCap((appealCost.mulCap(multiplier)) / MULTIPLIER_DIVISOR);
        
        // contribute(round, _side, msg.sender, msg.value, totalCost); // TODO
        
        if (round.paidFees[uint(_side)] >= totalCost)
            round.hasPaid[uint(_side)] = true;

        // Raise appeal if both sides are fully funded.
        if (round.hasPaid[uint(Party.Challenger)] && round.hasPaid[uint(Party.Requester)]) {
            request.arbitrator.appeal.value(appealCost)(request.disputeID, request.arbitratorExtraData);
            request.rounds.length++;
            round.feeRewards = round.feeRewards.subCap(appealCost);

            emit ClaimStatusChange(
                request.parties[uint(Party.Requester)],
                request.parties[uint(Party.Challenger)],
                _claimID,
                claim.status,
                DisputeStatus.Appealed
            );
        }
    }
    
    /** @dev Reimburses contributions if no disputes were raised. If a dispute was raised, sends the fee stake 
     *  rewards and reimbursements proportional to the contributions made to the winner of a dispute.
     *  @param _beneficiary The address that made contributions to a request.
     *  @param _claimID The ID of the claim submission with the request from which to withdraw.
     *  @param _request The request from which to withdraw.
     *  @param _round The round from which to withdraw.
     */
    function withdrawFeesAndRewards(
        address payable _beneficiary, 
        bytes32 _claimID, 
        uint _request,
        uint _round
    ) public {
        Claim storage claim = claims[_claimID];
        Request storage request = claim.requests[_request];
        Round storage round = request.rounds[_round];
        // The request must be resolved and there can be no disputes pending resolution.
        require(
            request.disputeStatus == DisputeStatus.Resolved || request.disputeStatus == DisputeStatus.ResolvedByTimeout, 
            "The dispute must be resolved."
        );

        uint reward;
        if (request.disputeStatus == DisputeStatus.ResolvedByTimeout || request.ruling == Party.None) {
            // No disputes were raised, or there isn't a winner and loser. Reimburse unspent fees proportionally.
            uint rewardRequester = round.paidFees[uint(Party.Requester)] > 0
                ? (round.contributions[_beneficiary][uint(Party.Requester)] 
                  * round.feeRewards) / (round.paidFees[uint(Party.Challenger)] + round.paidFees[uint(Party.Requester)])
                : 0;
            uint rewardChallenger = round.paidFees[uint(Party.Challenger)] > 0
                ? (round.contributions[_beneficiary][uint(Party.Challenger)] 
                  * round.feeRewards) / (round.paidFees[uint(Party.Challenger)] + round.paidFees[uint(Party.Requester)])
                : 0;

            reward = rewardRequester + rewardChallenger;
            round.contributions[_beneficiary][uint(Party.Requester)] = 0;
            round.contributions[_beneficiary][uint(Party.Challenger)] = 0;
        } else {
            // Reward the winner.
            reward = round.paidFees[uint(request.ruling)] > 0
                ? (round.contributions[_beneficiary][uint(request.ruling)]
                  * round.feeRewards) / round.paidFees[uint(request.ruling)]
                : 0;

            round.contributions[_beneficiary][uint(request.ruling)] = 0;
        }

        emit RewardWithdrawal(_claimID, _beneficiary, _request, _round,  reward);
        _beneficiary.send(reward); // It is the user responsibility to accept ETH.
    }
    
    /** @dev Withdraws rewards and reimbursements of multiple rounds at once. 
     *  This function is O(n) where n is the number of rounds. This could exceed gas limits, 
     *  therefore this function should be used only as a utility and not be relied upon by other contracts.
     *  @param _beneficiary The address that made contributions to the request.
     *  @param _claimID The claim ID with funds to be withdrawn.
     *  @param _request The request from which to withdraw contributions.
     *  @param _cursor The round from where to start withdrawing.
     *  @param _count The number of rounds to iterate. If set to 0 or a value larger than the number of rounds, 
     *  iterates until the last round.
     */
    function batchRoundWithdraw(
        address payable _beneficiary, 
        bytes32 _claimID, 
        uint _request, 
        uint _cursor, 
        uint _count
    ) public {
        Claim storage claim = claims[_claimID];
        Request storage request = claim.requests[_request];
        for (uint i = _cursor; i<request.rounds.length && (_count==0 || i<_count); i++)
            withdrawFeesAndRewards(_beneficiary, _claimID, _request, i);
    }

    /** @dev Withdraws rewards and reimbursements of multiple requests at once. This function is O(n*m) where n is 
     *  the number of requests and m is the number of rounds to withdraw per request. This could exceed gas limits, 
     *  therefore this function should be used only as a utility and not be relied upon by other contracts.
     *  @param _beneficiary The address that made contributions to the request.
     *  @param _claimID The claim ID with funds to be withdrawn.
     *  @param _cursor The request from which to start withdrawing.
     *  @param _count The number of requests to iterate. If set to 0 or a value larger than the number of request, 
     *  iterates until the last request.
     *  @param _roundCursor The round of each request from where to start withdrawing.
     *  @param _roundCount The number of rounds to iterate on each request. If set to 0 or a value larger than 
     *  the number of rounds a request has, iteration for that request will stop at the last round.
     */
    function batchRequestWithdraw(
        address payable _beneficiary,
        bytes32 _claimID,
        uint _cursor,
        uint _count,
        uint _roundCursor,
        uint _roundCount
    ) external {
        Claim storage claim = claims[_claimID];
        for (uint i = _cursor; i<claim.requests.length && (_count==0 || i<_count); i++)
            batchRoundWithdraw(_beneficiary, _claimID, i, _roundCursor, _roundCount);
    }
    
    /** @dev Executes a request if the challenge period passed and no one challenged the request.
     *  @param _claimID The ID of the token with the request to execute.
     */
    function executeRequest(bytes32 _claimID) external {
        Claim storage claim = claims[_claimID];
        Request storage request = claim.requests[claim.requests.length - 1];
        
        require(
            now - request.submissionTime > challengePeriodDuration,
            "Time to challenge the request must have passed."
        );
        require(
            request.disputeStatus == DisputeStatus.None, 
            "The request should not be disputed."
        );
            

        if (claim.status == ClaimStatus.RegistrationRequested)
            claim.status = ClaimStatus.Registered;
        else if (claim.status == ClaimStatus.ClearingRequested)
            claim.status = ClaimStatus.Absent;
        else
            revert("There must be a request.");

        request.disputeStatus = DisputeStatus.ResolvedByTimeout;
        
        // address(request.parties[uint(Party.Requester)]) will not allow to call ``send`` directly, 
        // since ``request.parties[uint(Party.Requester)`` has no payable fallback function. It has 
        // to be converted to the ``address payable`` type via an intermediate conversion to ``uint160`` 
        // to even allow calling ``send`` on it.
        address payable requester = address(uint160(address(request.parties[uint(Party.Requester)])));
        
        // Automatically withdraw for the requester.
        withdrawFeesAndRewards(
            requester, 
            _claimID, 
            claim.requests.length - 1, 
            0
        );
        
        emit ClaimStatusChange(
            request.parties[uint(Party.Requester)],
            address(0x0),
            _claimID,
            claim.status,
            DisputeStatus.ResolvedByTimeout
        );
    }
    
    //////////////////////////// TODO setClaim ///////////////////////////////////////////////////////////////
    
    /** @dev Give a ruling for a dispute. Can only be called by the arbitrator. TRUSTED.
     *  Overrides parent function to account for the situation where the winner loses a case due to paying 
     *  less appeal fees than expected.
     *  @param _disputeID ID of the dispute in the arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make 
     *  a decision".
     */
    function rule(uint _disputeID, uint _ruling) public {
        Party resultRuling = Party(_ruling);
        bytes32 claimID = arbitratorDisputeIDToClaimID[msg.sender][_disputeID];
        Claim storage claim = claims[claimID];
        Request storage request = claim.requests[claim.requests.length - 1];
        Round storage round = request.rounds[request.rounds.length - 1];

        require(_ruling <= RULING_OPTIONS); // solium-disable-line error-reason
        require(address(request.arbitrator) == msg.sender); // solium-disable-line error-reason
        require(request.disputeStatus != DisputeStatus.Resolved); // solium-disable-line error-reason

        // The ruling is inverted if the loser paid its fees.
        // If one side paid its fees, the ruling is in its favor. 
        // Note that if the other side had also paid, an appeal would have been created.
        resultRuling = (round.hasPaid[uint(Party.Requester)] == true) 
            ? Party.Requester 
            : (round.hasPaid[uint(Party.Challenger)] == true)
                ? Party.Challenger
                : Party.None;
        
        emit Ruling(Arbitrator(msg.sender), _disputeID, uint(resultRuling));
        executeRuling(_disputeID, uint(resultRuling));
    }

    /** @dev Submit a reference to evidence. EVENT.
     *  @param _claimID The ID of the claim with the request to execute.
     *  @param _evidence A link to an evidence using its URI.
     */
    function submitEvidence(bytes32 _claimID, string calldata _evidence) external {
        Claim storage claim = claims[_claimID];
        Request storage request = claim.requests[claim.requests.length - 1];
        require(request.disputeStatus != DisputeStatus.Resolved, "The dispute must not already be resolved.");

        emit Evidence(
            request.arbitrator, 
            uint(keccak256(abi.encodePacked(_claimID, claim.requests.length - 1))), 
            msg.sender, 
            _evidence
        );
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

    /** @dev Change the base amount required as a deposit to make a request.
     *  @param _requesterBaseDeposit The new base amount of wei required to make a request.
     */
    function changeRequesterBaseDeposit(uint _requesterBaseDeposit) external onlyGovernor {
        requesterBaseDeposit = _requesterBaseDeposit;
    }
    
    /** @dev Change the base amount required as a deposit to challenge a request.
     *  @param _challengerBaseDeposit The new base amount of wei required to challenge a request.
     */
    function changeChallengerBaseDeposit(uint _challengerBaseDeposit) external onlyGovernor {
        challengerBaseDeposit = _challengerBaseDeposit;
    }

    /** @dev Change the governor of the token curated registry.
     *  @param _governor The address of the new governor.
     */
    function changeGovernor(address _governor) external onlyGovernor {
        governor = _governor;
    }

    /** @dev Change the percentage of arbitration fees that must be paid as fee stake by parties when there isn't a winner or loser.
     *  @param _sharedStakeMultiplier Multiplier of arbitration fees that must be paid as fee stake. In basis points.
     */
    function changeSharedStakeMultiplier(uint _sharedStakeMultiplier) external onlyGovernor {
        sharedStakeMultiplier = _sharedStakeMultiplier;
    }

    /** @dev Change the percentage of arbitration fees that must be paid as fee stake by the winner of the previous round.
     *  @param _winnerStakeMultiplier Multiplier of arbitration fees that must be paid as fee stake. In basis points.
     */
    function changeWinnerStakeMultiplier(uint _winnerStakeMultiplier) external onlyGovernor {
        winnerStakeMultiplier = _winnerStakeMultiplier;
    }

    /** @dev Change the percentage of arbitration fees that must be paid as fee stake by the party that lost the previous round.
     *  @param _loserStakeMultiplier Multiplier of arbitration fees that must be paid as fee stake. In basis points.
     */
    function changeLoserStakeMultiplier(uint _loserStakeMultiplier) external onlyGovernor {
        loserStakeMultiplier = _loserStakeMultiplier;
    }

    /** @dev Change the arbitrator to be used for disputes that may be raised in the next requests. The arbitrator is trusted 
     *  to support appeal periods and not reenter.
     *  @param _arbitrator The new trusted arbitrator to be used in the next requests.
     *  @param _arbitratorExtraData The extra data used by the new arbitrator.
     */
    function changeArbitrator(Arbitrator _arbitrator, bytes calldata _arbitratorExtraData) external onlyGovernor {
        arbitrator = _arbitrator;
        arbitratorExtraData = _arbitratorExtraData;
    }

    /** @dev Update the meta evidence used for disputes.
     *  @param _registrationMetaEvidence The meta evidence to be used for future registration request disputes.
     *  @param _clearingMetaEvidence The meta evidence to be used for future clearing request disputes.
     */
    function changeMetaEvidence(
        string calldata _registrationMetaEvidence, 
        string calldata _clearingMetaEvidence
    ) external onlyGovernor {
        metaEvidenceUpdates++;
        emit MetaEvidence(2 * metaEvidenceUpdates, _registrationMetaEvidence);
        emit MetaEvidence(2 * metaEvidenceUpdates + 1, _clearingMetaEvidence);
    }
    
    /* Internal */

    /** @dev Returns the contribution value and remainder from available ETH and required amount.
     *  @param _available The amount of ETH available for the contribution.
     *  @param _requiredAmount The amount of ETH required for the contribution.
     *  @return taken The amount of ETH taken.
     *  @return remainder The amount of ETH left from the contribution.
     */
    function calculateContribution(uint _available, uint _requiredAmount)
        internal
        pure
        returns (uint taken, uint remainder)
    {
        if (_requiredAmount > _available)
            return (_available, 0); // Take whatever is available, return 0 as leftover ETH.

        remainder = _available - _requiredAmount;

        return (_requiredAmount, remainder);
    }
    
    /** @dev Make a fee contribution.
     *  @param _round The round to contribute.
     *  @param _side The side for which to contribute.
     *  @param _contributor The contributor.
     *  @param _amount The amount contributed.
     *  @param _totalRequired The total amount required for this side.
     */
    function contribute(
        Round storage _round, 
        Party _side, 
        address payable _contributor, 
        uint _amount, 
        uint _totalRequired
    ) internal {
        // Take up to the amount necessary to fund the current round at the current costs.
        uint contribution; // Amount contributed.
        uint remainingETH; // Remaining ETH to send back.
        (contribution, remainingETH) = calculateContribution(_amount, _totalRequired.subCap(_round.paidFees[uint(_side)]));
        _round.contributions[_contributor][uint(_side)] += contribution;
        _round.paidFees[uint(_side)] += contribution;
        _round.feeRewards += contribution;

        // Reimburse leftover ETH.
        _contributor.send(remainingETH); // Deliberate use of send in order to not block the contract in case of reverting fallback.
    }
    
    /** @dev Execute the ruling of a dispute.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function executeRuling(uint _disputeID, uint _ruling) internal {
        bytes32 claimID = arbitratorDisputeIDToClaimID[msg.sender][_disputeID];
        Claim storage claim = claims[claimID];
        Request storage request = claim.requests[claim.requests.length - 1];

        Party winner = Party(_ruling);
        
        // Update claim state
        claim.status = (winner == Party.Requester) // Execute Request
            ? (claim.status == ClaimStatus.RegistrationRequested)
                ? ClaimStatus.Registered
                : ClaimStatus.Absent
            : (claim.status == ClaimStatus.RegistrationRequested) // Revert to previous state.
                ? ClaimStatus.Absent
                : ClaimStatus.Registered;

        request.disputeStatus = DisputeStatus.Resolved;
        request.ruling = Party(_ruling);
        
        address payable requester = address(uint160(address(request.parties[uint(Party.Requester)])));
        address payable challenger = address(uint160(address(request.parties[uint(Party.Challenger)])));

        // Automatically withdraw.
        if (winner == Party.None) { // If there is no winner.
            withdrawFeesAndRewards(
                requester, 
                claimID, 
                claim.requests.length - 1, 
                0
            );
            withdrawFeesAndRewards(
                challenger, 
                claimID, 
                claim.requests.length - 1, 
                0
            );
        } else {
            address payable winnerAddress = address(uint160(address(request.parties[uint(winner)])));

            withdrawFeesAndRewards(
                winnerAddress, 
                claimID, 
                claim.requests.length - 1, 
                0
            ); 
        }
        
        emit ClaimStatusChange(
            requester,
            challenger,
            claimID,
            claim.status,
            DisputeStatus.Resolved
        );
    }
    
    
    /* Views */

    /** @dev Return true if the claim is on the list.
     *  @param _claimID The ID of the claim to be queried.
     *  @return allowed True if the token is allowed, false otherwise.
     */
    function isPermitted(bytes32 _claimID) external view returns (bool allowed) {
        Claim storage claim = claims[_claimID];

        return claim.status == ClaimStatus.Registered || claim.status == ClaimStatus.ClearingRequested;
    }

    
    /* Interface Views */

    /** @dev Return the sum of withdrawable wei of a request an account is entitled to. This function is O(n), 
     *  where n is the number of rounds of the request. This could exceed the gas limit, therefore this function 
     *  should only be used for interface display and not by other contracts.
     *  @param _claimID The ID of the claim to query.
     *  @param _beneficiary The contributor for which to query.
     *  @param _request The request from which to query for.
     *  @return The total amount of wei available to withdraw.
     */
    function amountWithdrawable(
        bytes32 _claimID, 
        address _beneficiary, 
        uint _request
    ) external view returns (uint total) {
        Request storage request = claims[_claimID].requests[_request];

        if (request.disputeStatus == DisputeStatus.None) return total;

        for (uint i = 0; i < request.rounds.length; i++) {
            Round storage round = request.rounds[i];
            if (request.disputeStatus == DisputeStatus.None || request.ruling == Party.None) {
                uint rewardRequester = round.paidFees[uint(Party.Requester)] > 0
                    ? (round.contributions[_beneficiary][uint(Party.Requester)] * round.feeRewards) 
                        / (round.paidFees[uint(Party.Requester)] + round.paidFees[uint(Party.Challenger)])
                    : 0;
                uint rewardChallenger = round.paidFees[uint(Party.Challenger)] > 0
                    ? (round.contributions[_beneficiary][uint(Party.Challenger)] * round.feeRewards) 
                        / (round.paidFees[uint(Party.Requester)] + round.paidFees[uint(Party.Challenger)])
                    : 0;

                total += rewardRequester + rewardChallenger;
            } else {
                total += round.paidFees[uint(request.ruling)] > 0
                    ? (round.contributions[_beneficiary][uint(request.ruling)] * round.feeRewards) 
                        / round.paidFees[uint(request.ruling)]
                    : 0;
            }
        }

        return total;
    }
    
    /** @dev Return the numbers of claims that were submitted. Includes tokens that never made it to the list or were later removed.
     *  @return count The numbers of claims in the list.
     */
    function claimCount() external view returns (uint count) {
        count = claimsList.length;
    }
    
    /** @dev Return the numbers of claims with each status. This function is O(n), where n is the number of claims. 
     *  This could exceed the gas limit, therefore this function should only be used for interface display and not by other contracts.
     *  @return The numbers of claims in the list per status.
     */
    function countByStatus()
        external
        view
        returns (
            uint absent,
            uint registered,
            uint registrationRequest,
            uint clearingRequest,
            uint challengedRegistrationRequest,
            uint challengedClearingRequest
        )
    {
        for (uint i = 0; i < claimsList.length; i++) {
            Claim storage claim = claims[claimsList[i]];
            Request storage request = claim.requests[claim.requests.length - 1];

            if (claim.status == ClaimStatus.Absent) absent++;
            else if (claim.status == ClaimStatus.Registered) registered++;
            else if (
                claim.status == ClaimStatus.RegistrationRequested 
                && request.disputeStatus == DisputeStatus.None
            ) registrationRequest++;
            else if (
                claim.status == ClaimStatus.ClearingRequested 
                && request.disputeStatus == DisputeStatus.None
            ) clearingRequest++;
            else if (
                claim.status == ClaimStatus.RegistrationRequested 
                && request.disputeStatus != DisputeStatus.None
            ) challengedRegistrationRequest++;
            else if (
                claim.status == ClaimStatus.ClearingRequested 
                && request.disputeStatus != DisputeStatus.None
            ) challengedClearingRequest++;
        }
    }

    /** @dev Return the values of the claims the query finds. This function is O(n), where n is the number of claims. 
     *  This could exceed the gas limit, therefore this function should only be used for interface display and not 
     *  by other contracts.
     *  @param _cursor The ID of the claim from which to start iterating. To start from either the oldest or newest item.
     *  @param _count The number of claims to return.
     *  @param _filter The filter to use. Each element of the array in sequence means:
     *  - Include absent claims in result.
     *  - Include registered claims in result.
     *  - Include claims with registration requests that are not disputed in result.
     *  - Include claims with clearing requests that are not disputed in result.
     *  - Include disputed claims with registration requests in result.
     *  - Include disputed claims with clearing requests in result.
     *  - Include claims submitted by the caller.
     *  - Include claims challenged by the caller.
     *  @param _oldestFirst Whether to sort from oldest to the newest item.
     *  @param _subject A subject address to filter submissions by address (optional).
     *  @return The values of the claims found and whether there are more claims for the current filter and sort.
     */
    function queryTokens(
        bytes32 _cursor,
        uint _count, 
        bool[8] calldata _filter, 
        bool _oldestFirst, 
        address _subject
    )
        external
        view
        returns (bytes32[] memory values, bool hasMore)
    {
        uint cursorIndex;
        values = new bytes32[](_count);
        uint index = 0;

        bytes32[] storage list = _subject == address(0x0)
            ? claimsList
            : subjectToSubmissions[_subject];

        if (_cursor == 0)
            cursorIndex = 0;
        else {
            for (uint j = 0; j < list.length; j++) {
                if (list[j] == _cursor) {
                    cursorIndex = j;
                    break;
                }
            }

            require(cursorIndex  != 0, "The cursor is invalid.");
        }

        for (
                uint i = cursorIndex == 0 ? (_oldestFirst ? 0 : 1) : (_oldestFirst ? cursorIndex + 1 : list.length - cursorIndex + 1);
                _oldestFirst ? i < list.length : i <= list.length;
                i++
            ) { // Oldest or newest first.
            bytes32 claimID = list[_oldestFirst ? i : list.length - i];
            Claim storage claim = claims[claimID];
            Request storage request = claim.requests[claim.requests.length - 1];
            if (
                /* solium-disable operator-whitespace */
                (_filter[0] && claim.status == ClaimStatus.Absent) ||
                (_filter[1] && claim.status == ClaimStatus.Registered) ||
                (_filter[2] && claim.status == ClaimStatus.RegistrationRequested && request.disputeStatus == DisputeStatus.None) ||
                (_filter[3] && claim.status == ClaimStatus.ClearingRequested && request.disputeStatus == DisputeStatus.None) ||
                (_filter[4] && claim.status == ClaimStatus.RegistrationRequested && request.disputeStatus != DisputeStatus.None) ||
                (_filter[5] && claim.status == ClaimStatus.ClearingRequested && request.disputeStatus != DisputeStatus.None) ||
                (_filter[6] && request.parties[uint(Party.Requester)] == msg.sender) || // My Submissions.
                (_filter[7] && request.parties[uint(Party.Challenger)] == msg.sender) // My Challenges.
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
    
    /** @dev Gets the contributions made by a party for a given round of a request.
     *  @param _claimID The ID of the claim.
     *  @param _request The position of the request.
     *  @param _round The position of the round.
     *  @param _contributor The address of the contributor.
     *  @return The contributions.
     */
    function getContributions(
        bytes32 _claimID,
        uint _request,
        uint _round,
        address _contributor
    ) external view returns (uint[3] memory contributions) {
        Claim storage claim = claims[_claimID];
        Request storage request = claim.requests[_request];
        Round storage round = request.rounds[_round];
        contributions = round.contributions[_contributor];
    }
    
    /** @dev Returns claim information. Includes length of requests array.
     *  @param _claimID The ID of the queried claim.
     *  @return The claim information.
     */
    function getClaimInfo(bytes32 _claimID)
        external
        view
        returns (
            address issuer,
            address subject,
            bytes32 key,
            bytes32 value,
            uint validFrom,
            uint validTo,
            ClaimStatus status,
            uint numberOfRequests
        )
    {
        Claim storage claim = claims[_claimID];
        return (
            claim.issuer, // The address of the issuer. In the case of a resolved dispute, it's the arbitrator.
            claim.subject,
            claim.key,
            claim.value,
    	    claim.validFrom,
    	    claim.validTo,
            claim.status, // The status of the claim.
            claim.requests.length
        );
    }

    /** @dev Gets information on a request made for a claim.
     *  @param _claimID The ID of the queried claim.
     *  @param _request The request to be queried.
     *  @return The request information.
     */
    function getRequestInfo(bytes32 _claimID, uint _request)
        external
        view
        returns (
            DisputeStatus disputeStatus,
            uint disputeID,
            uint submissionTime,
            address[3] memory parties,
            uint numberOfRounds,
            Party ruling,
            Arbitrator arbitrator,
            bytes memory arbitratorExtraData
        )
    {
        Request storage request = claims[_claimID].requests[_request];

        return (
            request.disputeStatus,
            request.disputeID,
            request.submissionTime,
            request.parties,
            request.rounds.length,
            request.ruling,
            request.arbitrator,
            request.arbitratorExtraData
        );
    }

    /** @dev Gets the information on a round of a request.
     *  @param _claimID The ID of the queried claim.
     *  @param _request The request to be queried.
     *  @param _round The round to be queried.
     *  @return The round information.
     */
    function getRoundInfo(bytes32 _claimID, uint _request, uint _round)
        external
        view
        returns (
            bool appealed,
            uint[3] memory paidFees,
            bool[3] memory hasPaid,
            uint feeRewards
        )
    {
        Claim storage claim = claims[_claimID];
        Request storage request = claim.requests[_request];
        Round storage round = request.rounds[_round];
        return (
            _round != (request.rounds.length-1),
            round.paidFees,
            round.hasPaid,
            round.feeRewards
        );
    }
    
    function setClaim(address subject, bytes32 key, bytes32 value) external {}

    function setSelfClaim(bytes32 key, bytes32 value) external {}

    function getClaim(address issuer, address subject, bytes32 key) external view returns (bytes32) {}

    function removeClaim(address issuer, address subject, bytes32 key) external {}
}
