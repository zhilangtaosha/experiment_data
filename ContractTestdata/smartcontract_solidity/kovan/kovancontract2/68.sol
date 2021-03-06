/**
 *Submitted for verification at Etherscan.io on 2019-08-05
*/

pragma solidity ^0.5.10;

contract Derivatives
{
    struct Client
	{
		uint256 hard_balance_unit_cents;
		uint256 soft_balance_unit_cents;
		
		uint256 position_type; // 0 long, 1 short
		uint256 quantity_usd;
		uint256 price_in_usd_cents;
	}
	
    address public master;
    address public service;
	uint256 public price_in_usd_cents;
	uint256 public hard_reserved_unit_cents;
	mapping (address => Client) public clients;

    function deposit() external payable;
    function withdrawal(uint256 value) external;
	function set_price(uint256 new_price) external;
	function set_price_and_liquidation(uint256 new_price, address[] calldata to_liquidate) external;
	function liquidation(address[] calldata to_liquidate) external;
    function create_order_long(uint256 quantity_usd) external;
    function create_order_short(uint256 quantity_usd) external;
}

// version 0.1
contract DerivativesEntry is Derivatives
{
    constructor() public
    {
        master = msg.sender;
    }
    
    function() external payable
    {
        require(msg.data.length == 0, "only empty data allowed");
        require(service != address(0), "service not initialized");
        
        (bool success,) = service.delegatecall(abi.encodeWithSignature("deposit()"));
        require(success, "delegatecall failed");
    }
    
    function set_service(address _service) public
    {
        require(msg.sender == master);
        
        service = _service;
    }
    
    function deposit() external payable
    {
        require(service != address(0), "service not initialized");
        
        (bool success,) = service.delegatecall(abi.encodeWithSignature("deposit()"));
        require(success, "delegatecall failed");
    }

    function withdrawal(uint256 value) public
    {
        require(service != address(0), "service not initialized");
        
        (bool success,) = service.delegatecall(abi.encodeWithSignature("withdrawal(uint256)", value));
        require(success, "delegatecall failed");
    }
    
    function set_price(uint256 new_price) external
    {
        require(service != address(0), "service not initialized");
        
        (bool success,) = service.delegatecall(abi.encodeWithSignature("set_price(uint256)", new_price));
        require(success, "delegatecall failed");
    }
    
	function set_price_and_liquidation(uint256 new_price, address[] calldata to_liquidate) external
	{
        require(service != address(0), "service not initialized");
        
        (bool success,) = service.delegatecall(abi.encodeWithSignature("set_price_and_liquidation(uint256,address[])", new_price, to_liquidate));
        require(success, "delegatecall failed");
	}
	
	function liquidation(address[] calldata to_liquidate) external
	{
        require(service != address(0), "service not initialized");
        
        (bool success,) = service.delegatecall(abi.encodeWithSignature("liquidation(address[])", to_liquidate));
        require(success, "delegatecall failed");
	}
    
    function create_order_long(uint256 quantity_usd) external
    {
        require(service != address(0), "service not initialized");
        
        (bool success,) = service.delegatecall(abi.encodeWithSignature("create_order_long(uint256)", quantity_usd));
        require(success, "delegatecall failed");
    }
    
    function create_order_short(uint256 quantity_usd) external
    {
        require(service != address(0));
        
        (bool success,) = service.delegatecall(abi.encodeWithSignature("create_order_short(uint256)", quantity_usd));
        require(success, "delegatecall failed");
    }
}
