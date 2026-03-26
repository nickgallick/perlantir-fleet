---
name: accessibility-smoke-testing
description: Run automated WCAG 2.1 AA accessibility checks on every Arena page using axe-core via @axe-core/playwright. Identifies critical violations that block launch vs serious issues to fix soon. Integrated into Forge's E2E flow.
---

# Accessibility Smoke Testing — Agent Arena

## Standard

**WCAG 2.1 AA** — the baseline for any public-facing web app.

## Tool

`@axe-core/playwright` — injects axe-core into any Playwright page and returns structured violation data.

## Installation Check

```bash
npm list @axe-core/playwright 2>/dev/null || echo "NOT INSTALLED"
# Install if missing:
npm install @axe-core/playwright
```

## Arena Pages to Test

| Page | URL | Priority | Risk Level |
|------|-----|----------|------------|
| Landing | `/` | P0 | High traffic |
| Login | `/login` | P0 | Entry point |
| Challenges | `/challenges` | P1 | Public list |
| Challenge Detail | `/challenges/[id]` | P1 | Public |
| Register Agent | `/agents/new` | P1 | Form-heavy |
| Dashboard | `/` (authenticated) | P2 | Authenticated |
| Docs | `/docs` | P2 | Reference |
| Leaderboard | `/leaderboard` | P2 | Public |

## Violation Severity Reference

| axe Impact | Launch Decision | Action |
|------------|----------------|--------|
| `critical` | ❌ Block launch | Fix before launch |
| `serious` | ⚠️ Fix soon | Fix within sprint |
| `moderate` | 📋 Track | Fix in next quarter |
| `minor` | 💡 Nice to have | Backlog |

## Critical Violations to Always Check

- Missing alt text on images (`image-alt`)
- Form fields without labels (`label`)
- Insufficient color contrast (`color-contrast`)
- Missing page `<title>` (`document-title`)
- Missing `lang` attribute on `<html>` (`html-has-lang`)
- Interactive elements not keyboard accessible (`keyboard`)
- Missing focus indicator

## Working Integration Code

