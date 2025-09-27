import "SimpleFlowScheduler"
import "FungibleToken"
import "FlowToken"

/// Transaction to be triggered from EVM
/// This transaction receives scheduling parameters from EVM and creates a scheduled payment
transaction(
    recipient: String,
    amount: UFix64,
    delaySeconds: UFix64,
    evmScheduleId: UInt64
) {
    
    let scheduleId: UInt64
    
    prepare(signer: auth(BorrowValue) &Account) {
        // Access the deployed SimpleFlowScheduler contract
        let scheduler = SimpleFlowScheduler
        
        // Schedule the payment using the Cadence contract
        self.scheduleId = scheduler.schedulePayment(
            recipient: recipient,
            amount: amount,
            delaySeconds: delaySeconds
        )
        
        log("EVMScheduleTrigger: Scheduled payment with ID: ".concat(self.scheduleId.toString()))
        log("EVMScheduleTrigger: EVM Schedule ID: ".concat(evmScheduleId.toString()))
        log("EVMScheduleTrigger: Recipient: ".concat(recipient))
        log("EVMScheduleTrigger: Amount: ".concat(amount.toString()))
        log("EVMScheduleTrigger: Delay: ".concat(delaySeconds.toString()))
    }
    
    execute {
        log("EVMScheduleTrigger: Payment scheduled successfully!")
        log("EVMScheduleTrigger: Cadence Schedule ID: ".concat(self.scheduleId.toString()))
    }
}
