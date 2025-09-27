// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title EVMScheduler
 * @dev EVM contract that triggers Cadence scheduling via Flow EVM bridge
 * @author Your Name
 */
contract EVMScheduler {
    
    // Events
    event CadenceScheduleTriggered(
        uint256 indexed scheduleId,
        address indexed recipient,
        uint256 amount,
        uint256 delaySeconds,
        string cadenceTxId
    );
    
    event ScheduleExecuted(
        uint256 indexed scheduleId,
        bool success
    );
    
    // State variables
    mapping(uint256 => ScheduleInfo) public schedules;
    uint256 public nextScheduleId;
    address public owner;
    
    // Cadence contract address (deployed on testnet)
    // Note: Flow addresses are different from Ethereum addresses
    // We'll store this as a string or use a mapping to handle Flow addresses
    string public constant CADENCE_SCHEDULER_ADDRESS = "9f3e9372a21a4f15";
    
    struct ScheduleInfo {
        uint256 id;
        address recipient;
        uint256 amount;
        uint256 delaySeconds;
        uint256 createdAt;
        bool executed;
        string cadenceTxId;
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
     * @dev Schedule a payment via Cadence
     * @param recipient The recipient address
     * @param amount The amount to send
     * @param delaySeconds Delay before execution
     */
    function schedulePayment(
        address recipient,
        uint256 amount,
        uint256 delaySeconds
    ) external returns (uint256) {
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be positive");
        require(delaySeconds > 0, "Delay must be positive");
        
        uint256 scheduleId = nextScheduleId++;
        
        schedules[scheduleId] = ScheduleInfo({
            id: scheduleId,
            recipient: recipient,
            amount: amount,
            delaySeconds: delaySeconds,
            createdAt: block.timestamp,
            executed: false,
            cadenceTxId: ""
        });
        
        // Trigger Cadence scheduling
        string memory cadenceTxId = _triggerCadenceSchedule(
            scheduleId,
            recipient,
            amount,
            delaySeconds
        );
        
        schedules[scheduleId].cadenceTxId = cadenceTxId;
        
        emit CadenceScheduleTriggered(
            scheduleId,
            recipient,
            amount,
            delaySeconds,
            cadenceTxId
        );
        
        return scheduleId;
    }
    
    /**
     * @dev Execute a scheduled payment
     * @param scheduleId The schedule ID to execute
     */
    function executeSchedule(uint256 scheduleId) external {
        ScheduleInfo storage schedule = schedules[scheduleId];
        require(schedule.id != 0, "Schedule not found");
        require(!schedule.executed, "Already executed");
        require(
            block.timestamp >= schedule.createdAt + schedule.delaySeconds,
            "Not ready for execution"
        );
        
        // Mark as executed
        schedule.executed = true;
        
        emit ScheduleExecuted(scheduleId, true);
    }
    
    /**
     * @dev Get schedule information
     * @param scheduleId The schedule ID
     */
    function getSchedule(uint256 scheduleId) external view returns (ScheduleInfo memory) {
        return schedules[scheduleId];
    }
    
    /**
     * @dev Get all schedules for a recipient
     * @param recipient The recipient address
     */
    function getSchedulesForRecipient(address recipient) external view returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count matching schedules
        for (uint256 i = 1; i < nextScheduleId; i++) {
            if (schedules[i].recipient == recipient) {
                count++;
            }
        }
        
        // Create array and populate
        uint256[] memory recipientSchedules = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 1; i < nextScheduleId; i++) {
            if (schedules[i].recipient == recipient) {
                recipientSchedules[index] = i;
                index++;
            }
        }
        
        return recipientSchedules;
    }
    
    /**
     * @dev Get the Cadence scheduler address
     */
    function getCadenceSchedulerAddress() external pure returns (string memory) {
        return CADENCE_SCHEDULER_ADDRESS;
    }
    
    /**
     * @dev Internal function to trigger Cadence scheduling
     * This would typically involve calling a Cadence contract via Flow EVM bridge
     */
    function _triggerCadenceSchedule(
        uint256 scheduleId,
        address recipient,
        uint256 amount,
        uint256 delaySeconds
    ) internal returns (string memory) {
        // In a real implementation, this would:
        // 1. Call the Cadence contract via Flow EVM bridge using CADENCE_SCHEDULER_ADDRESS
        // 2. Pass the scheduling parameters to the Flow contract
        // 3. Return the actual Cadence transaction ID
        
        // For now, we'll simulate this with a mock transaction ID
        // that includes the Flow contract address for reference
        string memory mockTxId = string(abi.encodePacked(
            "cadence_tx_",
            _uint2str(scheduleId),
            "_to_",
            CADENCE_SCHEDULER_ADDRESS,
            "_",
            _uint2str(block.timestamp)
        ));
        
        return mockTxId;
    }
    
    /**
     * @dev Convert uint to string
     */
    function _uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
    /**
     * @dev Emergency function to update owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        owner = newOwner;
    }
}
