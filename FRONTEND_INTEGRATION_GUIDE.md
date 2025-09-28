# 🌉 EVM → Cadence Bridge Frontend Integration Guide

## 🎯 Overview

This guide shows you how to integrate your EVM → Cadence bridge into any frontend application. Your bridge automatically connects EVM contract calls to Cadence scheduled transactions.

## 📋 What You Have

### ✅ Deployed Contracts

-   **EVM Contract**: `UpdatedEVMScheduler.sol` at `0xf8e81D47203A594245E36C48e151709F0C19fBe8`
-   **Cadence Bridge**: `NativeEVMBridge.cdc` at `0x9f3e9372a21a4f15`
-   **Auto-Bridge Service**: `auto-bridge.js` (monitors EVM events → triggers Cadence)

### 🚀 How It Works

```
User calls EVM contract → Event emitted → Auto-bridge catches event → Cadence transaction → 100% on-chain execution
```

## 🛠 Integration Options

### 1. **HTML/Vanilla JavaScript** (Ready to use!)

-   File: `frontend-integration.html`
-   Open in browser and connect MetaMask
-   Fully functional UI for scheduling payments

### 2. **React Component** (For React apps)

-   File: `EVMBridgeComponent.jsx`
-   Import and use in your React application
-   Includes all bridge functionality

### 3. **Custom Integration** (Any framework)

-   Use the configuration and methods below
-   Adapt to your preferred framework

## 🔧 Configuration

```javascript
const CONFIG = {
	EVM_CONTRACT_ADDRESS: "0xf8e81D47203A594245E36C48e151709F0C19fBe8",
	CADENCE_ADDRESS: "0x9f3e9372a21a4f15",
	FLOW_EVM_RPC: "https://testnet.evm.nodes.onflow.org",
	CHAIN_ID: 545, // Flow EVM testnet
	EXPLORER_BASE: "https://evm-testnet.flowscan.io",
};
```

## 📝 Contract ABI

```javascript
const CONTRACT_ABI = [
	"function schedulePayment(string recipient, uint256 amount, uint256 delaySeconds) external payable returns (uint256)",
	"function getSchedule(uint256 scheduleId) external view returns (uint256 id, string recipient, uint256 amount, uint256 delaySeconds, uint256 createdAt, address creator, bool bridgeTriggered, bool executed)",
	"function getSchedulesByCreator(address creator) external view returns (uint256[])",
	"function getTotalSchedules() external view returns (uint256)",
	"event BridgeCallRequested(uint256 indexed scheduleId, string recipient, uint256 amount, uint256 delaySeconds, uint256 timestamp, address indexed caller)",
	"event ScheduleCreated(uint256 indexed scheduleId, address indexed creator, string recipient, uint256 amount, uint256 delaySeconds, bool bridgeTriggered)",
];
```

## 🚀 Quick Start Integration

### Step 1: Install Dependencies

```bash
npm install ethers
```

### Step 2: Connect to Wallet

```javascript
import { ethers } from "ethers";

async function connectWallet() {
	// Request account access
	await window.ethereum.request({ method: "eth_requestAccounts" });

	const provider = new ethers.providers.Web3Provider(window.ethereum);
	const signer = provider.getSigner();
	const userAddress = await signer.getAddress();

	// Check/switch to Flow EVM network
	const network = await provider.getNetwork();
	if (network.chainId !== 545) {
		await switchToFlowEVM();
	}

	const contract = new ethers.Contract(
		CONFIG.EVM_CONTRACT_ADDRESS,
		CONTRACT_ABI,
		signer
	);

	return { provider, signer, contract, userAddress };
}
```

### Step 3: Schedule a Payment

```javascript
async function schedulePayment(contract, recipient, amount, delaySeconds) {
	try {
		// Call your EVM contract
		const tx = await contract.schedulePayment(
			recipient,
			amount,
			delaySeconds
		);

		console.log("Transaction submitted:", tx.hash);

		// Wait for confirmation
		const receipt = await tx.wait();

		console.log(
			"✅ Payment scheduled! The bridge will automatically trigger Cadence."
		);

		return receipt;
	} catch (error) {
		console.error("❌ Error:", error.message);
		throw error;
	}
}
```

