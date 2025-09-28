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
    
    event BridgeCallRequested(
        uint256 indexed scheduleId,
        string recipient,
        uint256 amount,
        uint256 delaySeconds,
        uint256 timestamp
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
     * This calls the Cadence contract directly via Flow EVM bridge
     */
    function _triggerCadenceSchedule(
        uint256 scheduleId,
        address recipient,
        uint256 amount,
        uint256 delaySeconds
    ) internal returns (string memory) {
        // Convert EVM address to Flow address format
        string memory flowRecipient = _addressToFlowString(recipient);
        
        // Convert amount to Flow format (UFix64)
        uint256 flowAmount = amount;
        
        // Direct cross-chain call to Cadence
        bool success = _callCadenceScheduler(
            scheduleId,
            flowRecipient,
            flowAmount,
            delaySeconds
        );
        
        if (success) {
            // Emit success event
            emit CadenceScheduleTriggered(
                scheduleId,
                recipient,
                amount,
                delaySeconds,
                "direct_bridge_call"
            );
        } else {
            // Fallback: emit event for off-chain processing
            emit BridgeCallRequested(
                scheduleId,
                flowRecipient,
                flowAmount,
                delaySeconds,
                block.timestamp
            );
        }
        
        // Return transaction ID
        string memory txId = string(abi.encodePacked(
            "bridge_",
            _uint2str(scheduleId),
            "_",
            _uint2str(block.timestamp)
        ));
        
        return txId;
    }
    
    /**
     * @dev Direct call to Cadence scheduler using Flow EVM bridge
     */
    function _callCadenceScheduler(
        uint256 scheduleId,
        string memory recipient,
        uint256 amount,
        uint256 delaySeconds
    ) internal returns (bool) {
        // Flow EVM Bridge Interface
        // This uses Flow's built-in EVM-Cadence bridge
        
        // Prepare Cadence transaction data
        bytes memory cadenceCallData = abi.encode(
            "SimpleFlowScheduler.schedulePayment",
            recipient,
            amount,
            delaySeconds,
            scheduleId
        );
        
        // Call Flow bridge precompile (hypothetical address)
        // In reality, Flow provides specific precompile addresses
        address FLOW_BRIDGE_PRECOMPILE = address(0x0000000000000000000000000000000000000100);
        
        // Make the cross-chain call
        (bool success, bytes memory result) = FLOW_BRIDGE_PRECOMPILE.call(
            cadenceCallData
        );
        
        if (success) {
            // Decode the result to get Cadence schedule ID
            // uint256 cadenceScheduleId = abi.decode(result, (uint256));
            return true;
        }
        
        return false;
    }
    
    /**
     * @dev Convert EVM address to Flow address string
     */
    function _addressToFlowString(address addr) internal pure returns (string memory) {
        bytes memory addressBytes = abi.encodePacked(addr);
        bytes memory result = new bytes(40);
        
        for (uint256 i = 0; i < 20; i++) {
            uint8 value = uint8(addressBytes[i]);
            result[i * 2] = _byteToHex(value / 16);
            result[i * 2 + 1] = _byteToHex(value % 16);
        }
        
        return string(abi.encodePacked("0x", result));
    }
    
    /**
     * @dev Convert byte to hex character
     */
    function _byteToHex(uint8 value) internal pure returns (bytes1) {
        if (value < 10) {
            return bytes1(uint8(bytes1('0')) + value);
        } else {
            return bytes1(uint8(bytes1('a')) + value - 10);
        }
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
