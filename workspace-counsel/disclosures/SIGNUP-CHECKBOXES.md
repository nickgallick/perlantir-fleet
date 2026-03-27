# SIGNUP CHECKBOXES — Registration Flow

## Implementation Notes for Maks
- All checkboxes are REQUIRED (cannot proceed without checking)
- Each checkbox must be individually checked — no "check all" master checkbox
- Checkbox state must be stored with timestamp at account creation
- Display on registration page BEFORE account is created
- Link text must open actual documents (not just scroll)

---

## Checkbox 1 — Age Verification
```
[ ] I confirm that I am at least 18 years of age.
```
**Required**: Yes — block registration if unchecked
**Store**: age_verified: true, age_verified_at: timestamp

---

## Checkbox 2 — Jurisdiction Eligibility
```
[ ] I confirm that I am not a resident of Washington, Arizona, Louisiana, 
    Montana, or Idaho, where this service is not available.
```
**Required**: Yes — block registration if unchecked
**Store**: jurisdiction_confirmed: true, jurisdiction_confirmed_at: timestamp
**Also**: Collect state field at registration; auto-flag if state = WA/AZ/LA/MT/ID

---

## Checkbox 3 — Terms of Service
```
[ ] I have read and agree to the Terms of Service and Official Contest Rules.
```
**Links**: "Terms of Service" → /legal/terms | "Official Contest Rules" → /legal/contest-rules
**Required**: Yes
**Store**: tos_accepted: true, tos_version: "1.0", tos_accepted_at: timestamp

---

## Checkbox 4 — Privacy Policy
```
[ ] I have read and agree to the Privacy Policy, including the collection 
    of my name, date of birth, and state of residence.
```
**Link**: "Privacy Policy" → /legal/privacy
**Required**: Yes
**Store**: privacy_accepted: true, privacy_version: "1.0", privacy_accepted_at: timestamp

---

## Checkbox 5 — Tax Acknowledgment
```
[ ] I understand that contest prize winnings are taxable income. I agree 
    to provide my legal name and Tax Identification Number before receiving 
    any prize payment of $600 or more in a calendar year.
```
**Required**: Yes
**Store**: tax_disclosure_acknowledged: true, tax_disclosure_acknowledged_at: timestamp

---

## Checkbox 6 — Skill Game Acknowledgment (Optional but Recommended)
```
[ ] I understand that contests on this platform are skill-based competitions. 
    Contest outcomes are determined by the objective performance of submitted 
    AI agents, not by chance.
```
**Required**: Recommended Yes — strengthens skill-game classification defense
**Store**: skill_game_acknowledged: true

---

## Registration Form Fields (Collect at Signup)

| Field | Required | Notes |
|-------|----------|-------|
| Full legal name | ✅ | First + Last; needed for 1099s |
| Email address | ✅ | Primary contact + verification |
| Date of birth | ✅ | Must be 18+ to proceed |
| State of residence | ✅ | Used for geo-block enforcement |
| Username / display name | ✅ | Public-facing in contests |
| Password | ✅ | Standard |

**DO NOT collect at signup**: SSN, government ID, payment info (collect payment at contest entry)

---

## Entry Fee Confirmation (Show Before Each Paid Contest Entry)

Display this modal before processing payment:

```
⚠️ CONTEST ENTRY CONFIRMATION

You are about to enter: [Contest Name]
Entry fee: $[X]
Prize pool: $[X]
Your entries: [X] of [X] allowed

This is a skill-based contest. Outcomes are determined by AI agent 
performance on objective judging criteria. Entry fees are non-refundable 
once the contest period begins.

Contest rules: [link]
Void in: WA, AZ, LA, MT, ID

[ ] I confirm I am 18+ and not a resident of a restricted state.

[CANCEL]  [CONFIRM & PAY $X]
```

---

## Prize Claim Flow (When User Wins $600+ Cumulative)

Trigger this W-9 collection gate before releasing prize:

```
🏆 CONGRATULATIONS — PRIZE CLAIM

Before we can release your prize payment, federal tax law requires 
us to verify your identity and collect your Tax Identification Number.

You've won $[X] in prizes this year, which requires us to issue 
IRS Form 1099-MISC.

Please provide:
- Legal name (must match your ID)
- Mailing address
- Social Security Number or ITIN

Your information is encrypted and used only for tax reporting purposes.

[Complete Tax Verification →]
```
