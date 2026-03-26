# Smart Contract DevOps

## CI/CD Pipeline (GitHub Actions)

```yaml
# .github/workflows/ci.yml
name: Smart Contract CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          submodules: recursive

      - name: Install Foundry
        uses: foundry-rs/foundry-toolchain@v1

      - name: Run Slither (static analysis)
        uses: crytic/slither-action@v0.3.0
        with:
          fail-on: high  # Fail CI on any HIGH finding
          slither-args: '--filter-paths test,script,lib'

      - name: Compile
        run: forge build --sizes  # Show contract sizes (alert if near 24KB)

      - name: Test
        run: forge test -vvv --gas-report
        env:
          MAINNET_RPC: ${{ secrets.MAINNET_RPC }}  # For fork tests

      - name: Coverage
        run: |
          forge coverage --report lcov
          # Fail if below 95% line coverage
          COVERAGE=$(forge coverage --report summary 2>&1 | grep "Lines" | awk '{print $4}' | tr -d '%')
          if (( $(echo "$COVERAGE < 95" | bc -l) )); then
            echo "Coverage $COVERAGE% below 95% threshold"
            exit 1
          fi

      - name: Gas Snapshot
        run: |
          forge snapshot
          forge snapshot --diff  # Fail if gas increased by > 5% on any function

      - name: Check Contract Sizes
        run: |
          forge build --sizes 2>&1 | awk '{if ($2 > 23000) print "WARNING: "$1" is "$2" bytes (near 24KB limit)"}'
```

## Deployment Manifest

Track every deployment permanently:

```typescript
// deployments/manifest.ts
interface Deployment {
  address: string
  txHash: string
  blockNumber: number
  deployer: string
  constructorArgs: unknown[]
  compilerVersion: string
  optimizationRuns: number
  deployedAt: string  // ISO timestamp
  verified: boolean
  proxyOf?: string    // If this is a proxy, point to implementation
  implementationOf?: string  // If this is an implementation
}

interface DeploymentManifest {
  [chainId: number]: {
    [contractName: string]: Deployment
  }
}

// deployments/manifest.json
{
  "8453": {
    "MarketFactory": {
      "address": "0x1234...",
      "txHash": "0xabcd...",
      "blockNumber": 15000000,
      "deployer": "0xSafe...",
      "constructorArgs": ["0xUSDC...", "0xOracle..."],
      "compilerVersion": "0.8.24",
      "optimizationRuns": 200,
      "deployedAt": "2026-03-26T00:00:00Z",
      "verified": true
    }
  }
}
```

## Key Management Hierarchy

```
COLD (Hardware + Multi-sig):
  Protocol ownership, upgrade authority
  Threshold: 3-of-5 Safe
  Signers: Ledger hardware wallets only
  Never online, never automated

WARM (Multi-sig):
  Parameter changes, fee updates, oracle updates
  Threshold: 2-of-3 Safe
  Signers: Mix of hardware + cloud HSM
  Used: weekly or less

HOT (Automated, Single Key):
  Keeper bots, liquidation bots, oracle updates
  Single EOA, cloud HSM (AWS KMS/GCP KMS)
  Used: multiple times per day
  Minimally funded (only what's needed)
  Key rotated monthly
```

### AWS KMS Signing

```typescript
import { KMSClient, SignCommand } from '@aws-sdk/client-kms'
import { createWalletClient, kmsKeyToAddress } from 'viem/accounts'

const kms = new KMSClient({ region: 'us-east-1' })

// Sign transaction with KMS key (private key never leaves AWS hardware)
async function kmsSign(digest: Uint8Array, keyId: string): Promise<{ r: string, s: string, v: number }> {
  const command = new SignCommand({
    KeyId: keyId,
    Message: digest,
    MessageType: 'DIGEST',
    SigningAlgorithm: 'ECDSA_SHA_256',
  })
  const response = await kms.send(command)
  return parseDERSignature(response.Signature!)
}
```

## Monitoring Stack

```yaml
# monitoring/forta-bot.js — Detect suspicious activity
const { Finding, FindingSeverity, FindingType } = require('forta-agent')

const handleTransaction = async (txEvent) => {
  const findings = []

  // Alert on large withdrawals
  const withdrawals = txEvent.filterFunction('function withdraw(uint256)')
  for (const withdrawal of withdrawals) {
    if (withdrawal.args.amount > parseUnits('100000', 6)) {  // >$100K
      findings.push(Finding.fromObject({
        name: 'Large Withdrawal',
        description: `$${formatUnits(withdrawal.args.amount, 6)} withdrawn`,
        alertId: 'LARGE-WITHDRAWAL',
        severity: FindingSeverity.High,
        type: FindingType.Info
      }))
    }
  }

  // Alert on access control changes
  const roleGrants = txEvent.filterLog(
    'event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)'
  )
  if (roleGrants.length > 0) {
    findings.push(Finding.fromObject({
      name: 'Role Granted',
      description: `Role ${roleGrants[0].args.role} granted to ${roleGrants[0].args.account}`,
      alertId: 'ROLE-CHANGE',
      severity: FindingSeverity.Critical,
      type: FindingType.Suspicious
    }))
  }

  return findings
}

module.exports = { handleTransaction }
```

## Runbooks (For Every Alert)

```markdown
## RUNBOOK: Large Withdrawal Alert

**Trigger**: Any single withdrawal > $100K USDC

**Severity**: HIGH

**Steps**:
1. Check if withdrawal is from a known address (team, partner, market maker)
   → If yes: log the event, no action needed
   → If unknown address: proceed to step 2

2. Verify this isn't an exploit:
   - Check health factor of withdrawer's position
   - Check if preceded by unusual deposit activity
   - Check if flash loan was involved in same tx

3. If suspicious:
   a. Alert security team (PagerDuty)
   b. Consider emergency pause (needs 2-of-3 guardian multisig)
   c. Post in team Discord: "Potential exploit, investigating"

4. Resolution:
   - If exploit: execute war room protocol (see WAR_ROOM.md)
   - If false alarm: document and tune alert threshold
```
