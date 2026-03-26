---
name: playwright-oauth-github
description: Handle GitHub OAuth flows in Playwright for Agent Arena. Correct technique using page.goto() for the auth initiation URL — not button clicks or fetch interception. Handles login, authorization grant, callback, and session verification.
---

# Playwright GitHub OAuth Skill

## Key Insight

GitHub OAuth **cannot** be done via fetch/XHR. The `/api/auth/github` route correctly returns a `302 redirect` — the browser must follow it. In Playwright, trigger it with `page.goto()` directly on the auth URL, not by clicking a UI button and intercepting the request.

The CORS errors seen in early tests were caused by Playwright treating the redirect as a fetch. **The route is not broken — the test technique was wrong.**

## Arena-Specific Config

- Auth initiation URL: `https://agent-arena-roan.vercel.app/api/auth/github`
- Post-login redirect: `/` (dashboard route group — NOT `/dashboard`)
- Login page: `/login`
- Test credentials: `/data/.openclaw/workspace-forge/test-credentials.md`
  - Email: `osintreconthreat@proton.me`
  - Password: `OpenClaw12`

## Working OAuth Login Code

```javascript
/**
 * performGithubOAuth - Full GitHub OAuth flow for Playwright
 * 
 * @param {import('playwright').Page} page
 * @param {string} email - GitHub account email
 * @param {string} password - GitHub account password
 * @returns {Promise<{ success: boolean, url: string, error?: string }>}
 */
async function performGithubOAuth(page, email, password) {
  const ARENA_BASE = 'https://agent-arena-roan.vercel.app';
  const AUTH_URL = `${ARENA_BASE}/api/auth/github`;
  
  // Step 1: Navigate directly to auth initiation URL
  // This triggers the 302 → github.com/login/oauth/authorize redirect chain
  console.log('[OAuth] Navigating to auth URL:', AUTH_URL);
  await page.goto(AUTH_URL, { waitUntil: 'domcontentloaded', timeout: 20000 });
  
  // Step 2: Detect where we landed
  const currentUrl = page.url();
  console.log('[OAuth] Landed at:', currentUrl);
  
  // Step 3: Already logged in to GitHub? Check if we're on authorize page directly
  if (currentUrl.includes('github.com/login/oauth/authorize')) {
    console.log('[OAuth] Already logged into GitHub — going straight to authorize step');
    return await handleAuthorize(page, ARENA_BASE);
  }
  
  // Step 4: GitHub login page — fill credentials
  if (currentUrl.includes('github.com/login')) {
    console.log('[OAuth] On GitHub login page — filling credentials');
    
    // Wait for login form
    await page.waitForSelector('#login_field', { timeout: 10000 });
    
    await page.fill('#login_field', email);
    await page.fill('#password', password);
    
    // Submit
    await page.click('[name="commit"]', { timeout: 5000 });
    await page.waitForLoadState('domcontentloaded');
    
    const postLoginUrl = page.url();
    console.log('[OAuth] Post-login URL:', postLoginUrl);
    
    // Check for 2FA prompt
    if (postLoginUrl.includes('two-factor') || postLoginUrl.includes('sessions/two-factor')) {
      console.error('[OAuth] ⚠️ 2FA required — cannot automate. Disable 2FA on test account.');
      return { success: false, url: postLoginUrl, error: '2FA_REQUIRED' };
    }
    
    // Check for incorrect password
    if (postLoginUrl.includes('github.com/login') || postLoginUrl.includes('session')) {
      const errorMsg = await page.locator('.flash-error, #js-flash-container').textContent().catch(() => null);
      if (errorMsg) {
        console.error('[OAuth] Login failed:', errorMsg.trim());
        return { success: false, url: postLoginUrl, error: errorMsg.trim() };
      }
    }
  }
  
  // Step 5: Handle OAuth authorize page (may appear after login)
  if (page.url().includes('github.com/login/oauth/authorize') || 
      page.url().includes('github.com/login')) {
    // May still be processing — wait for navigation
    await page.waitForURL(url => url.includes('oauth/authorize') || !url.includes('github.com/login'), {
      timeout: 15000
    }).catch(() => {});
  }
  
  return await handleAuthorize(page, ARENA_BASE);
}

/**
 * handleAuthorize - Handle the GitHub OAuth authorization grant screen
 * Skips automatically if already authorized (GitHub remembers previous grants)
 */
async function handleAuthorize(page, arenaBase) {
  const currentUrl = page.url();
  
  // If on authorize page, click the green authorize button
  if (currentUrl.includes('github.com/login/oauth/authorize')) {
    console.log('[OAuth] On authorize page — checking for authorize button');
    
    const authorizeBtn = page.locator('button[name="authorize"], input[name="authorize"], button:has-text("Authorize")');
    
    const btnVisible = await authorizeBtn.isVisible({ timeout: 5000 }).catch(() => false);
    if (btnVisible) {
      console.log('[OAuth] Clicking authorize button');
      await authorizeBtn.first().click();
      await page.waitForLoadState('domcontentloaded');
    } else {
      console.log('[OAuth] No authorize button — app already authorized, continuing');
    }
  }
  
  // Step 6: Wait for redirect back to Arena callback, then to dashboard
  console.log('[OAuth] Waiting for redirect back to Arena...');
  
  try {
    await page.waitForURL(url => {
      return url.includes(arenaBase) && !url.includes('/callback');
    }, { timeout: 20000 });
  } catch (e) {
    // May have landed on callback or another page
    const url = page.url();
    if (!url.includes(arenaBase)) {
      return { success: false, url, error: 'Did not redirect back to Arena' };
    }
  }
  
  // Step 7: Verify login success
  const finalUrl = page.url();
  return await verifyLoginSuccess(page, finalUrl, arenaBase);
}

/**
 * verifyLoginSuccess - Confirm authenticated session established
 */
async function verifyLoginSuccess(page, finalUrl, arenaBase) {
  console.log('[OAuth] Verifying login at:', finalUrl);
  
  // Check for authenticated nav elements
  const authIndicators = [
    page.getByRole('img', { name: /avatar|profile/i }),
    page.locator('[data-testid="user-avatar"]'),
    page.locator('nav a[href*="settings"]'),
    page.locator('nav a[href*="agents"]'),
    page.locator('[class*="avatar"]'),
  ];
  
  for (const indicator of authIndicators) {
    if (await indicator.isVisible({ timeout: 3000 }).catch(() => false)) {
      console.log('[OAuth] ✅ Login confirmed via auth indicator');
      return { success: true, url: finalUrl };
    }
  }
  
  // Fallback: check we're not on login page
  if (!finalUrl.includes('/login') && !finalUrl.includes('github.com')) {
    console.log('[OAuth] ✅ Login likely successful — not on login/github page');
    return { success: true, url: finalUrl };
  }
  
  return { success: false, url: finalUrl, error: 'Auth indicators not found after redirect' };
}

/**
 * isAlreadyLoggedIn - Check if current session is authenticated
 * Use before OAuth flow to skip login if already authenticated
 */
async function isAlreadyLoggedIn(page, arenaBase) {
  const meResp = await page.request.get(`${arenaBase}/api/me`).catch(() => null);
  if (meResp && meResp.status() === 200) {
    console.log('[OAuth] Already authenticated via /api/me');
    return true;
  }
  return false;
}
```

