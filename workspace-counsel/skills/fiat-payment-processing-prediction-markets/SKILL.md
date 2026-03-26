# SKILL: Fiat Payment Processing for Prediction Markets

## Purpose
Navigate the unique challenges of obtaining and maintaining fiat payment processing (credit cards, ACH, bank wires) for prediction market, skill-game competition, and wagering-adjacent platforms. This is a critical operational dependency that must be solved before launch.

## Risk Level
🔴 High — Payment processing is the single biggest operational risk for prediction market and gambling-adjacent platforms. Banks and card networks aggressively close accounts in this category. A single chargeback wave or MCC reclassification can kill the product. Plan this before writing code.

---

## Why Fiat Payment Processing Is Hard for This Category

### Card Network Rules
**Visa Merchant Category Codes (MCCs)**:
- MCC 7995: "Gambling — Horse Racing, Lottery, Off-Track Betting" — PROHIBITED for most card issuers
- MCC 7994: "Video Game Arcades/Establishments" — Generally acceptable
- MCC 7993: "Video Games" — Generally acceptable
- MCC 5816: "Digital Goods / Games" — Generally acceptable for skill-game entry fees

**The core problem**: If your platform is coded as MCC 7995 (gambling), most card-issuing banks will decline transactions. Cardholders often have gambling blocks on their accounts. Processing fails.

**Solution**: Structure and document the platform as MCC 7993/7816/5816 (skill game / digital goods). Requires that the product genuinely qualifies.

### Issuing Bank Blocks
Even with correct MCC:
- Many issuing banks block gambling-adjacent MCCs by default
- Some issuers block ANY real-money gaming transaction
- Customer's card may be approved at processor level but declined at issuer level
- Creates failed-transaction rate that looks like fraud to processors

### Acquiring Bank Risk Tolerance
- Standard acquiring banks (Chase, Wells Fargo) will not process gambling or gambling-adjacent payments
- Need a **high-risk acquiring bank** or processor
- High-risk processing: Higher rates (2.9% + $0.30 → 4–6% + higher fixed), rolling reserves, additional documentation

---

## Payment Processing Options

### Option 1: Standard Processors (Low-Risk MCCs Only)
**Stripe**:
- Will process skill-game entry fees if product documented as skill competition
- Explicitly prohibits: "gambling, contest prizes, lottery" in restricted businesses
- Has approved: DFS platforms, coding competitions, trivia games
- Key requirement: Must not describe as "betting" or "wagering" in marketing or T&C
- Chargeback limit: 0.5% for optimal standing; >1% triggers review; >2% = termination
- **Verdict**: Viable for pure skill competition (Agent Arena / Bouts Layer 1)

**Braintree (PayPal)**:
- Similar restrictions to Stripe
- PayPal itself is more restrictive (blocks many gaming categories)
- Braintree: More flexible than PayPal direct; negotiable on category

**Square**: Generally too restrictive for prediction market adjacent; stick with Stripe/Braintree

### Option 2: High-Risk Processors (Gambling/Wagering Adjacent)
**Nuvei**:
- Specializes in gaming and gambling payment processing
- Licensed for sports betting, casino, and prediction market categories
- Higher rates but handles the category properly
- Requires: RG program documentation, KYC/AML, proof of licenses where applicable

**Paysafe (Skrill/Neteller/Paysafecard)**:
- Major gaming payment processor globally
- Strong US presence for DFS/gaming
- Requires merchant agreement with gaming compliance documentation

**PaymentCloud**:
- US-focused high-risk processor
- Works with gaming, gambling-adjacent, sweepstakes
- Mid-tier pricing; good for early stage

**Bankful / Paybly**:
- Smaller high-risk processors
- More flexible on documentation requirements
- Higher rates; lower volume capacity

**Priority Commerce / Clearent**:
- Mid-market processors that handle gaming-adjacent
- Require proper MCC documentation

### Option 3: ACH / Bank Transfers (Lower Risk)
**Plaid + ACH**:
- Bank-to-bank transfers avoid card network rules
- No MCC classification for ACH
- Lower fees (0.5–1% or flat)
- Slower settlement (2–3 days)
- No chargeback rights for users (ACH disputes = reversal claims; easier to defend)
- **Recommended**: ACH as primary, card as supplementary — reduces dependency on card network approval

**Dwolla**:
- ACH payment platform
- Works with gaming-adjacent platforms
- Requires their standard approval process; generally more flexible than card processors

**Synapse / Column Bank**:
- Banking-as-a-service; can provide ACH rails with more flexible terms

### Option 4: Crypto Onramps (Fiat → Crypto)
**MoonPay**:
- Allows users to buy USDC/ETH with credit card
- MoonPay handles card processing; you receive crypto
- Offloads payment processing risk to MoonPay
- Fee: ~3–4.5% on fiat-to-crypto conversion

**Transak**:
- Similar to MoonPay
- Wider international coverage
- Fees: 2.5–3.5%

**Stripe Crypto Onramp**:
- Stripe's own crypto onramp product
- More seamless UX than MoonPay
- Currently limited to USDC
- Stripe handles all card processing compliance

