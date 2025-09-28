#!/usr/bin/env node

/**
 * Auto Bridge Service - Connects EVM to Cadence Automatically
 * This is the ONLY service you need to run!
 */

const { ethers } = require("ethers");
const { exec } = require("child_process");
const { promisify } = require("util");

const execAsync = promisify(exec);

// Configuration
const CONFIG = {
	// Flow EVM RPC
	RPC_URL: "https://testnet.evm.nodes.onflow.org",

	// Your EVM contract address (UPDATE THIS when you deploy UpdatedEVMScheduler.sol)
	EVM_CONTRACT_ADDRESS: "0xf8e81D47203A594245E36C48e151709F0C19fBe8", // ✅ UPDATED!

	// Flow configuration
	FLOW_NETWORK: "testnet",
	FLOW_SIGNER: "testnet-account",

	// Polling interval
	POLL_INTERVAL: 3000, // 3 seconds
};

// EVM Contract ABI - only the events we need
const CONTRACT_ABI = [
	"event BridgeCallRequested(uint256 indexed scheduleId, string recipient, uint256 amount, uint256 delaySeconds, uint256 timestamp, address indexed caller)",
	"event CadenceBridgeTriggered(uint256 indexed scheduleId, string cadenceContractAddress, string transactionName)",
];

class AutoBridge {
	constructor() {
		console.log("🌉 Auto Bridge Service Starting...");
		this.provider = new ethers.JsonRpcProvider(CONFIG.RPC_URL);
		this.contract = new ethers.Contract(
			CONFIG.EVM_CONTRACT_ADDRESS,
			CONTRACT_ABI,
			this.provider
		);
		this.processedEvents = new Set();
	}

	async start() {
		console.log(`🔗 Connected to Flow EVM at ${CONFIG.RPC_URL}`);
		console.log(`📍 Monitoring contract: ${CONFIG.EVM_CONTRACT_ADDRESS}`);
		console.log(`⚡ Polling every ${CONFIG.POLL_INTERVAL}ms`);
		console.log("🚀 Ready to bridge EVM → Cadence!\n");

		// Listen for new events
		this.contract.on(
			"BridgeCallRequested",
			async (
				scheduleId,
				recipient,
				amount,
				delaySeconds,
				timestamp,
				caller,
				event
			) => {
				await this.handleBridgeCall({
					scheduleId: scheduleId.toString(),
					recipient,
					amount: amount.toString(),
					delaySeconds: delaySeconds.toString(),
					timestamp: timestamp.toString(),
					caller,
					txHash: event.transactionHash,
				});
			}
		);

		// Also poll for missed events
		setInterval(() => this.pollForEvents(), CONFIG.POLL_INTERVAL);
	}

	async handleBridgeCall(eventData) {
		const eventKey = `${eventData.txHash}-${eventData.scheduleId}`;

		if (this.processedEvents.has(eventKey)) {
			return; // Already processed
		}

		console.log("🎯 New EVM Bridge Call Detected!");
		console.log(`📋 Schedule ID: ${eventData.scheduleId}`);
		console.log(`💰 Amount: ${eventData.amount}`);
		console.log(`👤 Recipient: ${eventData.recipient}`);
		console.log(`⏰ Delay: ${eventData.delaySeconds}s`);
		console.log(`📍 From: ${eventData.caller}`);
		console.log(`🔗 EVM Tx: ${eventData.txHash}\n`);

		try {
			// 🚀 TRIGGER CADENCE AUTOMATICALLY!
			const cadenceResult = await this.triggerCadence(eventData);

			this.processedEvents.add(eventKey);

			console.log("✅ Bridge Call Successful!");
			console.log(
				`🌉 EVM→Cadence: ${eventData.scheduleId} → ${cadenceResult.cadenceId}`
			);
			console.log(`🔗 Cadence Tx: ${cadenceResult.txHash}\n`);
		} catch (error) {
			console.error("❌ Bridge Call Failed:", error.message);
		}
	}

	async triggerCadence(eventData) {
		const command =
			`flow transactions send cadence/transactions/NativeEVMSchedule.cdc ` +
			`--network ${CONFIG.FLOW_NETWORK} ` +
			`--signer ${CONFIG.FLOW_SIGNER} ` +
			`--args-json '[` +
			`{"type":"UInt64","value":"${eventData.scheduleId}"},` +
			`{"type":"String","value":"${eventData.recipient}"},` +
			`{"type":"UFix64","value":"${eventData.amount}.0"},` +
			`{"type":"UFix64","value":"${eventData.delaySeconds}.0"}` +
			`]'`;

		console.log("🚀 Executing Cadence transaction...");

		const { stdout, stderr } = await execAsync(command);

		if (stderr) {
			throw new Error(`Cadence execution failed: ${stderr}`);
		}

		// Extract transaction ID from output
		const txMatch = stdout.match(/Transaction ID: ([a-f0-9]+)/);
		const cadenceIdMatch = stdout.match(
			/cadenceScheduleId \(UInt64\): (\d+)/
		);

		return {
			txHash: txMatch ? txMatch[1] : "unknown",
			cadenceId: cadenceIdMatch ? cadenceIdMatch[1] : "unknown",
			output: stdout,
		};
	}

	async pollForEvents() {
		try {
			const currentBlock = await this.provider.getBlockNumber();
			const fromBlock = Math.max(currentBlock - 100, 0); // Last 100 blocks

			const events = await this.contract.queryFilter(
				this.contract.filters.BridgeCallRequested(),
				fromBlock,
				currentBlock
			);

			for (const event of events) {
				const eventKey = `${
					event.transactionHash
				}-${event.args[0].toString()}`;

				if (!this.processedEvents.has(eventKey)) {
					await this.handleBridgeCall({
						scheduleId: event.args[0].toString(),
						recipient: event.args[1],
						amount: event.args[2].toString(),
						delaySeconds: event.args[3].toString(),
						timestamp: event.args[4].toString(),
						caller: event.args[5],
						txHash: event.transactionHash,
					});
				}
			}
		} catch (error) {
			console.error("❌ Polling error:", error.message);
		}
	}
}

// Start the auto bridge
const bridge = new AutoBridge();
bridge.start().catch(console.error);

console.log("🎉 Auto Bridge Service Running!");
console.log("💡 Now call your EVM contract and watch the magic happen!");
console.log("🛑 Press Ctrl+C to stop\n");