### Step 4: Load User's Schedules

```javascript
async function loadUserSchedules(contract, userAddress) {
	try {
		// Get schedule IDs for this user
		const scheduleIds = await contract.getSchedulesByCreator(userAddress);

		// Get details for each schedule
		const schedules = [];
		for (const id of scheduleIds) {
			const schedule = await contract.getSchedule(id);
			schedules.push({
				id: schedule.id.toString(),
				recipient: schedule.recipient,
				amount: schedule.amount.toString(),
				delaySeconds: schedule.delaySeconds.toString(),
				createdAt: new Date(schedule.createdAt.toNumber() * 1000),
				bridgeTriggered: schedule.bridgeTriggered,
				executed: schedule.executed,
			});
		}

		return schedules.sort((a, b) => b.createdAt - a.createdAt);
	} catch (error) {
		console.error("Error loading schedules:", error);
		return [];
	}
}
```

### Step 5: Listen for Events

```javascript
function setupEventListeners(contract, userAddress) {
	// Listen for new schedules
	contract.on(
		"ScheduleCreated",
		(
			scheduleId,
			creator,
			recipient,
			amount,
			delaySeconds,
			bridgeTriggered
		) => {
			if (creator.toLowerCase() === userAddress.toLowerCase()) {
				console.log("🎉 New schedule created:", scheduleId.toString());
				// Update UI
			}
		}
	);

	// Listen for bridge calls
	contract.on(
		"BridgeCallRequested",
		(scheduleId, recipient, amount, delaySeconds, timestamp, caller) => {
			if (caller.toLowerCase() === userAddress.toLowerCase()) {
				console.log(
					"🌉 Bridge call triggered for schedule:",
					scheduleId.toString()
				);
				// Update UI
			}
		}
	);
}
```

## 🌐 Network Configuration

### Add Flow EVM to MetaMask

```javascript
async function switchToFlowEVM() {
	try {
		await window.ethereum.request({
			method: "wallet_switchEthereumChain",
			params: [{ chainId: "0x221" }], // 545 in hex
		});
	} catch (switchError) {
		// Add network if not exists
		if (switchError.code === 4902) {
			await window.ethereum.request({
				method: "wallet_addEthereumChain",
				params: [
					{
						chainId: "0x221",
						chainName: "Flow EVM Testnet",
						nativeCurrency: {
							name: "FLOW",
							symbol: "FLOW",
							decimals: 18,
						},
						rpcUrls: ["https://testnet.evm.nodes.onflow.org"],
						blockExplorerUrls: ["https://evm-testnet.flowscan.io"],
					},
				],
			});
		}
	}
}
```

## 🎨 UI Components

### Schedule Payment Form

```html
<form id="scheduleForm">
	<input type="text" placeholder="Recipient Address" required />
	<input type="number" placeholder="Amount" min="1" required />
	<select>
		<option value="300">5 minutes</option>
		<option value="1800">30 minutes</option>
		<option value="3600">1 hour</option>
	</select>
	<button type="submit">🚀 Schedule Payment</button>
</form>
```

### Schedule Display

```html
<div class="schedule-item">
	<div class="schedule-header">
		<span class="schedule-id">Schedule #123</span>
		<span class="status">✅ Bridge Triggered</span>
	</div>
	<div class="schedule-details">
		<div>Recipient: 0x...</div>
		<div>Amount: 100</div>
		<div>Delay: 5m</div>
		<div>Status: 🚀 Scheduled in Cadence</div>
	</div>
</div>
```

## 🔄 Complete Integration Flow

### 1. **User Action**

```javascript
// User fills form and clicks "Schedule Payment"
const tx = await contract.schedulePayment(recipient, amount, delaySeconds);
```