**Strategy**: Accept USD via Stripe → auto-convert to USDC → use USDC for platform operations. Keeps Stripe relationship clean (you're selling digital goods/services) while crypto handles prize pool mechanics.

---

## MCC Classification Strategy

### For Pure Skill Competition (Agent Arena / Bouts Layer 1)
**Target MCC**: 5816 (Digital Goods / Games) or 7993 (Video Games)
**Positioning**:
- "AI coding competition platform"
- "Skill-based technology challenge"
- Entry fees = "contest entry" not "bet" or "wager"
- Prizes = "competition prizes" not "winnings"

**Documentation for processor**:
- Product description emphasizing skill over chance
- Terms of Service with no gambling language
- Proof of skill-based judging criteria
- Comparison to DFS (already approved category)

### For Prediction Market Layer (If Any)
**Required**: High-risk processor (Nuvei, Paysafe) or ACH
**Cannot use**: Stripe, standard Braintree in this configuration
**Alternative**: Crypto-native (USDC only); no fiat card processing for this layer

---

## Required Documentation for High-Risk Merchant Account

1. **Business documentation**: Articles of incorporation, EIN, bank statements
2. **Product description**: Clear explanation of what users are paying for
3. **Terms of Service**: Must include refund policy, complaint process, chargeback dispute process
4. **MCC justification**: Written argument for skill-game (not gambling) classification
5. **Responsible Gaming Policy** (even if not required, shows legitimacy)
6. **KYC/AML documentation**: Your user verification procedures
7. **Chargeback management plan**: How you handle disputes
8. **Processing history** (if any): Existing statements from prior processors
9. **Website URL**: Must be live and professional at time of application
10. **Owner ID verification**: All beneficial owners >25% must provide ID

---

## Chargeback Management (Critical)

### The Numbers That Matter
- **Visa threshold**: >0.9% chargeback rate = "excessive" → remediation program or termination
- **Mastercard threshold**: >1% = "excessive"
- **Stripe**: >0.5% = review; >1% = likely termination

### Common Chargeback Triggers for This Category
- User loses money and claims "unauthorized transaction"
- User forgot they signed up
- User didn't recognize company name on statement
- User disputes payout calculation
- Friendly fraud (deliberate dispute of legitimate charge)

### Prevention Strategies
1. **Descriptor**: Ensure your merchant descriptor is clear (not "PERLANT AI" — make it recognizable)
2. **Email receipts**: Immediate confirmation with amount and description
3. **Transaction history**: Easy to access in-app (user can see what they paid for)
4. **Pre-chargeback alerts**: Stripe Radar, Verifi (Visa), Ethoca (Mastercard) — catch disputes before they become chargebacks
5. **Refund policy**: Generous refund window prevents chargebacks (7-day no-questions refund better than fighting chargebacks)
6. **Confirmation friction**: "You are entering a paid contest. Your card will be charged $X" — explicit confirmation
7. **Customer support**: Fast response to billing questions prevents charge escalation to chargeback

---

## Banking Relationship Risk

### The De-banking Problem
- Banks have closed accounts of crypto/gambling-adjacent companies without warning
- "Operation Choke Point" precedent — banking regulators informally pressured banks to avoid certain industries
- Under current administration (2025+): Less de-banking pressure; but risk persists at bank level

### Mitigation
1. **Multiple bank accounts**: Primary + backup; don't hold all funds in one institution
2. **Crypto treasury**: Hold portion of operating funds in USDC as hedge against bank closure
3. **Fintech alternatives**: Mercury, Relay, Arc — more crypto/startup-friendly banks
4. **Avoid the word "gambling"**: Internally and externally. Documentation is discoverable.

### Recommended Banking Stack
- **Primary**: Mercury Bank (crypto-friendly, startup-focused)
- **Backup**: Relay or Arc
- **Reserve**: USDC on Coinbase Prime or Circle Account

---

## Compliance Requirements for Payment Processing

### KYC Requirements (Processor-Mandated)
- User identity verification before first deposit
- SSN/EIN collection for tax reporting
- OFAC screening (no sanctioned individuals)
- Most processors require at minimum: name, address, DOB, email

### AML Requirements
- Transaction monitoring for unusual patterns
- SAR filing capability for suspected money laundering
- Enhanced due diligence for large transactions (>$3,000 in 30 days typically)
- See: `anti-money-laundering-deep` skill for full AML program

---

## Iowa Angle
- Iowa Code § 533C: Iowa Money Services Act — if you're holding user funds (float), you may need Iowa MTL
- Iowa Division of Banking: Engage early; Iowa has been relatively favorable to fintech
- Iowa-based entity + Iowa banking relationships: Local credit unions (CUNA Mutual, Greater Iowa Credit Union) may be more flexible than national banks for this category
- Iowa has no state prohibition on skill-game entry fees specifically

---

## Minimum Viable Payment Stack (Pre-Launch)
1. ✅ Stripe for skill-competition entry fees (MCC 7993/5816)
2. ✅ Plaid/ACH as alternative payment method
3. ✅ MoonPay or Stripe Crypto Onramp for crypto-native users
4. ✅ Merchant descriptor that users will recognize
5. ✅ Immediate email receipt with clear transaction description
6. ✅ Pre-chargeback alert enrollment (Verifi + Ethoca)
7. ✅ Refund policy: 7-day no-questions for unused contest entries
8. ✅ Backup bank account (Mercury primary, Relay backup)

---

## Disclaimer
This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.
