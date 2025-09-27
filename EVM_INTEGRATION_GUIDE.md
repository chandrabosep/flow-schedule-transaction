# EVM to Cadence Integration Guide

## Overview

This guide shows you how to set up the complete EVM-to-Cadence scheduling system. Your contracts are already deployed to Flow testnet, and now you need to set up the EVM trigger mechanism.

## Current Status

✅ **Cadence contracts deployed to testnet**: `0x9f3e9372a21a4f15`

-   `Counter` contract
-   `SimpleFlowScheduler` contract

## Next Steps for EVM Integration

### 1. Deploy EVM Contract

```bash
# Deploy the EVM scheduler contract
./scripts/deploy-evm.sh
```

### 2. Test the Integration

```bash
# Test EVM to Cadence integration
./scripts/test-evm-integration.sh
```

### 3. Manual Testing

You can also test manually using the Flow CLI:

```bash
# Test EVM trigger simulation
flow transactions send cadence/transactions/EVMScheduleTrigger.cdc \
    --args-json '[
        {"type": "String", "value": "0x1234567890abcdef"},
        {"type": "UFix64", "value": "10.0"},
        {"type": "UFix64", "value": "60.0"},
        {"type": "UInt64", "value": "1"}
    ]' \
    --network testnet \
    --signer 9f3e9372a21a4f15
```

## Architecture

```
EVM Contract (Solidity) → Flow EVM Bridge → Cadence Contract
     ↓                        ↓                    ↓
Schedule Payment → Trigger Transaction → SimpleFlowScheduler
```

## Key Components

### 1. EVM Contract (`contracts/EVMScheduler.sol`)

-   Solidity contract that manages scheduling from EVM
-   Triggers Cadence scheduling via bridge
-   Tracks schedule status and execution

### 2. Cadence Bridge Transaction (`cadence/transactions/EVMScheduleTrigger.cdc`)

-   Receives parameters from EVM
-   Calls `SimpleFlowScheduler.schedulePayment()`
-   Returns schedule ID to EVM

### 3. Cadence Scheduler (`SimpleFlowScheduler.cdc`)

-   Core scheduling logic
-   Payment execution
-   Status tracking

## Integration Flow

1. **EVM Contract Call**: User calls `schedulePayment()` on EVM contract
2. **Bridge Trigger**: EVM contract triggers Cadence transaction
3. **Cadence Scheduling**: Cadence contract schedules the payment
4. **Status Tracking**: Both EVM and Cadence track the schedule
5. **Execution**: Payment executes at scheduled time

## Testing Commands

### Check Scheduled Payments

```bash
flow scripts execute cadence/scripts/GetCounter.cdc --network testnet
```

### Execute a Payment

```bash
flow transactions send cadence/transactions/IncrementCounter.cdc \
    --network testnet \
    --signer 9f3e9372a21a4f15
```

## Development Workflow

1. **Deploy contracts** to testnet
2. **Test EVM integration** with provided scripts
3. **Customize** for your specific use case
4. **Deploy to mainnet** when ready

## Troubleshooting

### Common Issues

1. **Account not funded**: Use `flow accounts fund --network testnet 9f3e9372a21a4f15`
2. **Contract not deployed**: Run `flow project deploy --network testnet`
3. **Transaction fails**: Check account balance and permissions

### Debug Commands

```bash
# Check account status
flow accounts get --network testnet 9f3e9372a21a4f15

# Check contract deployment
flow project deploy --network testnet --dry-run

# View transaction logs
flow transactions get <transaction-id> --network testnet
```

## Next Steps

1. **Deploy EVM contract** to Flow EVM testnet
2. **Test the integration** with the provided scripts
3. **Customize** the scheduling logic for your needs
4. **Integrate** with your dApp frontend
5. **Deploy to mainnet** when ready

## Support

-   Flow Documentation: https://developers.flow.com/
-   Flow EVM: https://developers.flow.com/evm
-   Community: https://forum.onflow.org/
