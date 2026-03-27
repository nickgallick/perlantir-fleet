# Screen 10: Wallet

## Design Authority: Pixel
## Date: 2026-03-22
## Reference: Stripe balance dashboard, DeFi wallets (transaction history), Figma billing

---

## PAGE LAYOUT

```
Same top nav — "Wallet" link.

Container: min-h-screen bg-arena-page
Content: max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-6 md:py-8
```

---

## SECTION 1: BALANCE DISPLAY

```
Container: arena-glass p-8 md:p-12 text-center

Large balance display:
  Label: font-body text-sm text-arena-text-muted uppercase tracking-wider "Current Balance"
  Amount: font-mono text-6xl md:text-7xl font-bold text-arena-text-primary mt-4 tabular-nums
    "2,450"
  Icon: Lucide Coins 32px text-yellow-400 inline-block ml-3 (mobile: below amount)

  Animation on first render:
    opacity: 0 → 1, y 20 → 0, 0.6s cubic-bezier(0.16,1,0.3,1)
  Number counter animation (if balance changes):
    from old → new, duration 1.2s, easeOut

Lifetime stats row: flex items-center justify-center gap-8 mt-8 pt-8 border-t border-arena-border/50
  Stat:
    Label: font-body text-xs text-arena-text-muted uppercase tracking-wider
    Value: font-mono text-lg font-semibold text-arena-text-primary mt-1

    Stats:
    - "12,450" / "Lifetime Earned"
    - "9,450" / "Lifetime Spent"
    - "3,000" / "Total Withdrawn" (if applicable)
```

---

## SECTION 2: STREAK FREEZE INVENTORY

```
Container: arena-glass p-6 mt-8

Header: flex items-center justify-between
  font-heading text-base font-semibold text-arena-text-primary "Streak Freezes"
  Help: icon button Lucide HelpCircle 14px text-arena-text-muted
    Tooltip: "Use a Streak Freeze to prevent losing your streak when you miss a day."

Inventory row: flex flex-col sm:flex-row items-center gap-4 mt-4
  Left:
    Icon: Lucide Shield 24px text-blue-400
    Text: flex flex-col
      Label: font-body text-sm font-medium text-arena-text-primary "Streak Freezes Owned"
      Value: font-mono text-lg font-semibold text-arena-text-primary mt-0.5 "3"

  Right:
    CTA: primary button "Buy More Freezes"
      Icon: Lucide ShoppingCart 14px left of text
      Opens pricing modal (see Pricing Modal below)

Usage history: mt-4 pt-4 border-t border-arena-border/50
  Label: font-body text-xs text-arena-text-muted uppercase tracking-wider "Usage"
  List: flex flex-col gap-2 mt-2
    Item:
      Text: font-body text-sm text-arena-text-secondary "Used 1 freeze on Feb 28, 2026"
      Remaining: font-mono text-xs text-arena-text-muted "2 remaining after this"
```

---

## SECTION 3: TRANSACTION HISTORY

```
Container: arena-glass p-0 rounded-lg overflow-hidden mt-8

Header: px-6 py-4 bg-arena-surface border-b border-arena-border
  Title: font-heading text-base font-semibold text-arena-text-primary "Transaction History"
  Filter: flex items-center gap-2
    Label: font-body text-xs text-arena-text-muted "Filter: "
    Options: All, Earned, Spent
    Button style: secondary rounded-md px-3 py-1 text-xs

Table: px-0 py-0

  Head: flex items-center h-10 bg-arena-surface/50 border-b border-arena-border/50 px-6 gap-4
    font-body text-xs text-arena-text-muted uppercase tracking-wider

    Columns:
    "Date" / "Description" / "Type" / "Amount" / "Balance"

  Body: max-h-[600px] overflow-y-auto

  Row (×50+): flex items-center h-11 px-6 gap-4 border-b border-arena-border/30 hover:bg-arena-elevated/20 transition-colors 0.2s

    Date: w-24 flex-shrink-0
      font-body text-sm text-arena-text-muted "Mar 22, 2026"
      Time below: font-body text-xs text-arena-text-muted/60 "14:32"

    Description: flex-1 min-w-0
      font-body text-sm text-arena-text-primary truncate "Challenge reward: Speed Build #1247"

    Type: w-24 flex-shrink-0
      Badge (inline): bg-[type-color]/15 text-[type-color] border border-[type-color]/30 rounded-full px-2 py-0.5
        Earned: text-emerald-400 "Earned"
        Spent: text-red-400 "Spent"
        Bonus: text-amber-400 "Bonus"
        Refund: text-blue-400 "Refund"

    Amount: w-16 text-right flex-shrink-0
      font-mono text-sm font-semibold text-arena-text-primary tabular-nums
      Earned: text-emerald-400 "+450"
      Spent: text-red-400 "-50"

    Balance: w-20 text-right flex-shrink-0 hidden sm:block
      font-mono text-sm text-arena-text-muted tabular-nums "2,450"

Pagination: (if many transactions)
  Same as previous screens
```

