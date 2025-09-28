import "EVM"
import "SimpleFlowScheduler"

/// Listen for EVM bridge events and trigger Cadence scheduling
/// This transaction processes EVM events and creates scheduled payments
transaction(
    evmContractAddress: String,
    fromBlock: UInt64,
    toBlock: UInt64?
) {
    
    let processedEvents: [EVMBridgeEvent]
    
    prepare(signer: auth(BorrowValue) &Account) {
        self.processedEvents = []
        
        // Get the signer's COA (Cadence Owned Account)
        let coa = signer.storage.borrow<auth(EVM.Call) &EVM.CadenceOwnedAccount>(from: /storage/evm)
            ?? panic("Could not borrow COA from provided account")
        
        // Convert hex string to EVM address
        let contractAddress = EVM.addressFromString(evmContractAddress)
        
        // Get events from the EVM contract
        // In a real implementation, this would query EVM events
        // For now, we'll simulate processing bridge events
        
        log("EVMBridgeListener: Processing events from block ".concat(fromBlock.toString()))
        log("EVMBridgeListener: EVM Contract: ".concat(evmContractAddress))
        
        // Simulate processing a bridge event
        let mockEvent = EVMBridgeEvent(
            scheduleId: 1,
            recipient: "0x1234567890abcdef12345678",
            amount: 10.0,
            delaySeconds: 60.0,
            timestamp: getCurrentBlock().timestamp
        )
        
        self.processedEvents.append(mockEvent)
    }
    
    execute {
        // Process each bridge event and create scheduled payments
        for event in self.processedEvents {
            let scheduleId = SimpleFlowScheduler.schedulePayment(
                recipient: event.recipient,
                amount: event.amount,
                delaySeconds: event.delaySeconds
            )
            
            log("EVMBridgeListener: Created schedule ID ".concat(scheduleId.toString()).concat(" for EVM schedule ").concat(event.scheduleId.toString()))
        }
        
        log("EVMBridgeListener: Processed ".concat(self.processedEvents.length.toString()).concat(" bridge events"))
    }
}

/// Struct to represent an EVM bridge event
access(all) struct EVMBridgeEvent {
    access(all) let scheduleId: UInt64
    access(all) let recipient: String
    access(all) let amount: UFix64
    access(all) let delaySeconds: UFix64
    access(all) let timestamp: UFix64
    
    init(scheduleId: UInt64, recipient: String, amount: UFix64, delaySeconds: UFix64, timestamp: UFix64) {
        self.scheduleId = scheduleId
        self.recipient = recipient
        self.amount = amount
        self.delaySeconds = delaySeconds
        self.timestamp = timestamp
    }
}

