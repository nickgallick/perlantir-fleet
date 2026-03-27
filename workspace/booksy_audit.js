const { chromium, devices } = require('playwright');
const fs = require('fs');
const path = require('path');
const BASE = 'https://booksy-clone-one.vercel.app';
const OUT = '/tmp/qa-screenshots/booksy-m1';
fs.mkdirSync(OUT, { recursive: true });
const WAIT = 2500;

async function goto(page, url){
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForTimeout(WAIT);
}
async function shot(page, name){ await page.screenshot({ path: path.join(OUT, name+'.png'), fullPage: true }); }
async function body(page){ return ((await page.textContent('body').catch(()=>''))||'').replace(/\s+/g,' ').trim(); }
async function findByText(page, re){
  const locs = [page.getByRole('button', { name: re }), page.getByRole('link', { name: re }), page.getByText(re)];
  for (const loc of locs) { if (await loc.count().catch(()=>0)) return loc.first(); }
  return null;
}
async function run(mode){
  const browser = await chromium.launch({ headless: true, executablePath: '/usr/bin/chromium', args:['--no-sandbox'] });
  const context = await browser.newContext(mode==='mobile' ? {...devices['iPhone 13']} : { viewport: { width: 1440, height: 1800 } });
  const page = await context.newPage();
  const res = { mode, console: [], errors: [], observations: {} };
  page.on('console', m => res.console.push(`${m.type()}: ${m.text()}`));
  page.on('pageerror', e => res.errors.push(`pageerror: ${e.message}`));
  page.on('response', r => { if (r.status() >= 400) res.errors.push(`HTTP ${r.status()} ${r.url()}`); });

  await goto(page, BASE);
  res.observations.home = { url: page.url(), title: await page.title(), body: (await body(page)).slice(0,1200) };
  await shot(page, `${mode}_home`);

  // search/home CTA discovery
  const homeLinks = await page.locator('a').evaluateAll(els => els.map(a => ({text:(a.textContent||'').trim(), href:a.href})).filter(x=>x.text||x.href));
  res.observations.homeLinks = homeLinks.slice(0,80);

  // locate provider-like link
  let providerHref = null;
  for (const l of homeLinks) {
    if (/provider|business|barber|salon|spa|nails|massage/i.test(l.href) || /book now|view profile|see details/i.test(l.text)) { providerHref = l.href; break; }
  }
  if (!providerHref && homeLinks.length) providerHref = homeLinks.find(l => l.href.startsWith(BASE))?.href;
  res.observations.providerHref = providerHref;

  // search page candidates
  for (const u of [`${BASE}/search`, `${BASE}/providers`, `${BASE}/discover`]) {
    await goto(page, u).catch(e=>res.errors.push(`goto ${u}: ${e.message}`));
    const b = await body(page);
    if (b && !/404/i.test(b)) { res.observations.search = { url: page.url(), body: b.slice(0,1200) }; await shot(page, `${mode}_search`); break; }
  }

  if (providerHref) {
    await goto(page, providerHref);
    res.observations.provider = { url: page.url(), body: (await body(page)).slice(0,1600) };
    await shot(page, `${mode}_provider`);

    const actions = [];
    for (let i=0;i<5;i++) {
      const before = page.url();
      let clicked = false;
      for (const re of [/book now/i,/continue/i,/next/i,/reserve/i,/select/i,/available/i,/sign in/i,/sign up/i]) {
        const loc = await findByText(page, re);
        if (loc) {
          try { await loc.click({ timeout: 3000 }); await page.waitForTimeout(WAIT); clicked = true; break; } catch(e) {}
        }
      }
      if (!clicked) {
        const radio = page.locator('input[type=radio]').first();
        if (await radio.count().catch(()=>0)) { await radio.check().catch(()=>radio.click()); clicked = true; await page.waitForTimeout(1000); }
      }
      const b = await body(page);
      actions.push({ step:i+1, url: page.url(), changed: page.url()!==before, body: b.slice(0,1200) });
      if (!clicked) break;
      if (/login|signup|account|auth/i.test(page.url()) || /log in|sign up|create account|forgot password/i.test(b)) break;
    }
    res.observations.booking = actions;
    await shot(page, `${mode}_booking_end`);
  }

  // auth routes
  for (const key of ['login','signup']) {
    const urls = key==='login' ? [`${BASE}/login`,`${BASE}/auth/login`,`${BASE}/sign-in`] : [`${BASE}/signup`,`${BASE}/auth/signup`,`${BASE}/sign-up`];
    for (const u of urls) {
      try {
        await goto(page, u);
        const b = await body(page);
        if (b && !/404/i.test(b)) { res.observations[key] = { url: page.url(), body: b.slice(0,1400) }; await shot(page, `${mode}_${key}`); break; }
      } catch(e) { res.errors.push(`${key} ${u}: ${e.message}`); }
    }
  }

  // forgot visibility on login
  if (res.observations.login?.url) {
    await goto(page, res.observations.login.url);
    const b = await body(page);
    res.observations.forgot = { forgot: /forgot/i.test(b), reset: /reset/i.test(b), body: b.slice(0,900) };
  }

  // account redirect
  const redirects = [];
  for (const u of [`${BASE}/account`,`${BASE}/dashboard`,`${BASE}/profile`]) {
    try { await goto(page, u); redirects.push({ requested:u, final:page.url(), body:(await body(page)).slice(0,900) }); }
    catch(e) { redirects.push({ requested:u, error:e.message }); }
  }
  res.observations.redirects = redirects;

  if (mode==='mobile') {
    await goto(page, BASE);
    res.observations.mobileNav = await page.evaluate(() => Array.from(document.querySelectorAll('nav a, nav button, [role="navigation"] a, [role="navigation"] button')).map(el => ({text:(el.textContent||'').trim(), href:el.getAttribute('href')})).filter(x=>x.text||x.href));
    await shot(page, 'mobile_nav');
  }

  await browser.close();
  return res;
}

(async()=>{
  const output = { desktop: await run('desktop'), mobile: await run('mobile') };
  fs.writeFileSync(path.join(OUT, 'results.json'), JSON.stringify(output, null, 2));
  console.log(JSON.stringify(output, null, 2));
})();