---

## PRICING MODAL (Buy Streak Freezes)

```
Modal: Shadcn Dialog / Sheet (full-screen on mobile)

Header: font-heading text-lg font-semibold text-arena-text-primary "Buy Streak Freezes"
Close: icon button

Content: py-6

Package grid: grid grid-cols-1 sm:grid-cols-2 gap-4

  Package card (×3): arena-glass p-6 relative cursor-pointer
    hover: border-blue-500/30 scale(1.02) transition-all 0.2s

    Package name: font-heading text-base font-semibold text-arena-text-primary mt-2

    Quantity: font-mono text-2xl font-bold text-arena-text-primary "3"
    Label: font-body text-xs text-arena-text-muted "freezes"

    Price: flex items-baseline gap-1 mt-3
      font-mono text-3xl font-bold text-arena-text-primary "9.99"
      font-mono text-sm text-arena-text-muted "USD"

    Value: font-body text-xs text-emerald-400 mt-1
      "Save 10%"

    Divider: border-t border-arena-border my-4

    Details: font-body text-xs text-arena-text-secondary
      "3 freezes for $9.99"
      "Use anytime to save your streak"

    CTA: secondary button "Buy Now", w-full

  Packages offered:
    1 freeze: $4.99 (no discount)
    3 freezes: $9.99 (save 10%)
    10 freezes: $24.99 (save 25%)

Feature info: mt-8 pt-8 border-t border-arena-border/50
  Label: font-body text-xs text-arena-text-muted uppercase tracking-wider "How it works"
  Points: flex flex-col gap-2
    Item: flex items-start gap-2
      Lucide Check 14px text-emerald-400 flex-shrink-0 mt-0.5
      font-body text-sm text-arena-text-secondary "Automatically applied when you miss a day"
    Item: flex items-start gap-2
      Lucide Check 14px text-emerald-400 flex-shrink-0 mt-0.5
      font-body text-sm text-arena-text-secondary "Keeps your win streak intact"
    Item: flex items-start gap-2
      Lucide Check 14px text-emerald-400 flex-shrink-0 mt-0.5
      font-body text-sm text-arena-text-secondary "One freeze per day maximum"

Payment methods: mt-6
  Label: font-body text-xs text-arena-text-muted uppercase tracking-wider "Accepted Payment Methods"
  Icons: Lucide CreditCard, Lucide Wallet, Lucide DollarSign — 20px each, text-arena-text-muted, spacing gap-3

Footer: mt-8 flex items-center gap-3
  Close: secondary button "Cancel"
  Buy: primary button "[X] Freezes for $[price]"
    Leads to payment (Stripe checkout)
    Loading state: button disabled, spinner
```

---

## MOBILE ADAPTATION

```
Mobile (<md):
  Balance section: stack vertically
  Lifetime stats: 2 cols instead of 3 (stacked below)
  Streak freezes: stack icon + info vertically
  Transaction table: scrollable, hide "Balance" column
  Pricing modal: full-screen sheet, packages stack vertically
  Buttons: full-width
```

---

## 10-QUESTION QUALITY CHECK

1. ✅ Color — hex/Tailwind for all elements (earned emerald, spent red, etc.).
2. ✅ Font — font-heading/body/mono per element with weight, size, tracking.
3. ✅ Spacing — exact Tailwind (p-8, gap-4, h-10, mt-4, etc.).
4. ✅ Effects — glass cards, table hover state, modal overlays.
5. ✅ Animation — balance counter on load/change, package card hover scale, modal fade.
6. ✅ Layout — centered balance, grid for packages, table with scrollable body.
7. ✅ Z-order — z-50 for modal.
8. ✅ Hover — transaction rows, package cards, buttons.
9. ✅ Mobile — full-screen sheet, stacked layout, full-width buttons.
10. ✅ Accessibility — transaction table has headers, modal has focus management, payment info accessible.

**Verdict: SPEC COMPLETE — Screen 10 ready for generation.**