### 2. **EVM Contract**

```solidity
// UpdatedEVMScheduler.sol automatically:
// - Stores the schedule
// - Emits BridgeCallRequested event
// - Emits ScheduleCreated event
```

### 3. **Auto-Bridge Service**

```javascript
// auto-bridge.js automatically:
// - Detects the BridgeCallRequested event
// - Calls: flow transactions send cadence/transactions/NativeEVMSchedule.cdc
// - Logs success/failure
```

### 4. **Cadence Execution**

```cadence
// NativeEVMBridge.cdc automatically:
// - Creates scheduled payment
// - Executes at specified time
// - 100% on-chain from this point
```

### 5. **Frontend Updates**

```javascript
// Your frontend automatically:
// - Shows transaction confirmation
// - Updates schedule list
// - Displays bridge status
```

## 📱 Mobile Integration

### React Native

```javascript
import { ethers } from "ethers";

// Use WalletConnect or similar for mobile wallet connection
const provider = new ethers.providers.JsonRpcProvider(CONFIG.FLOW_EVM_RPC);
const contract = new ethers.Contract(
	CONFIG.EVM_CONTRACT_ADDRESS,
	CONTRACT_ABI,
	provider
);
```

### Web3Modal Integration

```javascript
import Web3Modal from "web3modal";

const web3Modal = new Web3Modal({
	network: "testnet",
	cacheProvider: true,
	providerOptions: {
		// Configure wallet providers
	},
});
```

## 🛠 Required Services

### Auto-Bridge Service (Required)

```bash
# Start the bridge service
node auto-bridge.js
```

**Important**: The auto-bridge service must be running to connect EVM events to Cadence transactions.

### Alternative: Serverless Bridge

```javascript
// AWS Lambda/Vercel function to handle bridge calls
export default async function handler(req, res) {
	// Listen for webhooks from EVM events
	// Trigger Cadence transactions
	// Return success/failure
}
```

## 🎯 Testing Your Integration

### 1. **Start Auto-Bridge**

```bash
node auto-bridge.js
```

### 2. **Open Frontend**

```bash
# Open frontend-integration.html in browser
# OR run your React app
npm start
```

### 3. **Connect MetaMask**

-   Switch to Flow EVM testnet
-   Connect your wallet

### 4. **Schedule a Payment**

-   Fill the form
-   Submit transaction
-   Watch the bridge work automatically!

### 5. **Monitor Results**

-   Check auto-bridge logs
-   View schedules in frontend
-   Verify Cadence execution

## 🚨 Common Issues & Solutions

### Issue: "Cannot find module 'ethers'"

```bash
npm install ethers
```

### Issue: "Network not supported"

```javascript
// Add Flow EVM network to MetaMask
await switchToFlowEVM();
```

### Issue: "Bridge not triggering"

```bash
# Ensure auto-bridge.js is running
node auto-bridge.js
```

### Issue: "Transaction failed"

```javascript
// Check gas limits and network connection
const tx = await contract.schedulePayment(recipient, amount, delaySeconds, {
	gasLimit: 300000,
});
```

## 🎉 You're Ready!

Your EVM → Cadence bridge frontend integration is complete! Users can now:

1. **Connect** their MetaMask wallet
2. **Schedule** payments through your EVM contract
3. **Watch** the bridge automatically trigger Cadence
4. **Monitor** their scheduled payments
5. **Enjoy** 100% on-chain execution

The bridge handles all the complex cross-chain communication automatically! 🌉✨

## 📚 Additional Resources

-   **Frontend Demo**: `frontend-integration.html`
-   **React Component**: `EVMBridgeComponent.jsx`
-   **Auto-Bridge Service**: `auto-bridge.js`
-   **EVM Contract**: `contracts/UpdatedEVMScheduler.sol`
-   **Cadence Bridge**: `cadence/contracts/NativeEVMBridge.cdc`

Happy building! 🚀
