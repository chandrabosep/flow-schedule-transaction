import "NativeEVMBridge"

/// 100% On-Chain EVM Payment Scheduling
/// This transaction can be called directly from EVM contracts
/// NO BRIDGE SERVICE REQUIRED!
transaction(
    evmScheduleId: UInt64,
    recipient: String,
    amount: UFix64,
    delaySeconds: UFix64
) {
    
    var cadenceScheduleId: UInt64
    
    prepare(signer: &Account) {
        log("🌉 Native EVM scheduling: EVM ID ".concat(evmScheduleId.toString()))
        log("💰 Payment: ".concat(amount.toString()).concat(" to ").concat(recipient))
        log("⏰ Delay: ".concat(delaySeconds.toString()).concat(" seconds"))
        
        // Initialize the variable
        self.cadenceScheduleId = 0
    }
    
    execute {
        // Schedule the payment using native on-chain scheduling
        self.cadenceScheduleId = NativeEVMBridge.scheduleEVMPayment(
            evmScheduleId: evmScheduleId,
            recipient: recipient,
            amount: amount,
            delaySeconds: delaySeconds
        )
        
        log("✅ Native scheduled payment created!")
        log("🆔 EVM ID: ".concat(evmScheduleId.toString()).concat(" -> Cadence ID: ").concat(self.cadenceScheduleId.toString()))
        log("🚀 Payment will execute automatically in ".concat(delaySeconds.toString()).concat(" seconds"))
        log("🌉 100% on-chain - no external services required!")
    }
}