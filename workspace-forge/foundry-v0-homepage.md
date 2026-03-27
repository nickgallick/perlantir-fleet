# FOUNDRY — v0 Prompt: Homepage
**Prepared by:** Forge 🔥
**Tool:** v0.dev (Vercel)
**Page:** Homepage (`/`)
**Stack:** Next.js 14 App Router + Tailwind CSS + shadcn/ui

---

## HOW TO USE THIS

1. Go to **v0.dev**
2. Paste the prompt below exactly as written
3. Review the output — iterate with the follow-up prompts at the bottom if needed
4. Export as Next.js component → drop into `src/app/page.tsx`

---

## MAIN PROMPT

Paste this into v0:

---

Build a homepage for **Foundry** — a blockchain-native crowdfunding platform. Kickstarter meets smart contract escrow. The core promise: creators prove it to earn it, backers are never stuck.

**Design language:**
- Dark theme: background `#0a0a0a`, surface cards `#111111`, borders `#1f1f1f`
- Primary accent: electric blue `#3b82f6`
- Secondary accent: emerald green `#10b981` (for verified/success states)
- Warning/caution: amber `#f59e0b`
- Text: primary `#f9fafb`, secondary `#9ca3af`, muted `#4b5563`
- Font: Inter (system font stack fallback)
- Rounded corners: `rounded-xl` for cards, `rounded-lg` for buttons
- Subtle gradients allowed on hero only
- No loud crypto aesthetics — professional, trustworthy, modern

**Tech stack:** Next.js 14 App Router, Tailwind CSS, shadcn/ui components. Use TypeScript. Export as a single `page.tsx` file with subcomponents defined in the same file.

---

### Section 1: Navigation Bar

Sticky top navigation. Dark background with subtle bottom border `border-b border-[#1f1f1f]`.

Left: Logo — "FOUNDRY" in bold, white, slightly tracked. Add a small forge/anvil icon or abstract geometric mark to the left of the wordmark (SVG inline, simple, ~20px).

Center: Nav links — "Discover", "Marketplace", "How It Works", "For Creators". Medium weight, `text-sm`, color `#9ca3af`, hover `#f9fafb`. 

Right: Two buttons —
- "Connect Wallet" — outlined button, `border border-[#1f1f1f]` background, `text-sm`
- "Sign In" — ghost/text button

On mobile: hamburger menu, links collapse into a drawer.

---

### Section 2: Hero

Full-width hero section. Vertically centered. Generous padding top/bottom (at least 120px each).

**Background:** Subtle radial gradient from `#0f172a` at center fading to `#0a0a0a`. Add a faint grid pattern overlay (CSS grid lines, very low opacity ~3%). Optional: one large blurred blue glow circle in the upper-right background, very subtle.

**Content (centered):**

Eyebrow tag above headline: small pill badge — "Built on Base · Secured by Smart Contracts" — dark pill, blue text, small border.

**Headline (large, ~64px on desktop, ~40px mobile):**
"The crowdfunding platform where creators prove it to earn it."

**Subheadline (~20px, muted color, max-width 560px, centered):**
"Milestone-gated escrow. AI-verified progress. Sell your reward claim anytime. Crowdfunding that actually works."

**CTA buttons (side by side, centered):**
- Primary: "Browse Campaigns" — filled blue `bg-blue-600 hover:bg-blue-500`, white text, `px-6 py-3 rounded-lg`
- Secondary: "Launch a Campaign" — outlined, `border border-blue-600 text-blue-400 hover:bg-blue-950`, `px-6 py-3 rounded-lg`

**Below CTAs:** Small trust line in muted text — "🔒 Funds locked in audited smart contracts · Built on Base"

---

### Section 3: Stats Strip

Full-width dark strip below hero. `bg-[#111111] border-y border-[#1f1f1f]`. Padding `py-8`.

Three stats centered, divided by vertical separators:

