# IMPLEMENTATION GUIDE — Disclosures for Maks
# What Goes Where and When

---

## Files in This Folder

| File | Purpose | Page/Location |
|------|---------|---------------|
| SIGNUP-CHECKBOXES.md | Registration form checkboxes + fields | /signup |
| TERMS-OF-SERVICE.md | Full ToS | /legal/terms |
| PRIVACY-POLICY.md | Full Privacy Policy | /legal/privacy |
| OFFICIAL-CONTEST-RULES.md | Contest rules template | /legal/contest-rules |
| RESPONSIBLE-GAMING-NOTICE.md | RG policy + footer text | /legal/responsible-gaming + footer |

---

## Before You Build — Replace All Placeholders

Search for `[` in each file and replace:
- `[Platform Name]` → actual product name
- `[Company Legal Name]` → Iowa LLC name (e.g., "Perlantir AI Studio LLC")
- `[Address]` / `[City, Iowa ZIP]` → Nick's business address
- `[DATE]` → launch date
- `[domain].com` → actual domain
- `[X]` → actual numbers (entry fees, prize amounts, judging weights)
- `[payment method]` → how prizes are paid (ACH, PayPal, etc.)
- `[email provider]` / `[hosting provider]` / `[KYC provider]` in Privacy Policy

---

## Route Structure to Create

```
/legal/terms                → TERMS-OF-SERVICE
/legal/privacy              → PRIVACY-POLICY  
/legal/contest-rules        → OFFICIAL-CONTEST-RULES (per contest or template)
/legal/responsible-gaming   → RESPONSIBLE-GAMING-NOTICE policy section
```

All legal pages must be:
- Publicly accessible (no login required)
- Linkable directly (no JavaScript-only rendering)
- Printable / plain text readable
- Dated with "Last Updated" at top

---

## Registration Page (/signup)

### Fields to Collect (in order)
1. Full legal name (first + last)
2. Email address
3. Date of birth (MM/DD/YYYY — validate 18+, block if under)
4. State of residence (dropdown — auto-reject WA, AZ, LA, MT, ID)
5. Username
6. Password

### Checkboxes (all required, in order)
1. Age 18+ confirmation
2. Not from restricted state confirmation
3. Terms of Service + Contest Rules agreement (with links)
4. Privacy Policy agreement (with link)
5. Tax acknowledgment
6. Skill game acknowledgment (recommended)

### Validation Rules
- DOB: If calculated age < 18 → block with message: "You must be 18 or older to participate."
- State: If WA, AZ, LA, MT, or ID → block with message: "This service is not available in your state."
- All checkboxes: Must be individually checked. No "select all."

### Data to Store on Account Creation
```
{
  full_name: string,
  email: string,
  date_of_birth: date,
  state_of_residence: string,
  username: string,
  
  // Compliance timestamps
  age_verified: boolean,
  age_verified_at: timestamp,
  jurisdiction_confirmed: boolean,
  jurisdiction_confirmed_at: timestamp,
  tos_accepted: boolean,
  tos_version: "1.0",
  tos_accepted_at: timestamp,
  privacy_accepted: boolean,
  privacy_version: "1.0",
  privacy_accepted_at: timestamp,
  tax_disclosure_acknowledged: boolean,
  tax_disclosure_acknowledged_at: timestamp,
  skill_game_acknowledged: boolean,
  
  // Tax tracking
  annual_prize_total: number (default 0),
  w9_collected: boolean (default false),
  w9_collected_at: timestamp (nullable)
}
```

---

## Contest Entry Flow

### Before Each Paid Entry — Show Confirmation Modal
Contents: (see SIGNUP-CHECKBOXES.md → "Entry Fee Confirmation" section)
- Contest name
- Entry fee amount
- Prize pool
- Non-refund notice
- Restricted states reminder
- Confirmation checkbox
- Cancel / Confirm buttons

### Store on Each Entry
```
{
  user_id,
  contest_id,
  entry_fee_paid: number,
  confirmed_at: timestamp,
  payment_id: string (Stripe),
  ip_address: string (for geo audit)
}
```

---

## Prize Payment Flow

### Track Annual Prize Total
- Every time a user wins a prize, add to `annual_prize_total` for that calendar year
- Reset January 1 each year (keep historical records)

### W-9 Gate (Triggers at $600 Cumulative)
When `annual_prize_total >= 600` AND `w9_collected = false`:
- Show W-9 collection modal (see SIGNUP-CHECKBOXES.md → "Prize Claim Flow")
- Collect: legal name, mailing address, SSN/ITIN
- Encrypt and store SSN — do NOT store in plaintext
- Set `w9_collected = true`, `w9_collected_at = now()`
- Do NOT release prize until W-9 complete

### 1099-MISC Issuance (January of Following Year)
- Pull all users where `annual_prize_total >= 600` for prior year
- Issue 1099-MISC by January 31
- File with IRS electronically by March 31
- Use Yearli, Track1099, or similar service for bulk filing

---

## Footer (Every Contest / Payment Page)

```html
<footer-legal>
  [Platform Name] contests are skill-based competitions, not gambling. 
  Must be 18+ | Not available in WA, AZ, LA, MT, ID
  If you have concerns about competitive gaming: 
  <a href="tel:18005224700">1-800-522-4700</a> (NCPG) | 
  Iowa: <a href="tel:18002387633">1-800-BETSOFF</a>
  <br/>
  <a href="/legal/terms">Terms</a> | 
  <a href="/legal/privacy">Privacy</a> | 
  <a href="/legal/contest-rules">Contest Rules</a> | 
  <a href="/legal/responsible-gaming">Responsible Gaming</a>
</footer-legal>
```

---

## Cloudflare Geo-Block (Engineering)

Block these states at the edge:
```
WA = Washington
AZ = Arizona  
LA = Louisiana
MT = Montana
ID = Idaho
```

Block page message:
```
This service is not available in your state.
[Platform Name] skill contests are void where prohibited by law.
Questions? Contact support@[domain].com
```

Also block these countries entirely (OFAC + safety):
- Cuba (CU), Iran (IR), North Korea (KP), Syria (SY), Russia (RU)

---

## Launch Checklist

- [ ] All `[placeholders]` replaced in all 5 documents
- [ ] All legal pages live at /legal/* before first user
- [ ] Registration form collects all required fields
- [ ] All 6 checkboxes present and individually required
- [ ] Age validation (< 18 blocked)
- [ ] State validation (WA/AZ/LA/MT/ID blocked)
- [ ] Cloudflare geo-block active for 5 states
- [ ] `annual_prize_total` field in user model
- [ ] W-9 gate built (activates at $600)
- [ ] Contest entry confirmation modal
- [ ] Footer with RG notice on contest pages
- [ ] Support email address working
- [ ] /legal/responsible-gaming page live

---

*Documents prepared by Counsel (⚖️). Questions → @TheGeneralCounselBot*
