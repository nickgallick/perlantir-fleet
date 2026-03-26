# SKILL: Payment Processing for Crypto Betting & Competition Platforms
**Version:** 1.0.0 | **Domain:** Payment Law, Fintech, MSB

---

## The Stripe Problem

**September 2023:** Stripe banned skill-based competitions and prediction markets.
- Classification as "real-money gaming" → immediate termination
- Applies to: entry fees, prize payouts, prediction market deposits/withdrawals
- Chargebacks from users claiming "gambling" accelerate deplatforming
- **Risk:** Sudden account termination with frozen funds
- **Never build a gaming/prediction platform's payment flow on Stripe as the primary processor**

---

## Alternative Fiat Payment Processors

| Processor | Gaming-Friendly | Notes |
|---|---|---|
| **Paysafe** (Skrill/Neteller) | ✅ Yes | Specifically serves gaming/betting; licensed; supports real-money gaming |
| **Nuvei** | ✅ Yes | Gaming-specialized; licensed in 200+ markets |
| **PayPal/Braintree** | ⚠️ Maybe | Allows gaming in some jurisdictions with prior approval; requires license |
| **Worldpay (FIS)** | ✅ Yes | Serves gambling industry with proper licensing |
| **Zero Hash** | ✅ Yes | Crypto-native; licensed MSB; purpose-built for fintech/gaming |
| **Circle** | ✅ Yes | USDC issuer; direct USDC acceptance eliminates processor risk |

---

## Crypto-Native Payment Architecture (RECOMMENDED)

### Why Crypto-Native Wins for This Use Case
1. No Stripe dependency
2. If non-custodial: no MSB concern
3. Global access (no geographic payment blocks)
4. Instant settlement (no T+2 ACH delays)
5. Target market (crypto-native users) already has wallets

### Architecture

```
User's Wallet (Coinbase/MetaMask/Phantom)
    ↓ USDC deposit
Smart Contract Escrow
    ↓ Contest resolution
Winner's Wallet
```

**The platform never touches funds.** This is the non-custodial design that avoids MSB classification.

### Supported Assets (in order of recommendation):
1. **USDC** — stable, regulated, widely held; Circle's issuer is NYDFS-licensed
2. **USDT** — wider global adoption; less US regulatory clarity on Tether itself
3. **ETH** — natural for Ethereum-based smart contracts; price volatility is UX risk
4. **SOL** — if building on Solana; fastest settlement, lowest fees

---

## Fiat On/Off Ramp Partners (When You Need to Support Fiat Users)

**Strategy:** YOU don't touch fiat. Your partner does. User buys USDC → uses your platform.

| Provider | What They Do | Who Handles KYC |
|---|---|---|
| **MoonPay** | Fiat → crypto widget; embed in your app | MoonPay handles all fiat KYC |
| **Transak** | Same; good global coverage | Transak handles KYC |
| **Ramp Network** | Fiat → crypto; strong EU coverage | Ramp handles KYC |
| **Sardine** | Faster ACH + fraud prevention | Sardine handles compliance |
| **Coinbase Pay** | Coinbase users buy crypto within your app | Coinbase handles KYC |

**Implementation:** Embed their SDK/widget. User clicks "Add Funds" → redirected to partner widget → USDC deposited to their wallet → they use your platform. You never see fiat.

---

## 1099 Reporting Obligations

### If You're a US Entity Paying Prizes:
- **Form 1099-MISC:** Required for prize payments >$600 (verify current IRS threshold)
- **Form W-2G:** For gambling winnings >$600 (if classified as gambling)
- **Collect before paying out:**
  - W-9 (US winners): Name, address, SSN/EIN
  - W-8BEN (non-US winners): Country, foreign TIN, treaty information
- **Annual IRS filing:** By January 31 following the tax year
- **Backup withholding:** 24% if winner doesn't provide valid W-9

### Crypto Prize Specifics:
- Payout in USDC/ETH: taxable at fair market value at time of payout
- Platform should provide: payout amount in USD equivalent, wallet address, date
- This data is needed by winner for their tax reporting; platform should make it easy to export

### If Offshore Entity Paying Prizes:
- Reporting obligations depend on entity jurisdiction
- No US 1099 obligation for non-US entity paying non-US recipients
- For US recipients: FATCA may require reporting; consult international tax counsel

---

## The Platform Payment Flow (Recommended Design)

### Entry Fee Collection
```
User connects wallet (MetaMask/Phantom/Coinbase Wallet)
→ App shows entry fee in USDC
→ User approves smart contract to spend USDC (ERC-20 approval)
→ Contest creation function pulls USDC into smart contract escrow
→ Platform emits event: ContestEntered(user, contestId, amount)
```

### Prize Distribution
```
Contest resolves (off-chain oracle or on-chain)
→ Smart contract calculates winners
→ Contract transfers USDC directly to winner wallets
→ Platform emits event: PrizeDistributed(winner, contestId, amount)
→ Platform provides winner with CSV for tax purposes
```

**Result:** Platform never custodies funds at any point. All movement is contract-to-wallet.

---

## Building Chargeback Protection (If Using Any Fiat Processor)
- Require KYC before any fiat deposit
- Display explicit TOS acceptance at deposit with "You understand this is a skill-based competition" language
- Record IP address, timestamp, TOS version at acceptance
- Self-exclusion check before every deposit
- Dispute evidence package: TOS acceptance record, usage history, payout history
- Some DFS operators: 10-15% chargeback rates before implementing these controls; 0.5-2% after

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