| Stat | Label |
|------|-------|
| $2.4M+ | Total Funds Protected |
| 48 | Campaigns Funded |
| 3,200+ | Backers |

Each stat: large bold number in white, label in muted text below. On mobile: stack vertically.

---

### Section 4: How It Works

Section heading: "How Foundry Works" — centered, white, `text-3xl font-bold`. Subtext below: "A crowdfunding platform with real accountability — for creators and backers." Muted color.

**4 step cards in a horizontal row** (2×2 grid on mobile):

Each card: `bg-[#111111] border border-[#1f1f1f] rounded-xl p-6`. Icon top-left (use lucide-react icons), step number top-right in muted text.

**Card 1 — Creator Stakes**
Icon: `Shield` (blue)
Title: "Creators stake collateral"
Body: "Every creator deposits a performance bond before launch. If they abandon the project, backers get refunded from the stake."

**Card 2 — Milestone Gating**
Icon: `GitBranch` (blue)
Title: "Funds release milestone by milestone"
Body: "Money never goes upfront. Creators earn each tranche by hitting verifiable milestones. AI reviews every submission."

**Card 3 — AI Review**
Icon: `Sparkles` (blue)
Title: "AI vets every campaign"
Body: "Before going live, every campaign gets an AI feasibility review. Backers see the score. No more mystery projects."

**Card 4 — Backer Exit**
Icon: `ArrowLeftRight` (emerald)
Title: "Backers are never stuck"
Body: "Changed your mind? Take a platform refund or sell your reward claim on the marketplace. You're always in control."

---

### Section 5: Featured Campaigns

Section heading: "Live Campaigns" — left-aligned on desktop. "See All" link right-aligned, blue text. 

**3 campaign cards in a horizontal row** (stacks on mobile). Each card:

```
bg-[#111111] border border-[#1f1f1f] rounded-xl overflow-hidden
```

**Card structure:**
- Top: placeholder image area `h-48 bg-[#1a1a1a]` with category badge overlay (top-left, small pill: e.g. "Tech", "Games", "Creative")
- Body padding `p-5`
- Campaign title: white, `font-semibold text-lg`
- Creator name: muted, `text-sm`
- AI Score badge: small pill — "AI Score: 87/100" — blue background, white text, `text-xs`
- Funding progress bar: full width, `h-2 rounded-full bg-[#1f1f1f]` with blue fill. Below bar: "$94,500 raised of $120,000 · 28 days left" in muted text
- Milestone progress: "✓ 2 of 4 milestones complete" — emerald text, `text-sm`
- Footer: Refund protection badge on left — "50% refund protection" in amber text, small shield icon. Tier price on right — "From $49"

**Mock campaigns:**

1. **Luminary — Smart Home Lighting System**
Creator: Aria Chen · Category: Tech
AI Score: 87 · $94,500 / $120,000 · 28 days left
Milestones: 2/4 verified · Refund: 50% · From $49

2. **Echoes — Ambient Sound Machine**
Creator: Marcus Webb · Category: Creative  
AI Score: 79 · $31,200 / $75,000 · 44 days left
Milestones: 1/3 verified · Refund: 40% · From $89

3. **Strata — Modular Backpack System**
Creator: Priya Nair · Category: Physical
AI Score: 92 · $187,000 / $200,000 · 6 days left
Milestones: 3/5 verified · Refund: 60% · From $129

---

### Section 6: For Creators

Two-column layout. Left: text. Right: visual (can be a styled card or illustration mockup).

**Left side:**
Eyebrow: "FOR CREATORS" — small caps, blue, tracked
Headline: "Launch with credibility. Build with accountability." — white, `text-3xl font-bold`
Body: "Foundry campaigns are AI-reviewed before launch. Backers see your feasibility score. Milestone-gated funding means you never have to ask for trust — you earn it." — muted text
CTA: "Start Your Campaign →" — blue text link with arrow

