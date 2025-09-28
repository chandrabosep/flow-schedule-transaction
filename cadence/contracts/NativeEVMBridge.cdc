import "EVM"
import "SimpleFlowScheduler"

/// 100% On-Chain EVM-Cadence Bridge 
/// Uses SimpleFlowScheduler for automatic execution - No external services required!
access(all) contract NativeEVMBridge {
    
    // Events
    access(all) event EVMScheduleReceived(
        evmScheduleId: UInt64,
        cadenceScheduleId: UInt64,
        recipient: String,
        amount: UFix64,
        delaySeconds: UFix64
    )
    
    access(all) event DirectScheduleCreated(
        cadenceScheduleId: UInt64,
        executionTime: UFix64
    )
    
    /// Schedule a payment directly using SimpleFlowScheduler
    /// This is called directly from EVM contracts - NO EXTERNAL SERVICE NEEDED!
    access(all) fun scheduleEVMPayment(
        evmScheduleId: UInt64,
        recipient: String,
        amount: UFix64,
        delaySeconds: UFix64
    ): UInt64 {
        // Create scheduled payment using the existing SimpleFlowScheduler
        // This will execute automatically when the time comes!
        let cadenceScheduleId = SimpleFlowScheduler.schedulePayment(
            recipient: recipient,
            amount: amount,
            delaySeconds: delaySeconds
        )
        
        // Calculate execution time for logging
        let executionTime = getCurrentBlock().timestamp + delaySeconds
        
        // Emit events
        emit EVMScheduleReceived(
            evmScheduleId: evmScheduleId,
            cadenceScheduleId: cadenceScheduleId,
            recipient: recipient,
            amount: amount,
            delaySeconds: delaySeconds
        )
        
        emit DirectScheduleCreated(
            cadenceScheduleId: cadenceScheduleId,
            executionTime: executionTime
        )
        
        log("🌉 Native EVM bridge: EVM ID ".concat(evmScheduleId.toString())
            .concat(" -> Cadence ID ").concat(cadenceScheduleId.toString()))
        log("🚀 Payment will execute automatically at ".concat(executionTime.toString()))
        log("✅ 100% on-chain - no external services required!")
        
        return cadenceScheduleId
    }
    
    /// Get scheduled payment info (for EVM queries)
    access(all) fun getScheduledPayment(cadenceScheduleId: UInt64): SimpleFlowScheduler.ScheduledPayment? {
        return SimpleFlowScheduler.getScheduledPayment(id: cadenceScheduleId)
    }
    
    /// Execute a scheduled payment immediately (if ready)
    access(all) fun executeScheduledPayment(cadenceScheduleId: UInt64) {
        SimpleFlowScheduler.executePayment(id: cadenceScheduleId)
    }
    
    /// Get all scheduled payments
    access(all) fun getAllScheduledPayments(): {UInt64: SimpleFlowScheduler.ScheduledPayment} {
        return SimpleFlowScheduler.getAllScheduledPayments()
    }
    
    init() {
        log("NativeEVMBridge initialized - 100% on-chain scheduling ready!")
    }
}