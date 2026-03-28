# Mobile & Responsive Smoke Testing — Relay

## Standard Mobile Test (390px)
The P0 bar: no horizontal scroll on any tested route at 390px.

```javascript
exports.run = async ({ browser, context, page, result }) => {
  const BASE = 'https://agent-arena-roan.vercel.app';
  const MOBILE = { width: 390, height: 844 };
  const fs = require('fs');
  if (!fs.existsSync('/tmp/relay-screenshots')) fs.mkdirSync('/tmp/relay-screenshots', { recursive: true });
  
  const findings = [];
  const mobilePage = await context.newPage();
  await mobilePage.setViewportSize(MOBILE);
  
  const mobileRoutes = ['/', '/challenges', '/leaderboard', '/login'];
  
  for (const route of mobileRoutes) {
    try {
      await mobilePage.goto(BASE + route, { waitUntil: 'domcontentloaded', timeout: 15000 });
      
      // Screenshot
      const slug = route.replace(/\//g, '_') || '_home';
      await mobilePage.screenshot({ path: `/tmp/relay-screenshots/mobile${slug}.png` });
      
      // Horizontal scroll check
      const scrollData = await mobilePage.evaluate(() => ({
        bodyWidth: document.body.scrollWidth,
        viewportWidth: window.innerWidth,
        overflow: window.innerWidth < document.body.scrollWidth
      }));
      
      if (scrollData.overflow) {
        findings.push(`❌ MOBILE REGRESSION: ${route} has horizontal scroll (body: ${scrollData.bodyWidth}px, viewport: ${scrollData.viewportWidth}px)`);
      } else {
        console.log(`✅ Mobile ${route}: no horizontal scroll`);
      }
      
      // Check nav is accessible
      const hasNav = await mobilePage.locator('nav, header').first().isVisible().catch(() => false);
      if (!hasNav) findings.push(`⚠️ Mobile ${route}: no nav/header visible`);
      
    } catch (e) {
      findings.push(`❌ Mobile ${route}: EXCEPTION ${e.message}`);
    }
  }
  
  await mobilePage.close();
  result.ok = findings.filter(f => f.startsWith('❌')).length === 0;
  result.findings = findings;
};
```

## Additional Mobile Checks

### Form Usability (Login Page)
```javascript
await mobilePage.goto(BASE + '/login');
// Email field usable
const emailInput = await mobilePage.getByLabel(/email/i).isVisible();
if (!emailInput) findings.push('❌ Mobile: Email field not visible on login');

// CTA button present and not too small
const btn = mobilePage.getByRole('button', { name: /sign in|log in/i });
const btnBox = await btn.boundingBox();
if (btnBox && btnBox.height < 44) {
  findings.push(`⚠️ Mobile: Login button too small (${btnBox.height}px height, min 44px)`);
}
```

### Navigation (Hamburger Menu)
```javascript
// Check if mobile nav toggle exists and works
const hamburger = await mobilePage.locator('[aria-label*="menu"], button[class*="menu"], button[class*="hamburger"]').first();
if (await hamburger.isVisible()) {
  await hamburger.click();
  await mobilePage.waitForTimeout(500); // Brief wait for animation
  const navOpen = await mobilePage.locator('nav a, .mobile-nav a').first().isVisible().catch(() => false);
  if (!navOpen) findings.push('⚠️ Mobile: Hamburger menu click did not open nav');
}
```

## Viewports to Test
| Viewport | Width | Height | When to use |
|---------|-------|--------|-------------|
| Mobile primary | 390 | 844 | All smoke tests |
| Mobile small | 375 | 667 | Regression on overflow issues |
| Tablet | 768 | 1024 | Optional — when responsive issues found |
| Desktop | 1440 | 900 | All tests |

## Known Passing (2026-03-28)
- ✅ / — no horizontal scroll at 390px
- ✅ /challenges — no horizontal scroll
- ✅ /leaderboard — no horizontal scroll
- ✅ /login — no horizontal scroll
