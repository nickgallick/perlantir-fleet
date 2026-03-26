# SKILL 60: Fund Segregation & User Protection

## Purpose
Protect user funds from company bankruptcy and regulatory seizure. Understand the legal difference between "property of the estate" and "customer property." Design architecture that keeps user funds safe regardless of what happens to the company.

## Why This Matters — The Celsius/FTX Lesson
- **Celsius (2022)**: user "deposits" were classified as loans to Celsius under the TOS. In bankruptcy, users became unsecured creditors. Most received pennies on the dollar.
- **FTX (2022)**: user funds commingled with Alameda Research trading operations. No segregation. Users lost billions. Criminal prosecution of executives.
- **The rule**: if user funds touch your operating accounts, they are at risk in bankruptcy and regulatory seizure.

## CFTC Customer Fund Protection (Registered FCMs)
- 17 CFR Part 1 (§§1.20–1.30): Futures Commission Merchants must segregate customer funds
- Customer funds held in designated segregated accounts at CFTC-approved depositories
- Daily computation of segregation requirement
- Customer funds CANNOT be used for any company purpose (no commingling, no loans to affiliates)
- **Bankruptcy protection**: segregated customer funds are returned to customers FIRST, before general creditors

## For Non-Registered Platforms (Your Current Position)
- No explicit CFTC segregation requirement
- **BUT commingling user funds creates**:
  - Users as unsecured creditors in bankruptcy (they lose)
  - Evidence of operating as unregistered MSB or exchange
  - Fraud liability if funds are misappropriated
  - Personal liability for executives if funds are "borrowed" for operations
- **Best practice**: ALWAYS segregate user funds even if not legally required

## Non-Custodial Architecture (Strongest Protection)

### How It Works
- Smart contract holds ALL user funds — company NEVER has access to them
- User deposits directly to smart contract
- Payouts flow directly from smart contract to users
- Company operating funds: completely separate company wallet/bank account
- Even in company bankruptcy: smart contract funds are NOT property of the estate (the company never controlled them)

### Legal Analysis
- Bankruptcy Code §541: "property of the estate" = property in which the debtor has a legal or equitable interest
- If smart contract is truly non-custodial (company cannot unilaterally withdraw): company has no legal interest → NOT property of the estate
- **This is the strongest fund protection available**
- Caveat: if the company controls the admin keys and CAN drain the contract → it IS property of the estate. True non-custodial means NO ability to withdraw user funds unilaterally.

### Implementation Requirements
- Admin multisig: 3-of-5, with keyholders independent of each other (not all company employees)
- No single admin key that can drain user funds
- Emergency withdrawal mechanism: requires user signatures, not platform signatures
- Upgrade mechanism: if contract is upgradeable, upgrades require multi-sig and time-lock (48-72 hours), giving users time to exit before a malicious upgrade takes effect

## If Custodial (Not Recommended, But Sometimes Necessary)

### Required Safeguards
1. **Separate bank account**: labeled "Customer Segregated Account" — legally separate from operating accounts
2. **No commingling**: operating expenses NEVER paid from the customer account
3. **Daily reconciliation**: customer account balance ≥ total platform liabilities to users
4. **Quarterly independent audit**: accounting firm (Armanino, Mazars) attests to segregation
5. **Bankruptcy-remote SPV**: customer funds held in a Special Purpose Vehicle (SPV) that is legally separate from the operating company — SPV bankruptcy does not affect operating company and vice versa

### TOS Language (Critical for Custodial)
> "User deposits are held in segregated accounts and are not commingled with the Platform's operating funds. User deposits are the property of the user and are not loans to the Platform."

**NEVER use language that classifies deposits as loans.** That's the Celsius mistake.

## Proof of Reserves
Post-FTX, proof of reserves is a user EXPECTATION.

### Non-Custodial (On-Chain)
- Smart contract balance is publicly verifiable on the blockchain
- Publish the contract address prominently on the platform
- Users can verify: total contract balance ≥ sum of all user positions

### Custodial
- **Merkle tree proof**: publish a Merkle root of all user balances. Each user can verify their balance is included in the total without seeing other users' data.
- **Third-party attestation**: quarterly attestation by Armanino, Mazars, or similar firm
- **Real-time dashboard**: show total platform liabilities vs. total segregated funds (live)

## Risk Levels
- Non-custodial, true admin separation: 🟢 Low
- Non-custodial, admin can drain: 🔴 High (regulatory risk + user risk)
- Custodial without segregation: ⚫ Existential (FTX-level risk)
- Custodial with proper segregation + audit: 🟡 Medium

---
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
