import "EVM"
import "SimpleFlowScheduler"

/// EVM-Cadence Bridge Contract
/// Handles direct cross-chain calls from EVM to Cadence scheduling
access(all) contract EVMBridge {
    
    // Events
    access(all) event EVMScheduleReceived(
        evmScheduleId: UInt64,
        cadenceScheduleId: UInt64,
        recipient: String,
        amount: UFix64,
        delaySeconds: UFix64,
        evmContractAddress: String
    )
    
    access(all) event BridgeCallProcessed(
        evmTxHash: String,
        cadenceScheduleId: UInt64,
        success: Bool
    )
    
    // Storage paths
    access(all) let BridgeAdminStoragePath: StoragePath
    access(all) let BridgeAdminPublicPath: PublicPath
    
    // Bridge admin resource
    access(all) resource BridgeAdmin {
        
        /// Process an EVM bridge call and create Cadence scheduled payment
        access(all) fun processEVMScheduleCall(
            evmContractAddress: String,
            evmScheduleId: UInt64,
            recipient: String,
            amount: UFix64,
            delaySeconds: UFix64,
            evmTxHash: String
        ): UInt64 {
            // Validate inputs
            pre {
                amount > 0.0: "Amount must be positive"
                delaySeconds >= 0.0: "Delay cannot be negative"
                recipient.length > 0: "Recipient cannot be empty"
            }
            
            // Create scheduled payment in Cadence
            let cadenceScheduleId = SimpleFlowScheduler.schedulePayment(
                recipient: recipient,
                amount: amount,
                delaySeconds: delaySeconds
            )
            
            // Emit events
            emit EVMScheduleReceived(
                evmScheduleId: evmScheduleId,
                cadenceScheduleId: cadenceScheduleId,
                recipient: recipient,
                amount: amount,
                delaySeconds: delaySeconds,
                evmContractAddress: evmContractAddress
            )
            
            emit BridgeCallProcessed(
                evmTxHash: evmTxHash,
                cadenceScheduleId: cadenceScheduleId,
                success: true
            )
            
            return cadenceScheduleId
        }
        
        /// Execute a scheduled payment (can be called from EVM)
        access(all) fun executeScheduledPayment(scheduleId: UInt64) {
            SimpleFlowScheduler.executePayment(id: scheduleId)
        }
        
        /// Get scheduled payment info (for EVM queries)
        access(all) fun getScheduledPayment(scheduleId: UInt64): SimpleFlowScheduler.ScheduledPayment? {
            return SimpleFlowScheduler.getScheduledPayment(id: scheduleId)
        }
    }
    
    // Public interface for bridge operations
    access(all) resource interface BridgePublic {
        access(all) fun processEVMCall(
            evmContractAddress: String,
            evmScheduleId: UInt64,
            recipient: String,
            amount: UFix64,
            delaySeconds: UFix64,
            evmTxHash: String
        ): UInt64
    }
    
    // Bridge resource with public interface
    access(all) resource Bridge: BridgePublic {
        
        access(all) fun processEVMCall(
            evmContractAddress: String,
            evmScheduleId: UInt64,
            recipient: String,
            amount: UFix64,
            delaySeconds: UFix64,
            evmTxHash: String
        ): UInt64 {
            // This would typically have access controls
            // For now, allow any caller
            
            let admin = EVMBridge.account.storage.borrow<&BridgeAdmin>(
                from: EVMBridge.BridgeAdminStoragePath
            ) ?? panic("Could not borrow bridge admin")
            
            return admin.processEVMScheduleCall(
                evmContractAddress: evmContractAddress,
                evmScheduleId: evmScheduleId,
                recipient: recipient,
                amount: amount,
                delaySeconds: delaySeconds,
                evmTxHash: evmTxHash
            )
        }
    }
    
    /// Create a new bridge resource
    access(all) fun createBridge(): @Bridge {
        return <- create Bridge()
    }
    
    /// Get bridge public capability
    access(all) fun getBridgePublic(): Capability<&{BridgePublic}> {
        let cap = self.account.capabilities.get<&{BridgePublic}>(self.BridgeAdminPublicPath)
        if !cap.check() {
            panic("Bridge public capability not found or invalid")
        }
        return cap
    }
    
    /// Process EVM bridge call (public function)
    access(all) fun processEVMBridgeCall(
        evmContractAddress: String,
        evmScheduleId: UInt64,
        recipient: String,
        amount: UFix64,
        delaySeconds: UFix64,
        evmTxHash: String
    ): UInt64 {
        let bridge = self.getBridgePublic().borrow()
            ?? panic("Could not borrow bridge public reference")
            
        return bridge.processEVMCall(
            evmContractAddress: evmContractAddress,
            evmScheduleId: evmScheduleId,
            recipient: recipient,
            amount: amount,
            delaySeconds: delaySeconds,
            evmTxHash: evmTxHash
        )
    }
    
    init() {
        // Set storage paths
        self.BridgeAdminStoragePath = /storage/EVMBridgeAdmin
        self.BridgeAdminPublicPath = /public/EVMBridge
        
        // Create and store bridge admin
        let admin <- create BridgeAdmin()
        self.account.storage.save(<-admin, to: self.BridgeAdminStoragePath)
        
        // Create and link bridge public capability
        let bridge <- create Bridge()
        self.account.storage.save(<-bridge, to: /storage/EVMBridge)
        
        self.account.capabilities.publish(
            self.account.capabilities.storage.issue<&{BridgePublic}>(/storage/EVMBridge),
            at: self.BridgeAdminPublicPath
        )
    }
}
