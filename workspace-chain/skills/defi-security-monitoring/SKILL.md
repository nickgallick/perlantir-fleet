# DeFi Security Monitoring

## Post-Deployment Monitoring

### Forta (Real-Time Detection)
Automated bots that monitor transactions and alert on suspicious activity.

```javascript
// Detect suspicious market resolutions
const handleTransaction = async (txEvent) => {
  const resolveMarkets = txEvent.filterFunction("function resolveMarket(bytes32 questionId, bool outcome)");

  for (const resolveCall of resolveMarkets) {
    const { questionId, outcome } = resolveCall.args;

    // Alert if resolution happens very close to deadline (front-run risk)
    const market = await getMarketInfo(questionId);
    const timeUntilDeadline = market.resolutionDeadline - txEvent.block.timestamp;

    if (timeUntilDeadline < 3600) {  // Less than 1 hour
      findings.push(Finding.fromObject({
        name: "Suspicious Late Resolution",
        description: `Market ${questionId} resolved ${timeUntilDeadline}s before deadline`,
        severity: Severity.MEDIUM,
        type: FindingType.SUSPICIOUS
      }));
    }
  }

  return findings;
};

module.exports = { handleTransaction };
```

Register bot with Forta:
```bash
forta publish --dockerfile Dockerfile --manifest forta.config.json
forta-cli publish
```

### OpenZeppelin Defender
Comprehensive security operations platform.

#### Sentinels (Alerts)
```
Monitor transaction: resolveMarket() → Alert if suspicious outcome
Monitor value: treasury balance < $100K → Alert
Monitor function calls: Any pause() call → Alert + notif
```

#### Autotasks (Automated Responses)
```javascript
// Auto-pause market on suspicious activity
const handler = async (autotaskEvent) => {
  const txEvent = autotaskEvent.request.body;

  // Check if resolution is from approved oracle
  if (!isApprovedOracle(txEvent.from)) {
    // Call emergency pause
    const tx = await pauseMarkets();
    return {
      status: "paused",
      txHash: tx.hash
    };
  }
};
```

#### Relayers
Pre-funded contracts that can execute transactions (e.g., liquidations, oracle updates).
```javascript
const relayerProvider = new DefenderRelaySigner(credentials);
const signer = new ethers.Signer(relayerProvider);

async function updateOraclePrice(price) {
  const tx = await oracle.updatePrice(price);
  return tx.hash;
}
```

## Emergency Response Playbook

### Incident Severity
| Severity | Response Time | Actions |
|----------|---------------|---------|
| Critical (exploit in progress) | <15 min | Pause protocol, notify team, assess damage |
| High (vulnerability discovered) | <1 hour | Emergency patch, deploy, monitor |
| Medium (config issue) | <24 hours | Plan fix, test, deploy during maintenance |
| Low (improvement opportunity) | <7 days | Plan, review, schedule upgrade |

### War Room Checklist
```
[ ] Declare incident in Slack/Discord
[ ] Assemble technical team (eng, ops, security)
[ ] Isolate affected contracts (pause if possible)
[ ] Quantify damage (how much was stolen/lost)
[ ] Engage community (transparent comms)
[ ] Determine root cause
[ ] Prepare fix + test
[ ] Deploy fix
[ ] Monitor for follow-up attacks
[ ] Post-mortem (within 48h)
```

### Circuit Breakers (Automated Pauses)
```solidity
contract CircuitBreakerMarket is Market {
    uint256 public constant MAX_PRICE_CHANGE_BPS = 5000;  // 50% max change
    uint256 public lastPrice;
    bool public emergencyPause = false;

    modifier circuitBreaker() {
        if (emergencyPause) revert EmergencyPaused();
        uint256 currentPrice = getPrice();
        uint256 priceDelta = (currentPrice > lastPrice)
            ? currentPrice - lastPrice
            : lastPrice - currentPrice;

        if ((priceDelta * 10_000) / lastPrice > MAX_PRICE_CHANGE_BPS) {
            emergencyPause = true;
            emit CircuitBreakerTriggered(currentPrice);
        }
        _;
        lastPrice = currentPrice;
    }

    function buyShares(uint256 amount) external circuitBreaker {
        // ... buy logic
    }
}
```

## Monitoring Metrics

### Financial Invariants
- Total value locked (TVL) across all markets
- Total prize pool vs total fees collected
- Withdrawal request backlog (if liquidity constrained)
- Market utilization rates

### Smart Contract Health
- Failed transaction rate
- Reverted transfers
- Unusual access patterns (multiple failed auth checks)
- Storage slot anomalies

### Market Health
- Volume trends (spike = potential pump-and-dump?)
- Large position concentrations (whale risk)
- Price deviation from external sources (oracle manipulation attempt?)
- Order book depth (liquidity health)

### Example Monitoring Dashboard
```
App Health
├─ Contracts
│  ├─ Market Factory: 12.5M TVL, 15K transactions, 0 failed
│  ├─ Order Book: 340K pending orders, avg matching time 2.3s
│  └─ Oracle: 25 updates/day, 100% success rate
├─ Market Status
│  ├─ 847 active markets
│  ├─ $127M total volume (last 7 days)
│  ├─ Top 10 markets = 34% of volume (concentration)
│  └─ Avg market age: 14 days
└─ Financial
   ├─ Platform fees: $342K (last 30 days)
   ├─ Prize pool: $23M
   ├─ Fee treasury: $1.2M
   └─ Operator profit: $85K (last week)
```

## Bug Bounty Program (Immunefi)

Launch before mainnet:
```
Program name: PredictionMarket Protocol
Total budget: $500K
In scope: All contracts in src/
Out of scope: Frontend, tests, external dependencies

Severity Payouts:
Critical: $100K-500K (direct loss of funds)
High: $25K-100K (significant economic impact)
Medium: $5K-25K (conditional impact)
Low: $500-5K (best practice violations)
```

Immunefi handles: vetting hunters, managing disclosures, processing payments, legal protection.