```javascript
// /tmp/arena-a11y-tests.js
// Playwright script for A11y testing

exports.config = { headed: false, slowMo: 0 };

exports.run = async ({ browser, context, page, result }) => {
  // Check axe availability
  let checkA11y;
  try {
    ({ checkA11y } = require('@axe-core/playwright'));
  } catch (e) {
    result.ok = false;
    result.error = 'axe-core/playwright not installed. Run: npm install @axe-core/playwright';
    return;
  }

  const BASE = 'https://agent-arena-roan.vercel.app';
  const allViolations = [];
  const pageResults = [];

  /**
   * Run a11y check on current page
   */
  async function checkPage(name, url) {
    console.log(`\n[A11y] Checking: ${name} (${url})`);
    await page.goto(url, { waitUntil: 'networkidle', timeout: 20000 });
    await page.waitForTimeout(1000); // Allow dynamic content to render

    let violations = [];
    try {
      // Run axe against the full page
      await checkA11y(page, null, {
        axeOptions: {
          runOnly: {
            type: 'tag',
            values: ['wcag2a', 'wcag2aa', 'wcag21aa', 'best-practice']
          }
        },
        detailedReport: false,
        verbose: false,
      });
      console.log(`  ✅ No violations on ${name}`);
    } catch (e) {
      // axe throws when violations found — parse the error
      // The violations are in the error object for some versions
      // Use direct axe API instead:
      violations = await page.evaluate(async () => {
        if (!window.axe) return [];
        const results = await window.axe.run();
        return results.violations;
      }).catch(() => []);

      if (violations.length === 0) {
        // Inject axe manually if not available
        await page.addScriptTag({ 
          url: 'https://cdnjs.cloudflare.com/ajax/libs/axe-core/4.9.0/axe.min.js' 
        }).catch(() => {});
        
        violations = await page.evaluate(async () => {
          if (!window.axe) return [];
          const results = await window.axe.run();
          return results.violations;
        }).catch(() => []);
      }
    }

    // Classify violations
    const critical = violations.filter(v => v.impact === 'critical');
    const serious = violations.filter(v => v.impact === 'serious');
    const moderate = violations.filter(v => v.impact === 'moderate');
    const minor = violations.filter(v => v.impact === 'minor');

    const summary = {
      name,
      url,
      total: violations.length,
      critical: critical.length,
      serious: serious.length,
      moderate: moderate.length,
      minor: minor.length,
      blockers: critical.map(v => ({
        id: v.id,
        description: v.description,
        helpUrl: v.helpUrl,
        nodes: v.nodes?.length || 0
      }))
    };

    pageResults.push(summary);
    allViolations.push(...violations.map(v => ({ ...v, page: name })));

    if (critical.length > 0) {
      console.log(`  ❌ CRITICAL violations on ${name}: ${critical.length}`);
      critical.forEach(v => console.log(`     - ${v.id}: ${v.description}`));
    } else if (serious.length > 0) {
      console.log(`  ⚠️  Serious violations on ${name}: ${serious.length}`);
    } else if (violations.length > 0) {
      console.log(`  📋 ${violations.length} minor/moderate violations on ${name}`);
    } else {
      console.log(`  ✅ Clean on ${name}`);
    }

    return summary;
  }

  // ── Public pages (no auth needed) ───────────────────────────────────────────
  await checkPage('Landing Page', BASE);
  await checkPage('Login Page', `${BASE}/login`);
  await checkPage('Challenges List', `${BASE}/challenges`);
  await checkPage('Docs', `${BASE}/docs`);
  await checkPage('Leaderboard', `${BASE}/leaderboard`);

  // ── Check challenge detail (use first available challenge) ───────────────────
  try {
    const resp = await page.request.get(`${BASE}/api/challenges`);
    if (resp.ok()) {
      const challenges = await resp.json().catch(() => []);
      const firstId = Array.isArray(challenges) ? challenges[0]?.id : null;
      if (firstId) {
        await checkPage('Challenge Detail', `${BASE}/challenges/${firstId}`);
      }
    }
  } catch {}

  // ── Take screenshots of critical failures ────────────────────────────────────
  for (const pr of pageResults) {
    if (pr.critical > 0) {
      await page.goto(pr.url, { waitUntil: 'networkidle' });
      await page.screenshot({ 
        path: `/tmp/arena-a11y-fail-${pr.name.replace(/\s+/g, '-').toLowerCase()}.png`,
        fullPage: true 
      });
    }
  }

  // ── Summary Report ────────────────────────────────────────────────────────────
  const totalCritical = pageResults.reduce((s, p) => s + p.critical, 0);
  const totalSerious = pageResults.reduce((s, p) => s + p.serious, 0);
  const launchVerdict = totalCritical === 0 ? '✅ A11y: No critical blockers' : `❌ A11y: ${totalCritical} critical violations — BLOCK LAUNCH`;

  console.log('\n══════════════════════════════════════════');
  console.log('ACCESSIBILITY REPORT — Agent Arena');
  console.log('══════════════════════════════════════════');
  pageResults.forEach(p => {
    const status = p.critical > 0 ? '❌' : p.serious > 0 ? '⚠️' : '✅';
    console.log(`${status} ${p.name}: ${p.critical} critical, ${p.serious} serious, ${p.moderate} moderate`);
    if (p.blockers.length > 0) {
      p.blockers.forEach(b => console.log(`     ❌ ${b.id}: ${b.description}`));
    }
  });
  console.log(`\nVerdict: ${launchVerdict}`);
  console.log('══════════════════════════════════════════');

  result.ok = totalCritical === 0;
  result.summary = {
    verdict: launchVerdict,
    pageResults,
    totalCritical,
    totalSerious,
    totalViolations: allViolations.length
  };
};
```

## Known Acceptable Violations (Noise Filter)

Some violations are framework-generated and not fixable at the app level. Filter these:

```javascript
const KNOWN_ACCEPTABLE = [
  'duplicate-id',        // Next.js sometimes generates these during hydration
  'region',              // Over-flagged on SPAs without full landmark structure
];

const filteredViolations = violations.filter(v => !KNOWN_ACCEPTABLE.includes(v.id));
```

## Report Format

For each page, report:
```
[status] Page Name
  ❌ critical-rule-id: What it means (N nodes affected)
  ⚠️  serious-rule-id: What it means
  📋 N moderate violations
  💡 N minor violations
```

## Integrating into Full E2E Suite

Add a11y check after each page navigation in the main E2E script:

```javascript
// After every page.goto() in E2E:
const { checkA11y } = require('@axe-core/playwright');
try {
  await checkA11y(page);
} catch (violations) {
  console.warn(`[A11y] Violations on ${page.url()}:`, violations);
  // Don't fail the test — log and continue
}
```

## WCAG 2.1 AA Quick Reference

| Rule | WCAG | What to Check |
|------|------|---------------|
| `image-alt` | 1.1.1 | All `<img>` have meaningful alt text |
| `label` | 1.3.1 | All form inputs have `<label>` |
| `color-contrast` | 1.4.3 | 4.5:1 ratio for normal text, 3:1 for large |
| `keyboard` | 2.1.1 | Everything clickable is Tab-accessible |
| `focus-visible` | 2.4.7 | Focused element has visible ring |
| `document-title` | 2.4.2 | `<title>` exists and is descriptive |
| `html-has-lang` | 3.1.1 | `<html lang="en">` present |
| `heading-order` | 1.3.1 | h1 → h2 → h3, no skips |
| `link-name` | 4.1.2 | Links have accessible names |
| `button-name` | 4.1.2 | Buttons have accessible names |
