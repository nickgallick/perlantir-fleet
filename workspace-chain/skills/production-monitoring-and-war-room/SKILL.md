# Production Monitoring & War Room

Expert reference for smart contract production operations: pre-deployment hardening, real-time on-chain surveillance, incident response, and post-mortem discipline.

---

## Table of Contents

1. [Pre-Deployment Security Checklist](#1-pre-deployment-security-checklist)
2. [Forta Network — Detection Bots](#2-forta-network--detection-bots)
3. [OpenZeppelin Defender](#3-openzeppelin-defender)
4. [On-Chain Monitoring Patterns](#4-on-chain-monitoring-patterns)
5. [Incident Response Playbook](#5-incident-response-playbook)
6. [Emergency Procedures](#6-emergency-procedures)
7. [War Room Protocol](#7-war-room-protocol)
8. [Transaction Monitoring](#8-transaction-monitoring)
9. [Alerting Infrastructure](#9-alerting-infrastructure)
10. [Post-Mortem Framework](#10-post-mortem-framework)
11. [Bug Bounty Programs](#11-bug-bounty-programs)
12. [Security Operations](#12-security-operations)

---

## 1. Pre-Deployment Security Checklist

### 1.1 Audit Readiness

Complete every item before engaging an external auditor. Incomplete preparation wastes audit budget on mechanical findings rather than logic bugs.

```
AUDIT READINESS CHECKLIST
==========================

Code Freeze
[ ] Feature development halted; only audit-response commits permitted
[ ] All open PRs merged or explicitly deferred
[ ] Final commit SHA documented in audit brief

Documentation
[ ] NatSpec on every external/public function and state variable
[ ] Architecture diagram (system components, trust boundaries, privilege graph)
[ ] Threat model document listing assets, actors, and assumed invariants
[ ] Deployment script with constructor arguments and initialization order
[ ] Known issues / accepted risk list with rationale

Test Suite
[ ] Unit test coverage >= 95% line, >= 90% branch (check with forge coverage)
[ ] Invariant / fuzz tests for all core accounting identities
[ ] Integration tests against forked mainnet state
[ ] Mutation testing score documented (vertigo-rs or gambit)
[ ] Gas snapshot committed (forge snapshot)

Static Analysis
[ ] slither . --print human-summary passes with no high/medium findings
[ ] 4nalyzer or aderyn run; findings triaged
[ ] mythril or halmos symbolic execution on critical paths

Dependencies
[ ] All external library versions pinned (no floating ^)
[ ] Library diff against previous audited version documented
[ ] No unreviewed transitive dependency upgrades
```

### 1.2 Test Coverage Standards

```bash
# Foundry: enforce minimum coverage in CI
forge coverage --report lcov
genhtml lcov.info --branch-coverage -o coverage-report

# fail pipeline if below threshold
LINES=$(lcov --summary lcov.info 2>&1 | grep "lines" | awk '{print $2}' | tr -d '%')
if (( $(echo "$LINES < 95" | bc -l) )); then
  echo "Line coverage $LINES% below 95% threshold"; exit 1
fi

# Hardhat equivalent
npx hardhat coverage --solcoverjs .solcover.js
# .solcover.js
module.exports = {
  skipFiles: ['mocks/', 'test/'],
  istanbulReporter: ['html', 'lcov', 'text'],
  istanbulFolder: './coverage',
};
```

### 1.3 Access Control Review

Document every privileged role before deployment. Any role not documented is a misconfiguration waiting to happen.

```
ACCESS CONTROL MATRIX
=====================
Role              | Contract        | Capabilities                        | Holder
------------------|-----------------|-------------------------------------|------------------
DEFAULT_ADMIN     | ProxyAdmin      | Upgrade implementation              | 3/5 Multisig
PAUSER_ROLE       | Core, Vault     | pause() / unpause()                 | Guardian EOA
GUARDIAN_ROLE     | EmergencyModule | executeEmergency()                  | Security Council
OPERATOR_ROLE     | Relayer         | relay(), executeProposal()          | Defender Relayer
TIMELOCK_ADMIN    | TimelockController | queue, execute, cancel proposals | Governance contract
FEE_SETTER        | FeeManager      | setFee(), setRecipient()            | Protocol Multisig

Timelocks
---------
Upgrade delay:     48 hours
Fee change delay:  24 hours
Role grant delay:  48 hours
Emergency bypass:  Guardian role, no delay, emits EmergencyAction event
```

### 1.4 Upgrade Safety

```solidity
// Storage layout verification — commit slot map before every upgrade
// Run: forge inspect ContractV2 storage-layout > layout-v2.json
// Diff against layout-v1.json; no slot may shift

// UUPS upgrade guard pattern
function _authorizeUpgrade(address newImplementation)
    internal override onlyRole(DEFAULT_ADMIN_ROLE) {
    // Validate new implementation is not zero and passes interface check
    require(newImplementation != address(0), "zero impl");
    require(
        IERC165(newImplementation).supportsInterface(type(IProtocol).interfaceId),
        "bad interface"
    );
}

// Transparent proxy: always verify ProxyAdmin owner before upgrade
// cast call $PROXY_ADMIN "owner()(address)" --rpc-url $RPC
```

```bash
# Pre-upgrade checklist script
#!/usr/bin/env bash
set -euo pipefail

PROXY=$1
IMPL_NEW=$2
RPC=$3

echo "[1] Verify proxy admin ownership"
ADMIN=$(cast call "$PROXY" "admin()(address)" --rpc-url "$RPC")
echo "    ProxyAdmin: $ADMIN"

echo "[2] Storage layout diff"
forge inspect "$IMPL_NEW" storage-layout > /tmp/new-layout.json
diff layout-baseline.json /tmp/new-layout.json && echo "    PASS: no layout changes" || echo "    WARN: layout changed — review carefully"

echo "[3] Simulate upgrade on fork"
anvil --fork-url "$RPC" --fork-block-number latest &
ANVIL_PID=$!
forge script script/Upgrade.s.sol --fork-url http://localhost:8545 --broadcast
kill $ANVIL_PID

echo "[4] Verify implementation bytecode"
cast code "$IMPL_NEW" --rpc-url "$RPC" | sha256sum
```

---

## 2. Forta Network — Detection Bots

Forta bots are JavaScript/TypeScript agents that receive blockchain data (transactions, blocks, alerts) and emit findings. Each bot runs inside a Forta node scanning agent container.

### 2.1 Bot Architecture

```
Block/Transaction feed
        │
   Forta Scanner Node
        │
   ┌────▼────────────────────┐
   │  Bot Container (Docker) │
   │  handleTransaction()    │
   │  handleBlock()          │
   │  handleAlert()          │
   └────┬────────────────────┘
        │  Finding[]
   Forta Network (IPFS publish)
        │
   Subscribers / Defender Sentinel
```

### 2.2 Large Transfer Detection Bot

```typescript
// src/agent.ts
import {
  Finding,
  FindingSeverity,
  FindingType,
  HandleTransaction,
  TransactionEvent,
  ethers,
} from "forta-agent";

const ERC20_TRANSFER_EVENT =
  "event Transfer(address indexed from, address indexed to, uint256 value)";

// Contracts under surveillance → threshold in token units (18 decimals assumed)
const MONITORED_TOKENS: Record<string, { symbol: string; threshold: bigint }> = {
  "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48": {
    symbol: "USDC",
    threshold: ethers.parseUnits("1000000", 6), // 1M USDC
  },
  "0xdAC17F958D2ee523a2206206994597C13D831ec7": {
    symbol: "USDT",
    threshold: ethers.parseUnits("1000000", 6),
  },
  "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2": {
    symbol: "WETH",
    threshold: ethers.parseUnits("500", 18), // 500 WETH
  },
};

export const handleTransaction: HandleTransaction = async (
  txEvent: TransactionEvent
): Promise<Finding[]> => {
  const findings: Finding[] = [];

  for (const [tokenAddress, { symbol, threshold }] of Object.entries(
    MONITORED_TOKENS
  )) {
    const transferEvents = txEvent.filterLog(ERC20_TRANSFER_EVENT, tokenAddress);

    for (const event of transferEvents) {
      const { from, to, value } = event.args;
      if (value > threshold) {
        findings.push(
          Finding.fromObject({
            name: `Large ${symbol} Transfer`,
            description: `${ethers.formatUnits(value, symbol === "WETH" ? 18 : 6)} ${symbol} moved from ${from} to ${to}`,
            alertId: "LARGE-TRANSFER-1",
            severity: FindingSeverity.Medium,
            type: FindingType.Suspicious,
            metadata: {
              token: tokenAddress,
              symbol,
              from,
              to,
              value: value.toString(),
              txHash: txEvent.hash,
            },
          })
        );
      }
    }
  }

  return findings;
};
```

### 2.3 Flashloan Detection Bot

```typescript
// src/flashloan-agent.ts
import {
  Finding,
  FindingSeverity,
  FindingType,
  HandleTransaction,
  TransactionEvent,
  ethers,
} from "forta-agent";

// Known flashloan providers
const FLASHLOAN_SIGNATURES = [
  "flashLoan(address,address,uint256,bytes)",       // Aave v2
  "flashLoan(address,address[],uint256[],uint256[],address,bytes,uint16)", // Aave v3
  "flash(address,uint256,uint256,bytes)",            // Uniswap v3
  "flashBorrow(address,uint256)",                    // dYdX
];

const FLASHLOAN_SELECTORS = new Set(
  FLASHLOAN_SIGNATURES.map((sig) =>
    ethers.id(sig).slice(0, 10)
  )
);

const PROTOCOL_CONTRACTS = new Set([
  "0xYOUR_VAULT_ADDRESS",
  "0xYOUR_POOL_ADDRESS",
]);

export const handleTransaction: HandleTransaction = async (
  txEvent: TransactionEvent
): Promise<Finding[]> => {
  const findings: Finding[] = [];

  const hasFlashloan = txEvent.traces.some(
    (trace) =>
      trace.action.input &&
      FLASHLOAN_SELECTORS.has(trace.action.input.slice(0, 10))
  );

  if (!hasFlashloan) return findings;

  // Check if same tx interacts with protocol
  const hitsProtocol = txEvent.traces.some(
    (trace) =>
      trace.action.to && PROTOCOL_CONTRACTS.has(trace.action.to.toLowerCase())
  );

  if (hitsProtocol) {
    findings.push(
      Finding.fromObject({
        name: "Flashloan + Protocol Interaction",
        description: `Transaction ${txEvent.hash} uses flashloan and touches monitored protocol`,
        alertId: "FLASHLOAN-PROTOCOL-1",
        severity: FindingSeverity.High,
        type: FindingType.Exploit,
        metadata: {
          txHash: txEvent.hash,
          from: txEvent.from,
          gas: txEvent.transaction.gas,
        },
      })
    );
  }

  return findings;
};
```

### 2.4 Governance Attack Bot

```typescript
// src/governance-agent.ts
import {
  Finding,
  FindingSeverity,
  FindingType,
  HandleBlock,
  HandleTransaction,
  BlockEvent,
  TransactionEvent,
  getEthersProvider,
  ethers,
} from "forta-agent";

const GOVERNOR_ADDRESS = "0xYOUR_GOVERNOR";
const PROPOSAL_CREATED = "event ProposalCreated(uint256 proposalId, address proposer, address[] targets, uint256[] values, string[] signatures, bytes[] calldatas, uint256 startBlock, uint256 endBlock, string description)";
const VOTE_CAST = "event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 weight, string reason)";

// Threshold: a single voter with >15% of quorum is suspicious if address is new
const LARGE_VOTE_THRESHOLD_BPS = 1500; // 15%

export const handleTransaction: HandleTransaction = async (
  txEvent: TransactionEvent
): Promise<Finding[]> => {
  const findings: Finding[] = [];
  const provider = getEthersProvider();

  // Detect proposal creation from new/unknown addresses
  const proposals = txEvent.filterLog(PROPOSAL_CREATED, GOVERNOR_ADDRESS);
  for (const proposal of proposals) {
    const { proposer, description } = proposal.args;
    const nonce = await provider.getTransactionCount(proposer);
    if (nonce < 5) {
      findings.push(
        Finding.fromObject({
          name: "Governance Proposal from New Address",
          description: `New address ${proposer} (nonce ${nonce}) created proposal: ${description.slice(0, 100)}`,
          alertId: "GOV-NEW-PROPOSER-1",
          severity: FindingSeverity.Medium,
          type: FindingType.Suspicious,
          metadata: { proposer, proposalId: proposal.args.proposalId.toString() },
        })
      );
    }
  }

  // Detect outsized single votes
  const votes = txEvent.filterLog(VOTE_CAST, GOVERNOR_ADDRESS);
  for (const vote of votes) {
    const { voter, proposalId, weight } = vote.args;
    // Fetch total supply for context (cached in production)
    // If weight > LARGE_VOTE_THRESHOLD emit alert
    findings.push(
      Finding.fromObject({
        name: "Large Governance Vote",
        description: `Voter ${voter} cast ${ethers.formatEther(weight)} votes on proposal ${proposalId}`,
        alertId: "GOV-LARGE-VOTE-1",
        severity: FindingSeverity.Low,
        type: FindingType.Info,
        metadata: { voter, proposalId: proposalId.toString(), weight: weight.toString() },
      })
    );
  }

  return findings;
};
```

### 2.5 Bot Deployment

```bash
# Install Forta CLI
npm install -g @fortanetwork/forta-cli

# Initialize bot project
forta init --typescript

# Test locally against a real block
forta run --tx 0xTRANSACTION_HASH
forta run --block 19000000
forta run --range 19000000..19000010

# Run test suite
npm test

# Build Docker image
forta build

# Push to Forta registry (requires FORTA_PRIVATE_KEY env var)
forta publish

# Bot manifest (forta.config.json)
{
  "agentId": "0xYOUR_BOT_ID",
  "chainIds": [1, 137, 42161],
  "repository": "ipfs://Qm...",
  "documentation": "ipfs://Qm...",
  "manifest": "ipfs://Qm..."
}
```

### 2.6 Alert Subscription via SDK

```typescript
// Subscribe to your own bot's alerts programmatically
import { AlertsResponse } from "forta-agent";

const query = `
  query GetAlerts($botId: String!, $after: String) {
    alerts(
      input: {
        botIds: [$botId]
        chainId: 1
        first: 100
        after: $after
        createdSince: 3600
      }
    ) {
      alerts {
        alertId
        severity
        name
        description
        metadata
        createdAt
        hash
        transaction { hash }
      }
      pageInfo { hasNextPage endCursor { alertId blockNumber } }
    }
  }
`;
```

---

## 3. OpenZeppelin Defender

### 3.1 Monitor (formerly Sentinel) Configuration

Monitors watch for on-chain events or function calls and trigger notifications or Autotask webhooks.

```json
// Defender Monitor configuration (API / Terraform)
{
  "name": "Vault Pause Monitor",
  "network": "mainnet",
  "addresses": ["0xYOUR_VAULT"],
  "abi": "[{\"anonymous\":false,\"inputs\":[{\"indexed\":false,\"internalType\":\"address\",\"name\":\"account\",\"type\":\"address\"}],\"name\":\"Paused\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[],\"name\":\"Unpaused\",\"type\":\"event\"}]",
  "eventConditions": [
    { "eventSignature": "Paused(address)" },
    { "eventSignature": "Unpaused()" }
  ],
  "alertTimeoutMs": 0,
  "notificationChannels": ["pagerduty-critical", "slack-alerts"],
  "autotaskTrigger": {
    "autotaskId": "YOUR_AUTOTASK_ID"
  }
}
```

```json
// Monitor for large ETH balance change
{
  "name": "Treasury Balance Drop",
  "network": "mainnet",
  "addresses": ["0xTREASURY_ADDRESS"],
  "txCondition": "value > 50000000000000000000",
  "functionConditions": [],
  "alertThreshold": {
    "amount": 1,
    "windowSeconds": 3600
  },
  "notificationChannels": ["pagerduty-critical"]
}
```

### 3.2 Actions (formerly Autotasks)

```javascript
// Defender Action: auto-pause on anomaly
// Triggered by Monitor webhook when balance drops >20%

const { ethers } = require("ethers");
const { DefenderRelaySigner, DefenderRelayProvider } = require("defender-relay-client/lib/ethers");

const VAULT_ABI = [
  "function pause() external",
  "function paused() view returns (bool)",
  "function totalAssets() view returns (uint256)",
];

exports.handler = async function(credentials) {
  const provider = new DefenderRelayProvider(credentials);
  const signer = new DefenderRelaySigner(credentials, provider, { speed: "fast" });

  const vault = new ethers.Contract(process.env.VAULT_ADDRESS, VAULT_ABI, signer);

  const isPaused = await vault.paused();
  if (isPaused) {
    console.log("Vault already paused — skipping");
    return { status: "already-paused" };
  }

  const totalAssets = await vault.totalAssets();
  console.log(`Total assets before pause: ${ethers.formatEther(totalAssets)}`);

  const tx = await vault.pause();
  const receipt = await tx.wait();
  console.log(`Vault paused at tx ${receipt.hash}`);

  // Notify Slack via webhook env var
  await fetch(process.env.SLACK_WEBHOOK_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      text: `EMERGENCY: Vault auto-paused at block ${receipt.blockNumber}. Tx: ${receipt.hash}`,
    }),
  });

  return { status: "paused", txHash: receipt.hash };
};
```

### 3.3 Relayer Configuration

```javascript
// Create relayer via Defender SDK
const { Defender } = require("@openzeppelin/defender-sdk");

const client = new Defender({
  apiKey: process.env.DEFENDER_API_KEY,
  apiSecret: process.env.DEFENDER_API_SECRET,
});

async function createRelayer() {
  const relayer = await client.relay.create({
    name: "Emergency Guardian Relayer",
    network: "mainnet",
    minBalance: BigInt("100000000000000000"), // 0.1 ETH minimum
    policies: {
      gasPriceCap: "300000000000",   // 300 gwei hard cap
      whitelistReceivers: [
        "0xYOUR_VAULT",
        "0xYOUR_CORE_CONTRACT",
      ],
      eip1559Pricing: true,
    },
  });

  console.log("Relayer address:", relayer.address);
  console.log("Relayer ID:", relayer.relayerId);
}
```

### 3.4 Admin Proposals for Timelocked Operations

```javascript
// Queue upgrade via Defender Admin proposal
const { Defender } = require("@openzeppelin/defender-sdk");

async function proposeUpgrade(proxyAddress, newImplementationAddress) {
  const client = new Defender({ apiKey, apiSecret });

  const proposal = await client.proposal.create({
    contract: {
      address: proxyAddress,
      network: "mainnet",
    },
    title: "Upgrade to V2.1 — Patch reentrancy in withdraw()",
    description: "Fixes CEI violation reported in audit finding H-01. New impl: " + newImplementationAddress,
    type: "upgrade",
    newImplementation: newImplementationAddress,
    via: "0xMULTISIG_ADDRESS",
    viaType: "Gnosis Safe",
  });

  console.log("Proposal URL:", proposal.url);
}
```

---

## 4. On-Chain Monitoring Patterns

### 4.1 Event Monitor Script (ethers.js)

```typescript
// monitor/event-monitor.ts
import { ethers, EventLog } from "ethers";
import { sendAlert } from "./alerting";

const VAULT_ABI = [
  "event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares)",
  "event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares)",
  "event Paused(address account)",
  "event EmergencyWithdrawal(address indexed user, uint256 amount)",
];

const LARGE_DEPOSIT_THRESHOLD = ethers.parseEther("1000"); // 1000 ETH equivalent

async function startEventMonitor(
  provider: ethers.WebSocketProvider,
  vaultAddress: string
) {
  const vault = new ethers.Contract(vaultAddress, VAULT_ABI, provider);

  vault.on("Deposit", async (caller, owner, assets, shares, event: EventLog) => {
    if (assets > LARGE_DEPOSIT_THRESHOLD) {
      await sendAlert({
        severity: "medium",
        title: "Large Deposit",
        body: `${ethers.formatEther(assets)} ETH deposited by ${caller}`,
        txHash: event.transactionHash,
      });
    }
  });

  vault.on("Paused", async (account, event: EventLog) => {
    await sendAlert({
      severity: "critical",
      title: "CONTRACT PAUSED",
      body: `Vault paused by ${account}`,
      txHash: event.transactionHash,
    });
  });

  vault.on("EmergencyWithdrawal", async (user, amount, event: EventLog) => {
    await sendAlert({
      severity: "critical",
      title: "EMERGENCY WITHDRAWAL",
      body: `${ethers.formatEther(amount)} ETH withdrawn by ${user} via emergency path`,
      txHash: event.transactionHash,
    });
  });

  // Reconnect on disconnect
  provider.on("error", (err) => {
    console.error("WS provider error:", err);
    setTimeout(() => startEventMonitor(createProvider(), vaultAddress), 5000);
  });

  console.log(`Monitoring vault ${vaultAddress}`);
}

function createProvider(): ethers.WebSocketProvider {
  return new ethers.WebSocketProvider(process.env.WS_RPC_URL!);
}
```

### 4.2 Balance Tracker

```typescript
// monitor/balance-tracker.ts
import { ethers } from "ethers";

interface BalanceSnapshot {
  block: number;
  timestamp: number;
  ethBalance: bigint;
  tokenBalances: Record<string, bigint>;
}

const ERC20_ABI = ["function balanceOf(address) view returns (uint256)"];

async function trackBalances(
  provider: ethers.JsonRpcProvider,
  address: string,
  tokens: string[],
  thresholdDropBps: number,   // basis points, e.g. 500 = 5%
  intervalMs: number
) {
  let previous: BalanceSnapshot | null = null;

  async function snapshot(): Promise<BalanceSnapshot> {
    const block = await provider.getBlockNumber();
    const blockData = await provider.getBlock(block);
    const ethBalance = await provider.getBalance(address);
    const tokenBalances: Record<string, bigint> = {};

    for (const token of tokens) {
      const contract = new ethers.Contract(token, ERC20_ABI, provider);
      tokenBalances[token] = await contract.balanceOf(address);
    }

    return { block, timestamp: blockData!.timestamp, ethBalance, tokenBalances };
  }

  setInterval(async () => {
    const current = await snapshot();

    if (previous) {
      // ETH balance drop check
      if (previous.ethBalance > 0n) {
        const dropBps =
          ((previous.ethBalance - current.ethBalance) * 10000n) /
          previous.ethBalance;
        if (dropBps > BigInt(thresholdDropBps)) {
          await sendCriticalAlert(
            `ETH balance dropped ${dropBps}bps on ${address}`,
            current
          );
        }
      }

      // Token balance drop checks
      for (const [token, prevBalance] of Object.entries(previous.tokenBalances)) {
        const curBalance = current.tokenBalances[token];
        if (prevBalance > 0n) {
          const dropBps = ((prevBalance - curBalance) * 10000n) / prevBalance;
          if (dropBps > BigInt(thresholdDropBps)) {
            await sendCriticalAlert(
              `Token ${token} balance dropped ${dropBps}bps on ${address}`,
              current
            );
          }
        }
      }
    }

    previous = current;
  }, intervalMs);
}
```

### 4.3 Governance Proposal Watcher

```typescript
// monitor/governance-watcher.ts
import { ethers } from "ethers";

const GOVERNOR_ABI = [
  "event ProposalCreated(uint256 proposalId, address proposer, address[] targets, uint256[] values, string[] signatures, bytes[] calldatas, uint256 startBlock, uint256 endBlock, string description)",
  "event ProposalQueued(uint256 proposalId, uint256 eta)",
  "event ProposalExecuted(uint256 proposalId)",
  "function state(uint256 proposalId) view returns (uint8)",
  "function proposalEta(uint256 proposalId) view returns (uint256)",
];

// Proposal states: 0=Pending,1=Active,2=Canceled,3=Defeated,4=Succeeded,5=Queued,6=Expired,7=Executed

const DANGEROUS_CALLDATA_PATTERNS = [
  "upgradeTo(",
  "upgradeToAndCall(",
  "grantRole(",
  "revokeRole(",
  "transferOwnership(",
  "_setPendingAdmin(",
];

async function watchGovernance(
  provider: ethers.WebSocketProvider,
  governorAddress: string
) {
  const governor = new ethers.Contract(governorAddress, GOVERNOR_ABI, provider);

  governor.on(
    "ProposalCreated",
    async (proposalId, proposer, targets, values, signatures, calldatas, startBlock, endBlock, description) => {
      const warnings: string[] = [];

      // Check for dangerous operations in calldata
      for (let i = 0; i < calldatas.length; i++) {
        const decoded = Buffer.from(calldatas[i].slice(2), "hex").toString("utf8");
        for (const pattern of DANGEROUS_CALLDATA_PATTERNS) {
          if (signatures[i].includes(pattern) || decoded.includes(pattern)) {
            warnings.push(`Dangerous operation in call ${i}: ${signatures[i]}`);
          }
        }
      }

      const severity = warnings.length > 0 ? "high" : "medium";
      await sendAlert({
        severity,
        title: `Governance Proposal ${proposalId} Created`,
        body: [
          `Proposer: ${proposer}`,
          `Voting ends: block ${endBlock}`,
          `Description: ${description.slice(0, 200)}`,
          ...warnings,
        ].join("\n"),
      });
    }
  );

  governor.on("ProposalQueued", async (proposalId, eta) => {
    const execTime = new Date(Number(eta) * 1000).toISOString();
    await sendAlert({
      severity: "high",
      title: `Governance Proposal ${proposalId} Queued`,
      body: `Executable at: ${execTime}. Verify proposal intent before execution window.`,
    });
  });
}
```

---

## 5. Incident Response Playbook

### 5.1 Incident Severity Classification

```
SEVERITY LEVELS
===============
SEV-1 (Critical)  — Active exploit, funds at immediate risk, contract compromised
SEV-2 (High)      — Potential exploit vector identified, anomalous behavior, oracle manipulation
SEV-3 (Medium)    — Degraded functionality, unexpected state, non-critical contract misbehavior
SEV-4 (Low)       — Informational anomaly, monitoring gap, process deviation

Response SLAs:
SEV-1: Acknowledge 5 min | Triage 15 min | Containment 30 min
SEV-2: Acknowledge 15 min | Triage 1 hr  | Containment 4 hr
SEV-3: Acknowledge 1 hr  | Triage 4 hr  | Remediation 48 hr
SEV-4: Acknowledge 24 hr | Triage 72 hr | Remediation next sprint
```

### 5.2 Detection Phase

```
DETECTION CHECKLIST
===================
[ ] Alert source identified (Forta / Defender Monitor / community report / internal)
[ ] Alert validated — not a false positive
[ ] Affected contracts and functions identified
[ ] Blast radius estimated (funds at risk, users affected, protocols affected)
[ ] Attacker address(es) identified if exploit in progress
[ ] Attack transaction(s) decoded (use tenderly.co/tx or heimdall)
[ ] MEV/sandwich relationship assessed
[ ] Confirm whether attack is still ongoing
```

### 5.3 Triage Template

```
INCIDENT TRIAGE — [INCIDENT-ID] — [TIMESTAMP UTC]
=================================================
Detected By:       [Forta bot / Monitor / user report]
Severity:          [SEV-1 / SEV-2 / SEV-3 / SEV-4]
Incident Commander: [Name]
Scribe:            [Name]

Summary:
  [One paragraph describing what is happening]

Affected Contracts:
  - 0xADDRESS (ContractName) — [impact description]

Attacker Address(es):
  - 0xATTACKER

Attack Transactions:
  - 0xTX_HASH — [description of what it does]

Funds at Risk:
  - $X ETH
  - $Y USDC
  Total: $Z

Current Status:
  [ ] Attack ongoing
  [ ] Attack completed
  [ ] Unclear

Immediate Actions Taken:
  - [timestamp] [action] by [person]

Next Decision Point: [time]
```

### 5.4 Containment (Pause)

```bash
# Emergency pause via cast (direct EOA call — fastest path)
cast send $VAULT_ADDRESS "pause()" \
  --private-key $GUARDIAN_PRIVATE_KEY \
  --rpc-url $RPC_URL \
  --priority-fee 50gwei \
  --gas-limit 100000

# Verify pause state
cast call $VAULT_ADDRESS "paused()(bool)" --rpc-url $RPC_URL

# Block attacker via allowlist removal (if applicable)
cast send $ACCESS_CONTROL "revokeRole(bytes32,address)" \
  $(cast keccak "OPERATOR_ROLE") \
  $ATTACKER_ADDRESS \
  --private-key $ADMIN_KEY \
  --rpc-url $RPC_URL
```

### 5.5 Root Cause Analysis Framework

```
RCA CATEGORIES (tag every incident with at least one)
=====================================================
LOGIC    — Business logic flaw (wrong calculation, missing check)
REENTRY  — Reentrancy vulnerability
ACCESS   — Access control bypass or missing modifier
ORACLE   — Price oracle manipulation or staleness
UPGRADE  — Upgrade introduced regression; storage collision
MATH     — Integer overflow/underflow; precision loss
CONFIG   — Misconfigured parameter; wrong address at deployment
SOCIAL   — Social engineering; key compromise; phishing
INFRA    — RPC failure; indexer outage; monitoring gap
EXTERNAL — Dependency exploit (library, protocol integration)
```

### 5.6 Recovery Procedure

```
RECOVERY CHECKLIST
==================
Pre-Recovery
[ ] Root cause fully understood and documented
[ ] Fix developed and reviewed by at least 2 engineers
[ ] Fix tested on forked mainnet reproducing the exploit
[ ] Auditor review of fix (expedited if needed)
[ ] Communication drafted (users, community, partners)
[ ] Rescue plan for stuck funds if applicable

Deployment
[ ] Multisig signers assembled (require quorum)
[ ] New implementation deployed and verified on Etherscan
[ ] Upgrade proposal queued through Defender Admin
[ ] Timelock delay waived if guardian role permits (document justification)
[ ] Upgrade executed; state verified on-chain

Post-Deployment
[ ] Contract unpaused
[ ] All monitoring alerts re-armed
[ ] User communication published
[ ] Post-mortem scheduled (within 5 business days)
```

---

## 6. Emergency Procedures

### 6.1 Pause Mechanism Implementation

```solidity
// Layered pause architecture
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

abstract contract EmergencyPausable is AccessControl, Pausable {
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

    // Granular pause: pause individual functions without full halt
    mapping(bytes4 => bool) public functionPaused;

    event FunctionPaused(bytes4 indexed selector, address by);
    event FunctionUnpaused(bytes4 indexed selector, address by);
    event EmergencyAction(string action, address by, uint256 timestamp);

    modifier notFunctionPaused() {
        require(!functionPaused[msg.sig], "function paused");
        _;
    }

    // Full pause — guardian or admin
    function pause() external {
        require(
            hasRole(GUARDIAN_ROLE, msg.sender) ||
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "not guardian"
        );
        _pause();
        emit EmergencyAction("FULL_PAUSE", msg.sender, block.timestamp);
    }

    // Unpause requires higher authority than pause
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
        emit EmergencyAction("UNPAUSE", msg.sender, block.timestamp);
    }

    // Surgical pause of a single function
    function pauseFunction(bytes4 selector) external onlyRole(GUARDIAN_ROLE) {
        functionPaused[selector] = true;
        emit FunctionPaused(selector, msg.sender);
    }
}
```

### 6.2 Circuit Breaker Pattern

```solidity
// Rate-limiting circuit breaker for withdrawals
abstract contract WithdrawalCircuitBreaker {
    uint256 public constant PERIOD = 1 days;
    uint256 public constant MAX_WITHDRAWAL_BPS = 1000; // 10% of TVL per period

    uint256 public periodStart;
    uint256 public withdrawnInPeriod;
    bool public circuitBreakerTripped;

    event CircuitBreakerTripped(uint256 amount, uint256 limit, uint256 timestamp);
    event CircuitBreakerReset(address by, uint256 timestamp);

    function _checkCircuitBreaker(uint256 amount, uint256 totalAssets) internal {
        if (block.timestamp > periodStart + PERIOD) {
            periodStart = block.timestamp;
            withdrawnInPeriod = 0;
        }

        withdrawnInPeriod += amount;
        uint256 limit = (totalAssets * MAX_WITHDRAWAL_BPS) / 10000;

        if (withdrawnInPeriod > limit) {
            circuitBreakerTripped = true;
            emit CircuitBreakerTripped(withdrawnInPeriod, limit, block.timestamp);
            revert("circuit breaker: daily withdrawal limit exceeded");
        }
    }

    function resetCircuitBreaker() external onlyRole(DEFAULT_ADMIN_ROLE) {
        circuitBreakerTripped = false;
        withdrawnInPeriod = 0;
        emit CircuitBreakerReset(msg.sender, block.timestamp);
    }
}
```

### 6.3 Emergency Governance

```solidity
// Emergency governance: bypass timelock for critical fixes
// Requires supermajority of security council
contract EmergencyGovernance {
    uint256 public constant EMERGENCY_THRESHOLD = 4; // 4/6 signers
    uint256 public constant EXECUTION_WINDOW = 2 hours;

    mapping(bytes32 => uint256) public approvals;
    mapping(bytes32 => mapping(address => bool)) public hasApproved;
    mapping(bytes32 => uint256) public proposedAt;

    event EmergencyProposed(bytes32 indexed hash, address by);
    event EmergencyApproved(bytes32 indexed hash, address by, uint256 count);
    event EmergencyExecuted(bytes32 indexed hash);

    function proposeEmergency(
        address target,
        bytes calldata data
    ) external onlyCouncilMember returns (bytes32) {
        bytes32 hash = keccak256(abi.encode(target, data, block.timestamp / 3600));
        proposedAt[hash] = block.timestamp;
        emit EmergencyProposed(hash, msg.sender);
        return hash;
    }

    function approveEmergency(bytes32 hash) external onlyCouncilMember {
        require(!hasApproved[hash][msg.sender], "already approved");
        hasApproved[hash][msg.sender] = true;
        approvals[hash]++;
        emit EmergencyApproved(hash, msg.sender, approvals[hash]);
    }

    function executeEmergency(
        address target,
        bytes calldata data
    ) external onlyCouncilMember {
        bytes32 hash = keccak256(abi.encode(target, data, proposedAt[hash] / 3600));
        require(approvals[hash] >= EMERGENCY_THRESHOLD, "insufficient approvals");
        require(block.timestamp <= proposedAt[hash] + EXECUTION_WINDOW, "window expired");
        (bool ok,) = target.call(data);
        require(ok, "execution failed");
        emit EmergencyExecuted(hash);
    }
}
```

---

## 7. War Room Protocol

### 7.1 Role Assignments

```
WAR ROOM ROLES
==============
Incident Commander (IC)
  - Single decision-making authority
  - Calls go/no-go on all actions
  - Escalates to leadership if needed
  - Rotates every 4 hours in extended incidents

Technical Lead
  - Decodes attack transactions
  - Develops and reviews fix
  - Advises IC on technical options

Scribe
  - Logs every action with UTC timestamp
  - Maintains the incident timeline doc
  - Drafts communications

Communications Lead
  - Manages external messaging (Twitter/X, Discord, forum)
  - Coordinates with partners and integrators
  - Manages user-facing updates

Security Ops
  - Executes on-chain transactions (pauses, revocations)
  - Manages Defender and Forta configuration
  - Monitors attacker addresses

Legal/Compliance (escalate if >$500k impact)
  - Law enforcement contact if needed
  - Regulatory notification assessment
  - Safe harbor evaluation
```

### 7.2 Communication Templates

```
INITIAL INCIDENT ACKNOWLEDGMENT (public, post within 30 min of SEV-1)
======================================================================
We are aware of an issue affecting [Protocol Name] and are actively investigating.
As a precaution, [CONTRACT] has been paused. No further user action is required at this time.
We will provide an update within [X hours].

Do NOT interact with [Protocol Name] until this notice is lifted.

Status page: [URL]
```

```
INTERIM UPDATE (every 2 hours during active SEV-1)
==================================================
Update [N] — [HH:MM UTC]

Status: [Investigating / Contained / Remediating]

What we know:
- [Bullet points of confirmed facts only]

What we're doing:
- [Current actions]

What users should do:
- [Specific instructions or "no action needed"]

Next update: [time]
```

```
ALL-CLEAR NOTIFICATION
======================
The incident affecting [Protocol Name] has been resolved.

Root cause: [Brief technical summary]
Impact: [Funds lost / affected / not affected]
Fix: [What was deployed]

The protocol has been unpaused. All functions are operating normally.

A full post-mortem will be published within 5 business days.

Affected users: [Compensation plan if applicable]
```

### 7.3 Decision Framework

```
DECISION TREE — ACTIVE EXPLOIT
===============================

Funds actively draining?
  YES → Pause immediately → notify IC → start RCA in parallel
  NO  → Continue monitoring → assess blast radius

Pause sufficient to stop drain?
  YES → Pause → coordinate recovery
  NO  → Also: revoke attacker approvals, block addresses, contact block builders
          for tx blocking (Flashbots SUAVE / MEV blocker)

Can funds be rescued before attacker extracts?
  YES → Whitehack: deploy rescue tx with higher gas than attacker's pending tx
  NO  → Preserve evidence → document for recovery/legal

Attack vector fully understood?
  YES → Develop fix → emergency governance vote if needed
  NO  → Keep paused → bring in external security expertise
```

### 7.4 Timeline Documentation Template

```markdown
# Incident Timeline — [INCIDENT-ID]

| Time (UTC) | Actor           | Action                                         | Evidence          |
|------------|-----------------|------------------------------------------------|-------------------|
| 14:23:01   | Forta Bot       | Alert: FLASHLOAN-PROTOCOL-1 fired              | Alert hash: 0x... |
| 14:24:15   | PagerDuty       | SEV-1 page sent to on-call                    |                   |
| 14:26:00   | @alice          | Incident Commander declared, war room opened   | Slack thread      |
| 14:28:33   | @bob            | Attack tx decoded: reentrancy in withdraw()    | 0xTX_HASH         |
| 14:30:44   | @alice          | Decision: pause vault immediately              |                   |
| 14:31:02   | Security Ops    | pause() tx submitted                           | 0xPAUSE_TX        |
| 14:31:15   | Security Ops    | pause() confirmed, block 19,234,567            |                   |
| 14:32:00   | Comms           | Initial acknowledgment tweeted                 | link              |
| 14:45:00   | Tech Lead       | Root cause confirmed: missing reentrancy guard |                   |
| 16:00:00   | Tech Lead       | Fix developed and reviewed                     | PR #321           |
| 18:30:00   | Security Ops    | Fix deployed via emergency governance          | 0xFIX_TX          |
| 19:00:00   | Security Ops    | Vault unpaused                                 | 0xUNPAUSE_TX      |
| 19:05:00   | Comms           | All-clear posted                               | link              |
```

---

## 8. Transaction Monitoring

### 8.1 Mempool Monitoring for Front-Running Detection

```typescript
// monitor/mempool-monitor.ts
import { ethers } from "ethers";

const ATTACK_PATTERNS = [
  /flashloan/i,
  /liquidate.*borrow/i,
];

async function monitorMempool(
  provider: ethers.WebSocketProvider,
  protocolAddresses: Set<string>
) {
  provider.on("pending", async (txHash: string) => {
    try {
      const tx = await provider.getTransaction(txHash);
      if (!tx || !tx.to) return;

      if (!protocolAddresses.has(tx.to.toLowerCase())) return;

      // High-value transaction
      if (tx.value > ethers.parseEther("10")) {
        console.log(`Large pending tx: ${txHash} value: ${ethers.formatEther(tx.value)} ETH`);
      }

      // Unusually high gas price (potential front-run or sandwich)
      const baseFee = (await provider.getBlock("latest"))?.baseFeePerGas;
      if (baseFee && tx.maxFeePerGas && tx.maxFeePerGas > baseFee * 5n) {
        await sendAlert({
          severity: "medium",
          title: "High Gas Price Transaction to Protocol",
          body: `Tx ${txHash} has maxFeePerGas ${ethers.formatUnits(tx.maxFeePerGas, "gwei")} gwei (${Number(tx.maxFeePerGas / baseFee)}x base)`,
        });
      }
    } catch {
      // Tx may have been dropped; ignore
    }
  });
}
```

### 8.2 Multi-Block Attack Detection

```typescript
// Detect spread-out attack patterns (attackers split across blocks to avoid detection)
class AttackPatternDetector {
  private addressActivity: Map<string, { blocks: number[]; totalValue: bigint }> =
    new Map();

  private readonly WINDOW_BLOCKS = 10;
  private readonly TX_THRESHOLD = 5;
  private readonly VALUE_THRESHOLD = ethers.parseEther("100");

  recordActivity(address: string, block: number, value: bigint) {
    const key = address.toLowerCase();
    const existing = this.addressActivity.get(key) ?? {
      blocks: [],
      totalValue: 0n,
    };

    // Prune old blocks
    existing.blocks = existing.blocks.filter((b) => b > block - this.WINDOW_BLOCKS);
    existing.blocks.push(block);
    existing.totalValue += value;

    this.addressActivity.set(key, existing);

    if (
      existing.blocks.length >= this.TX_THRESHOLD ||
      existing.totalValue >= this.VALUE_THRESHOLD
    ) {
      return {
        suspicious: true,
        address,
        txCount: existing.blocks.length,
        totalValue: existing.totalValue,
      };
    }

    return { suspicious: false };
  }
}
```

### 8.3 Governance Attack Detection Patterns

```typescript
// Detect flash-loan-powered governance attacks
// Pattern: borrow tokens → vote → repay in same block
async function detectGovernanceFlashloan(
  txEvent: TransactionEvent
): Promise<Finding[]> {
  const findings: Finding[] = [];

  const hasFlashloan = /* check as above */ false;
  const hasVoteCast = txEvent.filterLog(
    "event VoteCast(address,uint256,uint8,uint256,string)",
    GOVERNOR_ADDRESS
  ).length > 0;

  const hasDelegation = txEvent.filterLog(
    "event DelegateVotesChanged(address,uint256,uint256)",
    TOKEN_ADDRESS
  ).length > 0;

  if (hasFlashloan && (hasVoteCast || hasDelegation)) {
    findings.push(
      Finding.fromObject({
        name: "Governance Flashloan Attack Vector",
        description: "Flashloan used in same tx as governance vote or delegation",
        alertId: "GOV-FLASHLOAN-1",
        severity: FindingSeverity.Critical,
        type: FindingType.Exploit,
        metadata: { txHash: txEvent.hash, from: txEvent.from },
      })
    );
  }

  return findings;
}
```

---

## 9. Alerting Infrastructure

### 9.1 PagerDuty Integration

```typescript
// alerting/pagerduty.ts
import { PagerDutyClient } from "@pagerduty/pdjs";

const pd = new PagerDutyClient({ token: process.env.PAGERDUTY_TOKEN! });

export interface Alert {
  severity: "critical" | "high" | "medium" | "low";
  title: string;
  body: string;
  txHash?: string;
  metadata?: Record<string, string>;
}

const SEVERITY_MAP = {
  critical: "critical",
  high:     "error",
  medium:   "warning",
  low:      "info",
} as const;

export async function sendAlert(alert: Alert): Promise<void> {
  await pd.events.sendEvent({
    data: {
      routing_key: process.env.PAGERDUTY_INTEGRATION_KEY!,
      event_action: "trigger",
      payload: {
        summary:   alert.title,
        severity:  SEVERITY_MAP[alert.severity],
        source:    "protocol-monitor",
        custom_details: {
          body:     alert.body,
          txHash:   alert.txHash ?? "",
          ...alert.metadata,
        },
      },
      links: alert.txHash
        ? [{ href: `https://etherscan.io/tx/${alert.txHash}`, text: "View on Etherscan" }]
        : [],
    },
  });
}

export async function resolveAlert(dedupKey: string): Promise<void> {
  await pd.events.sendEvent({
    data: {
      routing_key: process.env.PAGERDUTY_INTEGRATION_KEY!,
      event_action: "resolve",
      dedup_key: dedupKey,
    },
  });
}
```

### 9.2 Escalation Policy

```yaml
# PagerDuty escalation policy (Terraform / API representation)
escalation_policy:
  name: "Protocol Security Escalation"
  num_loops: 3
  rules:
    - escalation_delay_in_minutes: 5
      targets:
        - type: schedule_reference
          id: SCHEDULE_ON_CALL_SECURITY   # Primary on-call
    - escalation_delay_in_minutes: 10
      targets:
        - type: schedule_reference
          id: SCHEDULE_SECONDARY_SECURITY # Secondary on-call
        - type: user_reference
          id: USER_SECURITY_LEAD
    - escalation_delay_in_minutes: 15
      targets:
        - type: user_reference
          id: USER_CTO
        - type: user_reference
          id: USER_CEO            # Executive escalation for SEV-1
```

### 9.3 Slack / Telegram Bot

```typescript
// alerting/slack.ts
export async function sendSlackAlert(alert: Alert): Promise<void> {
  const color = {
    critical: "#FF0000",
    high:     "#FF6600",
    medium:   "#FFCC00",
    low:      "#36A64F",
  }[alert.severity];

  const payload = {
    attachments: [
      {
        color,
        title:  `[${alert.severity.toUpperCase()}] ${alert.title}`,
        text:   alert.body,
        fields: alert.txHash
          ? [{ title: "Transaction", value: `<https://etherscan.io/tx/${alert.txHash}|${alert.txHash}>`, short: false }]
          : [],
        footer: `protocol-monitor • ${new Date().toISOString()}`,
      },
    ],
  };

  await fetch(process.env.SLACK_WEBHOOK_URL!, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
}

// alerting/telegram.ts
export async function sendTelegramAlert(alert: Alert): Promise<void> {
  const text = [
    `*[${alert.severity.toUpperCase()}] ${escapeMarkdown(alert.title)}*`,
    escapeMarkdown(alert.body),
    alert.txHash ? `[View Tx](https://etherscan.io/tx/${alert.txHash})` : "",
  ]
    .filter(Boolean)
    .join("\n\n");

  await fetch(
    `https://api.telegram.org/bot${process.env.TELEGRAM_BOT_TOKEN}/sendMessage`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        chat_id: process.env.TELEGRAM_CHAT_ID,
        text,
        parse_mode: "MarkdownV2",
        disable_web_page_preview: true,
      }),
    }
  );
}

function escapeMarkdown(text: string): string {
  return text.replace(/[_*[\]()~`>#+=|{}.!\\-]/g, "\\$&");
}
```

### 9.4 Alert Deduplication and Suppression

```typescript
// Prevent alert storms during incidents
class AlertDeduplicator {
  private sent: Map<string, number> = new Map();
  private readonly cooldownMs: number;

  constructor(cooldownMs = 5 * 60 * 1000) { // 5 min default
    this.cooldownMs = cooldownMs;
  }

  shouldSend(key: string): boolean {
    const last = this.sent.get(key) ?? 0;
    const now = Date.now();
    if (now - last < this.cooldownMs) return false;
    this.sent.set(key, now);
    return true;
  }
}

const dedup = new AlertDeduplicator();

export async function sendDeduplicatedAlert(
  key: string,
  alert: Alert
): Promise<void> {
  if (!dedup.shouldSend(key)) return;
  await Promise.allSettled([
    sendAlert(alert),         // PagerDuty
    sendSlackAlert(alert),
    sendTelegramAlert(alert),
  ]);
}
```

---

## 10. Post-Mortem Framework

### 10.1 Post-Mortem Document Template

```markdown
# Post-Mortem — [INCIDENT-ID] — [Protocol Name]

**Date:** YYYY-MM-DD
**Severity:** SEV-N
**Duration:** X hours Y minutes (first alert to resolution)
**Incident Commander:** [Name]
**Authors:** [Names]
**Status:** Draft / Under Review / Final

---

## Executive Summary

[2-3 sentences: what happened, impact, and what fixed it. No jargon — assume non-technical reader.]

---

## Impact

| Metric              | Value                |
|---------------------|----------------------|
| Funds lost          | $X                   |
| Users affected      | N                    |
| Downtime            | X hours              |
| Chains affected     | mainnet, arbitrum    |
| Partner integrations impacted | [list]   |

---

## Timeline (all times UTC)

[See Section 7.4 format]

---

## Root Cause

**Category:** [LOGIC / REENTRY / ACCESS / ORACLE / UPGRADE / MATH / CONFIG / SOCIAL / INFRA / EXTERNAL]

**Technical Description:**

[Precise technical explanation of the vulnerability. Include:
- The vulnerable code path
- The preconditions required to trigger it
- Why it was not caught in testing/audit]

**Code snippet (vulnerable):**
\`\`\`solidity
// The vulnerable code
\`\`\`

**Code snippet (fixed):**
\`\`\`solidity
// The fix
\`\`\`

---

## Contributing Factors

- [ ] Test coverage gap: [describe]
- [ ] Audit finding missed or accepted risk: [describe]
- [ ] Monitoring gap: [describe]
- [ ] Process gap: [describe]
- [ ] Dependency risk: [describe]

---

## What Went Well

- [Response time was within SLA]
- [Pause mechanism worked correctly]
- [Communication was timely]

---

## What Went Poorly

- [Alert fired 3 minutes late due to RPC node lag]
- [Guardian key holder was unavailable for 8 minutes]
- [Comms took 45 min instead of 30 min target]

---

## Action Items

| ID  | Action                                      | Owner   | Due Date   | Status  |
|-----|---------------------------------------------|---------|------------|---------|
| A01 | Add reentrancy guard to withdraw()          | @alice  | 2026-04-01 | Done    |
| A02 | Add invariant fuzz test for withdraw flow   | @bob    | 2026-04-07 | Open    |
| A03 | Add Forta bot for reentrant call detection  | @carol  | 2026-04-07 | Open    |
| A04 | Update guardian key rotation schedule       | @dave   | 2026-04-14 | Open    |
| A05 | Conduct tabletop exercise for SEV-1 drill   | @alice  | 2026-04-30 | Open    |

---

## Lessons Learned

[Free-form paragraph synthesis: what should the team internalize beyond the specific action items?]
```

### 10.2 Action Item Tracking

```
POST-MORTEM ACTION TRACKING CADENCE
=====================================
Week 1:    All A0x items from post-mortem reviewed in security sync
Week 2:    Progress update on all open items
Month 1:   Retrospective: are systemic items addressed?
Quarter:   Trend analysis across all incidents — recurring categories?

Key metrics to track:
  - MTTD (Mean Time to Detect)
  - MTTA (Mean Time to Acknowledge)
  - MTTC (Mean Time to Contain)
  - MTTF (Mean Time to Fix / Full Recovery)
  - Repeat incident rate by root cause category
```

---

## 11. Bug Bounty Programs

### 11.1 Immunefi Program Setup

```yaml
# Immunefi program configuration (representative structure)
program:
  name: "Protocol Bug Bounty"
  assets:
    - address: "0xYOUR_VAULT"
      type: "smart_contract"
      severity_scope: ["critical", "high", "medium"]
    - address: "0xYOUR_GOVERNOR"
      type: "smart_contract"
      severity_scope: ["critical", "high"]

  rewards:
    smart_contract:
      critical:
        range: "$50,000 – $1,000,000"
        payout_type: "USDC"
        requires: "direct loss of funds or permanent protocol freezing"
      high:
        range: "$10,000 – $50,000"
        requires: "significant loss of funds with preconditions"
      medium:
        range: "$1,000 – $10,000"
        requires: "temporary freezing or loss <$1M"
      low:
        range: "$100 – $1,000"
        requires: "minimal impact"

  out_of_scope:
    - "Issues in third-party contracts not deployed by the protocol"
    - "Frontend issues not leading to direct fund loss"
    - "Already known issues listed at: [URL]"
    - "Issues requiring physical access to signer hardware"
    - "Governance attacks requiring >10% of circulating supply"

  safe_harbor:
    enabled: true
    statement: |
      We commit not to pursue legal action against researchers who:
      1. Do not exploit the vulnerability beyond proof-of-concept
      2. Report through our responsible disclosure process
      3. Do not publicly disclose before a fix is deployed
```

### 11.2 Severity Classification

```
SEVERITY MATRIX
===============
Critical ($50k–$1M)
  - Direct theft of user funds
  - Permanent protocol freezing
  - Governance takeover leading to fund drainage
  - Private key exposure for admin roles

High ($10k–$50k)
  - Theft of funds with preconditions (requires other user action)
  - Significant protocol manipulation (price, votes) leading to economic harm
  - Bypass of access control with material impact

Medium ($1k–$10k)
  - Temporary freezing of contracts or funds (<24 hours recoverable)
  - Griefing / DoS without permanent impact
  - Events emitting incorrect data

Low ($100–$1k)
  - Code quality issues with no practical exploit path
  - Missing input validation (no security impact)
  - Informational / best practice deviations
```

### 11.3 Responsible Disclosure Process

```
DISCLOSURE TIMELINE
===================
Day 0:    Report received via Immunefi / security@protocol.xyz
Day 1:    Acknowledgment sent to researcher; initial severity assessment
Day 3:    Technical validation complete; severity confirmed
Day 7:    Fix developed and internally reviewed
Day 14:   Fix audited (expedited if Critical)
Day 21:   Fix deployed to production
Day 28:   Researcher notified; bounty paid
Day 35:   Public disclosure (coordinated with researcher)
          — Protocol blog post
          — Immunefi disclosure
          — CVE filing if applicable

Researcher may request earlier disclosure after fix is deployed.
Protocol may request extension if systemic fix requires >21 days.
Both parties must agree to timeline changes in writing.
```

---

## 12. Security Operations

### 12.1 Key Management

```
KEY MANAGEMENT POLICY
======================
Guardian / Emergency Keys
  Storage:    Hardware wallet (Ledger/Trezor) — NEVER software wallet
  Location:   Geographically distributed (min 3 locations for multisig)
  Access:     Named individuals only; no shared credentials
  Rotation:   Every 90 days or immediately on personnel change
  Backup:     Shamir's Secret Sharing (SSS) with 3-of-5 shares; shares in safes

Operational Keys (Relayer)
  Storage:    Defender Relayer (isolated from other systems)
  Funding:    Max 0.5 ETH; auto-top-up from treasury multisig
  Permissions: Allowlisted recipient addresses only
  Rotation:   Every 180 days

Monitoring / Read-Only Keys
  Storage:    Environment variables in secrets manager (AWS SSM / GCP Secret Manager)
  Permissions: No transaction signing capability
  Rotation:   Every 365 days

Key Ceremony (for new multisig key generation)
  1. Air-gapped machine (never connected to internet)
  2. Hardware wallet initialized with new seed
  3. Seed backed up via SSS immediately
  4. Public address verified by 2nd person
  5. Hardware wallet sealed and stored
  6. Ceremony recorded in key registry (address, date, holder, purpose)
```

### 12.2 Multisig Monitoring

```typescript
// Monitor multisig for unusual activity
const SAFE_ABI = [
  "event ExecutionSuccess(bytes32 txHash, uint256 payment)",
  "event ExecutionFailure(bytes32 txHash, uint256 payment)",
  "event AddedOwner(address owner)",
  "event RemovedOwner(address owner)",
  "event ChangedThreshold(uint256 threshold)",
  "function getOwners() view returns (address[])",
  "function getThreshold() view returns (uint256)",
];

async function monitorMultisig(
  provider: ethers.WebSocketProvider,
  safeAddress: string
) {
  const safe = new ethers.Contract(safeAddress, SAFE_ABI, provider);

  // Baseline owners and threshold at startup
  let knownOwners = new Set(
    (await safe.getOwners()).map((a: string) => a.toLowerCase())
  );
  let knownThreshold = await safe.getThreshold();

  safe.on("AddedOwner", async (owner, event) => {
    await sendAlert({
      severity: "critical",
      title: "Multisig Owner Added",
      body: `New owner ${owner} added to Safe ${safeAddress}`,
      txHash: event.transactionHash,
    });
    knownOwners.add(owner.toLowerCase());
  });

  safe.on("RemovedOwner", async (owner, event) => {
    await sendAlert({
      severity: "critical",
      title: "Multisig Owner Removed",
      body: `Owner ${owner} removed from Safe ${safeAddress}`,
      txHash: event.transactionHash,
    });
    knownOwners.delete(owner.toLowerCase());
  });

  safe.on("ChangedThreshold", async (threshold, event) => {
    const direction = threshold < knownThreshold ? "REDUCED" : "increased";
    await sendAlert({
      severity: threshold < knownThreshold ? "critical" : "high",
      title: `Multisig Threshold ${direction}`,
      body: `Threshold changed from ${knownThreshold} to ${threshold} on Safe ${safeAddress}`,
      txHash: event.transactionHash,
    });
    knownThreshold = threshold;
  });
}
```

### 12.3 Access Review Cadence

```
ACCESS REVIEW SCHEDULE
======================
Weekly
  [ ] Defender Relayer balance check (alert if <0.1 ETH)
  [ ] Review any new Defender Actions deployed
  [ ] Review Forta bot health (all bots green)

Monthly
  [ ] Full access control matrix audit (compare on-chain roles to documented matrix)
  [ ] Review all role grants and revocations from past 30 days
  [ ] Confirm multisig owner set unchanged; verify signers are still active
  [ ] Rotate any compromised or suspected credentials

Quarterly
  [ ] Hardware wallet firmware updates
  [ ] Review and rotate operational keys (relayers, API keys)
  [ ] Off-boarding check: departed personnel removed from all access
  [ ] Bug bounty program review: scope, rewards, known issues list
  [ ] Security drill / tabletop exercise (simulate SEV-1)

Annually
  [ ] Full third-party security audit
  [ ] Penetration testing of off-chain infrastructure
  [ ] Key ceremony for any new multisig keys
  [ ] Disaster recovery test (full protocol restart from scratch)
  [ ] Update threat model document
```

### 12.4 Defender API Monitoring Script

```typescript
// ops/check-defender-health.ts
import { Defender } from "@openzeppelin/defender-sdk";

const client = new Defender({
  apiKey: process.env.DEFENDER_API_KEY!,
  apiSecret: process.env.DEFENDER_API_SECRET!,
});

async function checkDefenderHealth() {
  const issues: string[] = [];

  // Check relayer balances
  const relayers = await client.relay.list();
  for (const relayer of relayers) {
    const info = await client.relay.get(relayer.relayerId);
    const balanceEth = parseFloat(info.balance ?? "0") / 1e18;
    if (balanceEth < 0.05) {
      issues.push(`Relayer ${relayer.name}: LOW BALANCE ${balanceEth.toFixed(4)} ETH`);
    }
  }

  // Check monitor status
  const monitors = await client.monitor.list();
  for (const monitor of monitors) {
    if (monitor.paused) {
      issues.push(`Monitor "${monitor.name}" is PAUSED`);
    }
  }

  if (issues.length > 0) {
    await sendAlert({
      severity: "high",
      title: "Defender Health Check Failures",
      body: issues.join("\n"),
    });
  } else {
    console.log(`[${new Date().toISOString()}] Defender health: OK`);
  }
}

// Run every 15 minutes via cron
checkDefenderHealth().catch(console.error);
```

---

## Quick Reference Cards

### Emergency Pause — 60-Second Runbook

```bash
# 1. Confirm attack (30 seconds)
cast call $VAULT "paused()(bool)" --rpc-url $RPC       # should be false
cast tx $ATTACK_TX --rpc-url $RPC | grep -E "to:|value:"

# 2. Pause (15 seconds)
cast send $VAULT "pause()" \
  --private-key $GUARDIAN_KEY \
  --rpc-url $RPC \
  --priority-fee 100gwei

# 3. Verify (15 seconds)
cast call $VAULT "paused()(bool)" --rpc-url $RPC       # must be true
```

### Key Contract Addresses Template

```bash
# .env.production — populate before deployment
VAULT_ADDRESS=
GOVERNOR_ADDRESS=
TIMELOCK_ADDRESS=
TREASURY_MULTISIG=
GUARDIAN_EOA=
PROXY_ADMIN=
DEFENDER_RELAYER_ADDRESS=
FORTA_BOT_ID=
```

### Incident Communication Checklist

```
[ ] War room channel created (#incident-YYYYMMDD-N)
[ ] Incident Commander named and acknowledged
[ ] Initial public acknowledgment posted (<30 min from SEV-1 detection)
[ ] Partner integrators notified directly (DM / email)
[ ] Status page updated
[ ] Interim updates every 2 hours
[ ] All-clear posted with next steps
[ ] Post-mortem scheduled
[ ] Bug bounty status communicated (if reporter exists)
```
