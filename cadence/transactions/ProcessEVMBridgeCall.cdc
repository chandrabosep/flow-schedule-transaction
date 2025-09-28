import "EVM"
import "EVMBridge"
import "SimpleFlowScheduler"

/// Process direct EVM bridge call
/// This transaction can be called directly from EVM contracts via Flow's bridge
transaction(
    evmContractAddress: String,
    evmScheduleId: UInt64,
    recipient: String,
    amount: UFix64,
    delaySeconds: UFix64,
    evmTxHash: String
) {
    
    let cadenceScheduleId: UInt64
    
    prepare(signer: auth(BorrowValue) &Account) {
        // Get EVM transaction hash from context if available
        let actualEvmTxHash = evmTxHash.length > 0 ? evmTxHash : "direct_bridge_call"
        
        // Process the bridge call
        self.cadenceScheduleId = EVMBridge.processEVMBridgeCall(
            evmContractAddress: evmContractAddress,
            evmScheduleId: evmScheduleId,
            recipient: recipient,
            amount: amount,
            delaySeconds: delaySeconds,
            evmTxHash: actualEvmTxHash
        )
        
        log("ProcessEVMBridgeCall: EVM contract ".concat(evmContractAddress))
        log("ProcessEVMBridgeCall: EVM schedule ID ".concat(evmScheduleId.toString()))
        log("ProcessEVMBridgeCall: Created Cadence schedule ID ".concat(self.cadenceScheduleId.toString()))
    }
    
    execute {
        log("ProcessEVMBridgeCall: Bridge call processed successfully!")
        log("ProcessEVMBridgeCall: EVM→Cadence mapping: ".concat(evmScheduleId.toString()).concat("→").concat(self.cadenceScheduleId.toString()))
        
        // Return the Cadence schedule ID (this could be captured by EVM)
        // In a real bridge implementation, this would be returned to the EVM contract
    }
    
    post {
        // Verify the scheduled payment was created
        let payment = SimpleFlowScheduler.getScheduledPayment(id: self.cadenceScheduleId)
        assert(payment != nil, message: "Scheduled payment was not created")
        assert(payment!.amount == amount, message: "Amount mismatch")
        assert(payment!.recipient == recipient, message: "Recipient mismatch")
    }
}

