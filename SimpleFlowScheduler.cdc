access(all) contract SimpleFlowScheduler {

    access(all) event PaymentScheduled(
        id: UInt64,
        sender: String,
        recipient: String,
        amount: UFix64,
        scheduledTime: UFix64
    )

    access(all) event PaymentExecuted(
        id: UInt64,
        success: Bool
    )

    access(all) var nextId: UInt64
    access(all) var scheduledPayments: {UInt64: ScheduledPayment}

    access(all) struct ScheduledPayment {
        access(all) let id: UInt64
        access(all) let sender: String
        access(all) let recipient: String
        access(all) let amount: UFix64
        access(all) let scheduledTime: UFix64
        access(all) let executed: Bool

        init(id: UInt64, sender: String, recipient: String, amount: UFix64, scheduledTime: UFix64, executed: Bool) {
            self.id = id
            self.sender = sender
            self.recipient = recipient
            self.amount = amount
            self.scheduledTime = scheduledTime
            self.executed = executed
        }
    }

    access(all) fun schedulePayment(recipient: String, amount: UFix64, delaySeconds: UFix64): UInt64 {
        let id = self.nextId
        self.nextId = self.nextId + 1
        
        let scheduledTime = getCurrentBlock().timestamp + delaySeconds
        let payment = ScheduledPayment(
            id: id,
            sender: "0xEVMBridge",
            recipient: recipient,
            amount: amount,
            scheduledTime: scheduledTime,
            executed: false
        )
        
        self.scheduledPayments[id] = payment
        
        emit PaymentScheduled(
            id: id,
            sender: payment.sender,
            recipient: recipient,
            amount: amount,
            scheduledTime: scheduledTime
        )
        
        return id
    }

    access(all) fun executePayment(id: UInt64) {
        let payment = self.scheduledPayments[id] ?? panic("Payment not found")
        
        if payment.executed {
            panic("Payment already executed")
        }
        
        if getCurrentBlock().timestamp < payment.scheduledTime {
            panic("Payment not ready for execution")
        }
        
        // Create new payment with executed = true
        let executedPayment = ScheduledPayment(
            id: payment.id,
            sender: payment.sender,
            recipient: payment.recipient,
            amount: payment.amount,
            scheduledTime: payment.scheduledTime,
            executed: true
        )
        
        self.scheduledPayments[id] = executedPayment
        
        emit PaymentExecuted(id: id, success: true)
    }

    access(all) fun getScheduledPayment(id: UInt64): ScheduledPayment? {
        return self.scheduledPayments[id]
    }

    access(all) fun getAllScheduledPayments(): {UInt64: ScheduledPayment} {
        return self.scheduledPayments
    }


    init() {
        self.nextId = 1
        self.scheduledPayments = {}
    }
}