**Right side:** A stylized card mockup showing a creator dashboard snippet — milestone checklist with 2 checkmarks and 1 pending item, funds released counter "$45,000 released of $120,000". Dark card, subtle inner glow border. This can be a styled `div` — no image needed.

---

### Section 7: Footer

Dark footer `bg-[#080808] border-t border-[#1f1f1f]`. Padding `py-12`.

**Four columns:**

**Col 1:** Foundry logo + tagline "Crowdfunding with accountability." + small text "Built on Base · Powered by Perlantir AI Studio"

**Col 2:** Platform — Discover, Marketplace, How It Works, For Creators

**Col 3:** Company — About, Blog, Careers, Press

**Col 4:** Legal — Terms of Service, Privacy Policy, Cookie Policy

**Bottom bar:** horizontal line, then centered text: "© 2026 Perlantir AI Studio. All rights reserved." and on the right: "AI review is a quality filter, not a guarantee of delivery."

---

### Responsive Rules
- All sections: full-width on mobile, max-width `1280px` centered on desktop
- Nav: hamburger on mobile below `768px`
- Hero headline: `text-4xl` on mobile, `text-6xl` on desktop
- How It Works: `grid-cols-1 sm:grid-cols-2 lg:grid-cols-4`
- Campaigns: `grid-cols-1 md:grid-cols-3`
- For Creators: `flex-col lg:flex-row`
- Stats strip: `flex-col sm:flex-row`

---

### Additional Notes
- Use `lucide-react` for all icons
- shadcn/ui `Button`, `Badge`, `Card` components where appropriate
- No external image dependencies — use CSS placeholder blocks for images
- All links use Next.js `<Link href="...">` 
- Export as a single TypeScript file

---

## ITERATION PROMPTS

After v0 generates the first version, use these to refine:

**If the dark theme is too flat:**
> "Add more depth to the cards — try a very subtle inner highlight on the top edge of each card (`border-t border-white/5`) and a slight box shadow. The background should feel rich, not flat black."

**If the hero feels empty:**
> "Add more visual interest to the hero background. Try a large radial gradient spotlight effect behind the headline, and add subtle animated particles or a slow-moving mesh gradient. Keep it tasteful — not crypto-flashy."

**If the campaign cards look generic:**
> "Refine the campaign cards. Add a thin gradient overlay at the bottom of the image area fading to the card background. Make the AI score badge more prominent — pill shape with a small sparkle icon. The funding progress bar fill should have a slight gradient from blue to cyan."

**If spacing feels cramped:**
> "Increase section padding. Hero needs at least `py-32`, section gaps should be `gap-24` between major sections. Cards need breathing room — increase inner padding to `p-6`."

**If the CTA section needs more energy:**
> "Add a full-width CTA banner section before the footer. Dark blue gradient background, centered headline: 'Ready to back something real?' with subtext 'Join 3,200+ backers funding the next generation of products.' Two buttons: 'Browse Campaigns' (white filled) and 'Launch a Campaign' (outlined white). Generous padding."

**To check mobile:**
> "Show me the mobile layout of this homepage at 375px width. Focus on: nav collapse, hero text sizing, how the campaign cards stack, and the stats strip."

---

## WHAT TO EVALUATE IN THE OUTPUT

Before moving to the next page, check these:

- [ ] Dark theme feels premium, not cheap
- [ ] "Kickstarter meets Coinbase" vibe — trustworthy, not crypto-bro
- [ ] Campaign cards have the right information density
- [ ] How It Works section actually explains the product clearly
- [ ] Footer legal disclaimer is present (required)
- [ ] Refund protection language on campaign cards uses "refund protection" not "returns" or "yield"
- [ ] Mobile layout stacks cleanly
- [ ] No investment/financial language anywhere on the page

If the output passes these checks → move to the Campaign Discovery page prompt.

---

*Prepared by Forge 🔥 — Perlantir AI Studio*
*Next prompt doc: foundry-v0-campaigns.md (Campaign Discovery page)*