## Full Integration Example

```javascript
// /tmp/playwright-test-oauth-arena.js
exports.config = { headed: false, slowMo: 50 };

exports.run = async ({ page, result }) => {
  const BASE = 'https://agent-arena-roan.vercel.app';
  const CREDS = { 
    email: 'osintreconthreat@proton.me', 
    password: 'OpenClaw12' 
  };

  // Skip if already logged in
  const alreadyIn = await isAlreadyLoggedIn(page, BASE);
  if (!alreadyIn) {
    const authResult = await performGithubOAuth(page, CREDS.email, CREDS.password);
    if (!authResult.success) {
      result.ok = false;
      result.error = `OAuth failed: ${authResult.error}`;
      return;
    }
  }

  // Navigate to authenticated dashboard (route group — URL is /, not /dashboard)
  await page.goto(BASE, { waitUntil: 'networkidle' });
  await page.screenshot({ path: '/tmp/arena-authenticated.png', fullPage: true });
  
  result.ok = true;
  result.summary = { loggedIn: true, url: page.url() };
};
```

## Common Failure Modes

| Failure | Cause | Fix |
|---------|-------|-----|
| CORS errors | Used fetch/button intercept instead of page.goto() | Always use `page.goto(authUrl)` |
| Timeout on authorize | Button text mismatch | Check for `button[name="authorize"]` not text |
| 2FA prompt | Test account has 2FA enabled | Disable 2FA on test account |
| Redirect loop | Callback URL not whitelisted in GitHub OAuth app | Add preview URL to GitHub OAuth app callback |
| Session not persisting | Context closed before cookies saved | Use persistent context or save cookies |
| Landing on /login after callback | Supabase session not set | Check SUPABASE_URL/ANON_KEY on Vercel env |

## Important Notes

- **Dashboard URL is `/` not `/dashboard`** — Arena uses a route group `(dashboard)`. Going to `/dashboard` hits a 404.
- The `/api/auth/github` 302 redirect is **correct behavior** — not a bug.
- GitHub remembers OAuth authorization grants — the authorize button only appears on first login.
- Test account must NOT have 2FA enabled.
