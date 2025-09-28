// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title UpdatedEVMScheduler
 * @dev EVM contract that DIRECTLY triggers Cadence bridge calls
 * This is your updated contract that calls NativeEVMBridge automatically!
 */
contract UpdatedEVMScheduler {
    
    // Events that trigger Cadence bridge calls
    event BridgeCallRequested(
        uint256 indexed scheduleId,
        string recipient,
        uint256 amount,
        uint256 delaySeconds,
        uint256 timestamp,
        address indexed caller
    );
    
    event ScheduleCreated(
        uint256 indexed scheduleId,
        address indexed creator,
        string recipient,
        uint256 amount,
        uint256 delaySeconds,
        bool bridgeTriggered
    );
    
    event CadenceBridgeTriggered(
        uint256 indexed scheduleId,
        string cadenceContractAddress,
        string transactionName
    );
    
    // State variables
    mapping(uint256 => ScheduleInfo) public schedules;
    uint256 public nextScheduleId;
    address public owner;
    
    // Your deployed Cadence contract addresses
    string public constant CADENCE_BRIDGE_ADDRESS = "0x9f3e9372a21a4f15"; // NativeEVMBridge
    string public constant CADENCE_TRANSACTION = "NativeEVMSchedule.cdc";
    
    struct ScheduleInfo {
        uint256 id;
        string recipient;
        uint256 amount;
        uint256 delaySeconds;
        uint256 createdAt;
        address creator;
        bool bridgeTriggered;
        bool executed;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        nextScheduleId = 1;
    }
    
    /**
     * @dev Schedule a payment that AUTOMATICALLY triggers Cadence bridge
     * This is the main function that connects EVM → Cadence!
     */
    function schedulePayment(
        string memory recipient,
        uint256 amount,
        uint256 delaySeconds
    ) external payable returns (uint256) {
        require(bytes(recipient).length > 0, "Invalid recipient");
        require(amount > 0, "Amount must be positive");
        require(delaySeconds > 0, "Delay must be positive");
        
        uint256 scheduleId = nextScheduleId++;
        
        // Store schedule info
        schedules[scheduleId] = ScheduleInfo({
            id: scheduleId,
            recipient: recipient,
            amount: amount,
            delaySeconds: delaySeconds,
            createdAt: block.timestamp,
            creator: msg.sender,
            bridgeTriggered: false,
            executed: false
        });
        
        // 🚀 TRIGGER CADENCE BRIDGE AUTOMATICALLY!
        _triggerCadenceBridge(scheduleId, recipient, amount, delaySeconds);
        
        // Mark as bridge triggered
        schedules[scheduleId].bridgeTriggered = true;
        
        emit ScheduleCreated(
            scheduleId,
            msg.sender,
            recipient,
            amount,
            delaySeconds,
            true
        );
        
        return scheduleId;
    }
    
    /**
     * @dev Internal function that triggers the Cadence bridge
     * This emits the event that your bridge listener catches
     */
    function _triggerCadenceBridge(
        uint256 scheduleId,
        string memory recipient,
        uint256 amount,
        uint256 delaySeconds
    ) internal {
        
        // Emit the bridge call event
        emit BridgeCallRequested(
            scheduleId,
            recipient,
            amount,
            delaySeconds,
            block.timestamp,
            msg.sender
        );
        
        // Emit Cadence-specific event
        emit CadenceBridgeTriggered(
            scheduleId,
            CADENCE_BRIDGE_ADDRESS,
            CADENCE_TRANSACTION
        );
    }
    
    /**
     * @dev Manual trigger for existing schedules (admin only)
     */
    function manualTriggerBridge(uint256 scheduleId) external onlyOwner {
        require(scheduleId > 0 && scheduleId < nextScheduleId, "Invalid schedule ID");
        require(!schedules[scheduleId].bridgeTriggered, "Already triggered");
        
        ScheduleInfo storage schedule = schedules[scheduleId];
        
        _triggerCadenceBridge(
            scheduleId,
            schedule.recipient,
            schedule.amount,
            schedule.delaySeconds
        );
        
        schedule.bridgeTriggered = true;
    }
    
    /**
     * @dev Batch schedule multiple payments
     */
    function batchSchedulePayments(
        string[] memory recipients,
        uint256[] memory amounts,
        uint256[] memory delays
    ) external payable returns (uint256[] memory) {
        require(recipients.length == amounts.length, "Array length mismatch");
        require(amounts.length == delays.length, "Array length mismatch");
        require(recipients.length > 0, "Empty arrays");
        
        uint256[] memory scheduleIds = new uint256[](recipients.length);
        
        for (uint256 i = 0; i < recipients.length; i++) {
            // Call the external function using this.
            scheduleIds[i] = this.schedulePayment(recipients[i], amounts[i], delays[i]);
        }
        
        return scheduleIds;
    }
    
    /**
     * @dev Get schedule information
     */
    function getSchedule(uint256 scheduleId) external view returns (
        uint256 id,
        string memory recipient,
        uint256 amount,
        uint256 delaySeconds,
        uint256 createdAt,
        address creator,
        bool bridgeTriggered,
        bool executed
    ) {
        require(scheduleId > 0 && scheduleId < nextScheduleId, "Invalid schedule ID");
        
        ScheduleInfo memory schedule = schedules[scheduleId];
        return (
            schedule.id,
            schedule.recipient,
            schedule.amount,
            schedule.delaySeconds,
            schedule.createdAt,
            schedule.creator,
            schedule.bridgeTriggered,
            schedule.executed
        );
    }
    
    /**
     * @dev Get all schedules for a recipient
     */
    function getSchedulesByRecipient(string memory recipient) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count schedules for this recipient
        for (uint256 i = 1; i < nextScheduleId; i++) {
            if (keccak256(bytes(schedules[i].recipient)) == keccak256(bytes(recipient))) {
                count++;
            }
        }
        
        // Create array and populate
        uint256[] memory recipientSchedules = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i < nextScheduleId; i++) {
            if (keccak256(bytes(schedules[i].recipient)) == keccak256(bytes(recipient))) {
                recipientSchedules[index] = i;
                index++;
            }
        }
        
        return recipientSchedules;
    }
    
    /**
     * @dev Get schedules by creator
     */
    function getSchedulesByCreator(address creator) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count schedules for this creator
        for (uint256 i = 1; i < nextScheduleId; i++) {
            if (schedules[i].creator == creator) {
                count++;
            }
        }
        
        // Create array and populate
        uint256[] memory creatorSchedules = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i < nextScheduleId; i++) {
            if (schedules[i].creator == creator) {
                creatorSchedules[index] = i;
                index++;
            }
        }
        
        return creatorSchedules;
    }
    
    /**
     * @dev Get total number of schedules
     */
    function getTotalSchedules() external view returns (uint256) {
        return nextScheduleId - 1;
    }
    
    /**
     * @dev Get Cadence bridge information
     */
    function getCadenceBridgeInfo() external pure returns (
        string memory bridgeAddress,
        string memory transactionName
    ) {
        return (CADENCE_BRIDGE_ADDRESS, CADENCE_TRANSACTION);
    }
    
    /**
     * @dev Emergency function to withdraw contract balance (owner only)
     */
    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
    
    /**
     * @dev Transfer ownership
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        owner = newOwner;
    }
    
    /**
     * @dev Receive function to accept ETH
     */
    receive() external payable {}
}
