# SKILL: ADA & Web Accessibility Compliance
**Version:** 1.0.0 | **Domain:** ADA Title III, WCAG 2.1, Accessibility Litigation

---

## ADA Title III — Website Application
**Authority:** 42 U.S.C. §§ 12181-12189; 28 C.F.R. Part 36

### The Legal Landscape
- *Robles v. Domino's Pizza LLC*, 913 F.3d 898 (9th Cir. 2019): websites of businesses with physical locations must be accessible under ADA
- DOJ Statement (2022): websites and mobile apps are "places of public accommodation" subject to ADA
- DOJ Final Rule (2024): web accessibility regulations specifically for state/local government websites (Title II); Title III business regulations still pending but enforcement is active

**Circuit split on online-only businesses:**
- 11th Circuit: websites must have "nexus" to a physical location to be covered (*Gil v. Winn-Dixie*, 993 F.3d 1266 (11th Cir. 2021))
- 1st, 2nd, 7th Circuits: websites are places of public accommodation regardless of physical nexus
- **Practical reality:** Even if you win legally in a friendly circuit, the cost to defend is $30-100K minimum

### The ADA Troll Problem
- 2023: 4,605 ADA web accessibility lawsuits filed in federal court (up 300% from 2019)
- Plaintiff firms (Griffin Disability Law, Center for Disability Access): file hundreds of suits per year
- Most target: e-commerce sites, financial platforms, any site where transactions occur
- Settlement range: $10,000-$50,000 + legal fees + remediation costs
- **Prevention is dramatically cheaper than defense**

---

## WCAG 2.1 Level AA — The Standard
**Authority:** W3C Web Content Accessibility Guidelines 2.1 (June 5, 2018)
**DOJ standard:** Courts reference WCAG 2.1 AA as the benchmark for ADA compliance

### The Four Principles (POUR)

**Perceivable — Users can perceive all content:**
- All non-text content has text alternatives (alt text for images, captions for videos)
- Content can be presented in different ways without losing meaning
- Minimum color contrast ratio: 4.5:1 for normal text, 3:1 for large text (18pt+)
- Audio content has transcripts or captions
- Users can control timing (pause, stop, hide auto-playing content)

**Operable — Users can operate the interface:**
- All functionality available from a keyboard (no mouse required)
- No content causes seizures (nothing flashes more than 3 times per second)
- Users have enough time to read and use content (adjustable timeouts)
- Users can navigate, find content, and determine where they are

**Understandable — Users can understand content:**
- Text is readable and understandable (reading level, unusual words explained)
- Pages operate in predictable ways
- Users are helped to avoid and correct mistakes (clear error messages)
- Form inputs have labels; errors described specifically

**Robust — Content can be interpreted by assistive technologies:**
- HTML is valid and well-formed
- Name, role, value of all UI components available to assistive technologies (ARIA labels)
- Status messages programmatically determinable without focus

---

## Critical Accessibility Requirements for Financial Platforms

### Transaction Forms (Highest Risk — Most Often Litigated)

**Contest entry form:**
```html
<!-- BAD: No label association -->
<input type="number" placeholder="Entry fee" />

<!-- GOOD: Proper label + ARIA -->
<label for="entryFee">Entry Fee (USDC)</label>
<input type="number" id="entryFee" name="entryFee" 
       aria-describedby="entryFeeHelp"
       aria-required="true" />
<div id="entryFeeHelp">Minimum entry: 10 USDC</div>
```

**Error messages (specific, not just red borders):**
```html
<!-- BAD: Color-only error indicator -->
<input style="border: 2px solid red" />

<!-- GOOD: Text + ARIA + color -->
<input aria-invalid="true" aria-describedby="errorMsg" />
<div id="errorMsg" role="alert">
  Error: Insufficient USDC balance. Your balance: 5 USDC. Required: 10 USDC.
</div>
```

### Real-Time Data (Leaderboards, Prices, Scores)
- Leaderboard updates must be announced to screen readers: use `aria-live="polite"` for non-critical updates, `aria-live="assertive"` for important alerts
- Contest timer: accessible countdown with screen reader announcements at key intervals
- Price charts: provide data table alternative alongside the visual chart

### Wallet Connection Flow
- MetaMask popup instructions: provide text instructions for users who cannot see the popup
- Transaction confirmation: describe the transaction in plain text, not just as a graphic
- Loading states: announce to screen readers ("Connecting to wallet..." → "Wallet connected")

---

## Practical Compliance Steps

### Step 1: Automated Testing (Free, Do This First)
- **axe DevTools** (browser extension, free): run on every page, fix all violations
- **Lighthouse** (Chrome DevTools → Lighthouse tab → Accessibility): automated score + specific issues
- **WAVE** (wave.webaim.org): visual overlay of accessibility issues

### Step 2: Manual Testing
- Navigate your entire platform using ONLY the keyboard (Tab, Enter, Space, Arrow keys)
- Use a screen reader: NVDA (Windows, free), VoiceOver (Mac/iOS, built-in), JAWS (Windows, paid)
- Test at 200% browser zoom — content must still be accessible
- Test color contrast: use WebAIM Contrast Checker (webaim.org/resources/contrastchecker/)

### Step 3: User Testing (Before Launch)
- Test with actual users who have disabilities: deaf, blind, motor impairments
- Services: Fable (fable.co), UserTesting (usertesting.com accessibility panel)
- Cost: $500-$2,000 for a basic accessibility test session with real users

### Step 4: Accessibility Statement
- Publish at: /accessibility on your website
- Include: your WCAG conformance level, date last reviewed, known issues, contact for accessibility feedback
- Update regularly

### Step 5: Remediation Priority Order
1. **Critical:** Cannot complete a transaction (entry, payout, wallet connection) → fix immediately
2. **High:** Cannot navigate to key sections of the platform → fix before launch
3. **Medium:** WCAG AA violations that impede usability but don't block transactions → fix within 30 days of launch
4. **Low:** WCAG AA violations that affect comfort but not function → fix in next sprint

---

## Cost of Building Accessible vs. Retrofitting

| Approach | Cost |
|---|---|
| Build accessible from start | +10-15% development time |
| Retrofit after launch | 5-10x the cost of building it right |
| ADA lawsuit settlement | $10,000-$50,000 + $30,000-$100,000 legal fees |
| ADA lawsuit defense through trial | $200,000-$500,000 |

**Building accessible from Day 1 is the cheapest approach by far.**

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
