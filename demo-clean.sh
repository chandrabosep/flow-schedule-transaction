#!/bin/bash

# Clean Scheduling Demo
# This script demonstrates basic scheduling capabilities

set -e

echo "🚀 Starting Clean Scheduling Demo"
echo "================================="

# Demo 1: Test Counter (basic functionality)
echo "🔢 Demo 1: Basic Counter Test"
echo "============================="
echo "Testing basic Flow functionality..."

flow transactions send cadence/transactions/IncrementCounter.cdc \
    --network emulator \
    --signer emulator-account

echo "✅ Counter incremented successfully!"
echo ""

# Demo 2: Check counter value
echo "📊 Demo 2: Check Counter Value"
echo "============================="
echo "Retrieving counter value..."

flow scripts execute cadence/scripts/GetCounter.cdc --network emulator

echo "✅ Counter value retrieved!"
echo ""

# Demo 3: Test SimpleFlowScheduler
echo "📅 Demo 3: SimpleFlowScheduler Test"
echo "==================================="
echo "Testing SimpleFlowScheduler contract..."

# Create a simple transaction to interact with the scheduler
cat > test_scheduler.cdc << 'EOF'
import "SimpleFlowScheduler"

transaction {
    prepare(signer: auth(BorrowValue) &Account) {
        // Access the deployed contract
        let schedulerRef = getAccount(0xf8d6e0586b0a20c7).getContract(name: "SimpleFlowScheduler")
        let scheduler = schedulerRef as! &SimpleFlowScheduler
        
        // Schedule a payment
        let paymentId = scheduler.schedulePayment(
            recipient: "0x1234567890abcdef",
            amount: 10.0,
            delaySeconds: 60.0
        )
        log("Payment scheduled with ID: ".concat(paymentId.toString()))
    }
}
EOF

flow transactions send test_scheduler.cdc \
    --network emulator \
    --signer emulator-account

echo "✅ Payment scheduled using SimpleFlowScheduler!"
echo ""

# Demo 4: Check scheduled payments
echo "🔍 Demo 4: Check Scheduled Payments"
echo "==================================="
echo "Retrieving all scheduled payments..."

cat > get_payments.cdc << 'EOF'
import "SimpleFlowScheduler"

access(all) fun main(): {UInt64: SimpleFlowScheduler.ScheduledPayment} {
    let schedulerRef = getAccount(0xf8d6e0586b0a20c7).getContract(name: "SimpleFlowScheduler")
    let scheduler = schedulerRef as! &SimpleFlowScheduler
    return scheduler.getAllScheduledPayments()
}
EOF

flow scripts execute get_payments.cdc --network emulator

echo "✅ Retrieved scheduled payments!"
echo ""

# Demo 5: Schedule another payment
echo "💰 Demo 5: Schedule Another Payment"
echo "==================================="
echo "Scheduling a second payment..."

cat > schedule_second.cdc << 'EOF'
import "SimpleFlowScheduler"

transaction {
    prepare(signer: auth(BorrowValue) &Account) {
        let schedulerRef = getAccount(0xf8d6e0586b0a20c7).getContract(name: "SimpleFlowScheduler")
        let scheduler = schedulerRef as! &SimpleFlowScheduler
        
        let paymentId = scheduler.schedulePayment(
            recipient: "0xabcdef1234567890",
            amount: 25.0,
            delaySeconds: 120.0
        )
        log("Second payment scheduled with ID: ".concat(paymentId.toString()))
    }
}
EOF

flow transactions send schedule_second.cdc \
    --network emulator \
    --signer emulator-account

echo "✅ Second payment scheduled!"
echo ""

# Demo 6: Check all payments again
echo "📊 Demo 6: Check All Payments"
echo "============================"
echo "Retrieving all scheduled payments again..."

flow scripts execute get_payments.cdc --network emulator

echo "✅ All payments retrieved!"
echo ""

# Cleanup
rm -f test_scheduler.cdc get_payments.cdc schedule_second.cdc

# Display what we have
echo "🎯 Core Scheduling Features:"
echo "============================="
echo ""
echo "✅ Basic Payment Scheduling:"
echo "   • Schedule payments with specific delays"
echo "   • Execute payments at scheduled times"
echo "   • Track payment status and history"
echo "   • Multiple concurrent payments supported"
echo ""
echo "✅ EVM Integration Ready:"
echo "   • EVM contracts can trigger Cadence scheduling"
echo "   • Cross-VM bridge operations supported"
echo "   • Comprehensive Solidity contracts available"
echo ""

# Show the Solidity contract features
echo "📄 Your EVM Contract (ComprehensiveEVMScheduler.sol):"
echo "==================================================="
echo ""
echo "The provided Solidity contract includes:"
echo "• scheduleCalendarDeFiEvent() - Calendar-based DeFi automation"
echo "• enableDeFiAutomationWithAI() - AI-powered DeFi strategies"
echo "• createIntelligentSubscription() - Smart recurring payments"
echo "• setupGovernanceAutomation() - Automated DAO participation"
echo "• triggerAIScheduling() - Direct AI optimization"
echo ""

# Integration examples
echo "🔧 Integration Examples:"
echo "======================="
echo ""
echo "From your EVM contract, you can now trigger:"
echo ""
echo "1. Schedule a payment:"
echo "   contract.scheduleFlowPayment(recipient, amount, delay, currency)"
echo ""
echo "2. Enable DeFi automation:"
echo "   contract.enableDeFiAutomationWithAI(protocol, type, interval, threshold, true, 'gpt-4o')"
echo ""
echo "3. Create intelligent subscriptions:"
echo "   contract.createIntelligentSubscription(merchant, amount, interval, maxPayments, calendarId, true)"
echo ""
echo "4. Setup governance automation:"
echo "   contract.setupGovernanceAutomation(dao, votePreference, votingPower, 'gpt-4o', true)"
echo ""
echo "5. Trigger direct AI scheduling:"
echo "   contract.triggerAIScheduling(txType, params, 'gpt-4o', urgency, gasOptimization)"
echo ""

# Next steps
echo "🚀 Next Steps:"
echo "=============="
echo ""
echo "1. Deploy your EVM contracts to Flow EVM:"
echo "   Use the provided ComprehensiveEVMScheduler.sol"
echo ""
echo "2. Integrate with your dApp:"
echo "   Use the JavaScript examples in examples/comprehensive-demo.js"
echo ""
echo "3. Configure for your use cases:"
echo "   Set up user preferences and risk parameters"
echo ""

echo "🎉 Demo completed successfully!"
echo ""
echo "Your system now supports:"
echo "• EVM contracts triggering Cadence scheduling"
echo "• Basic payment scheduling with timing control"
echo "• Cross-VM bridge operations"
echo "• Ready for advanced features (AI, calendar, DeFi automation)"
echo ""
echo "🚀 Your EVM-to-Cadence scheduling system is ready for development!"
