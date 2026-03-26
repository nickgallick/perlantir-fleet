---
name: test-data-seeding
description: Seed Supabase with known test data before Arena E2E runs, then clean up after. Uses service key to bypass RLS. Idempotent — safe to re-run. Covers challenges, agents, and challenge_entries.
---

# Test Data Seeding — Agent Arena

## Why This Matters

Tests that depend on production data are flaky. Challenges may be expired, agents may be deleted, entries may already be submitted. Seeding creates **known, controlled test data** that tests can rely on — then cleans up after.

## Arena Schema (key tables)

```sql
profiles(id, display_name, avatar_url, is_admin, coins)
agents(id, user_id, name, model_name, mps, weight_class_id, api_key_hash, is_online)
challenges(id, title, description, status, category, type, prize_coins)
challenge_entries(id, challenge_id, agent_id, user_id, status, submission_text)
```

## Env Variables Required

```bash
ARENA_SUPABASE_URL=https://gojpbtlajzigvyfkghrg.supabase.co
ARENA_SUPABASE_SERVICE_KEY=<service_role_key>   # bypasses RLS
ARENA_TEST_USER_ID=<uuid of test user>           # set after first OAuth login
```

Store in `/data/.openclaw/workspace-forge/test-credentials.md` (never commit).

## Seeding Script

```javascript
// /tmp/arena-seed.js
// Usage: node /tmp/arena-seed.js [--cleanup]
// Requires: ARENA_SUPABASE_URL and ARENA_SUPABASE_SERVICE_KEY in env

const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = process.env.ARENA_SUPABASE_URL;
const SERVICE_KEY = process.env.ARENA_SUPABASE_SERVICE_KEY;
const TEST_USER_ID = process.env.ARENA_TEST_USER_ID;

// TEST DATA MARKER — all seeded rows include this in title/name
// for easy identification and cleanup
const TEST_MARKER = '[E2E-TEST]';

if (!SUPABASE_URL || !SERVICE_KEY) {
  console.error('Missing ARENA_SUPABASE_URL or ARENA_SUPABASE_SERVICE_KEY');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SERVICE_KEY, {
  auth: { persistSession: false }
});

// ── Cleanup ────────────────────────────────────────────────────────────────────

async function cleanup() {
  console.log('🧹 Cleaning up test data...');

  // Order matters: entries reference agents and challenges
  const { error: e1, count: c1 } = await supabase
    .from('challenge_entries')
    .delete({ count: 'exact' })
    .ilike('submission_text', `%${TEST_MARKER}%`);
  if (e1) console.error('  ❌ challenge_entries cleanup:', e1.message);
  else console.log(`  ✅ Deleted ${c1} test challenge_entries`);

  const { error: e2, count: c2 } = await supabase
    .from('agents')
    .delete({ count: 'exact' })
    .ilike('name', `%${TEST_MARKER}%`);
  if (e2) console.error('  ❌ agents cleanup:', e2.message);
  else console.log(`  ✅ Deleted ${c2} test agents`);

  const { error: e3, count: c3 } = await supabase
    .from('challenges')
    .delete({ count: 'exact' })
    .ilike('title', `%${TEST_MARKER}%`);
  if (e3) console.error('  ❌ challenges cleanup:', e3.message);
  else console.log(`  ✅ Deleted ${c3} test challenges`);

  console.log('🧹 Cleanup complete\n');
}

// ── Idempotent seed helpers ────────────────────────────────────────────────────

async function upsertChallenge() {
  // Check if test challenge already exists (idempotent)
  const { data: existing } = await supabase
    .from('challenges')
    .select('id')
    .ilike('title', `%${TEST_MARKER}%`)
    .single();

  if (existing) {
    console.log('  ⏭️  Test challenge already exists:', existing.id);
    return existing.id;
  }

  const { data, error } = await supabase
    .from('challenges')
    .insert({
      title: `${TEST_MARKER} E2E Challenge - Safe to delete`,
      description: 'Automated E2E test challenge. Delete if found in production.',
      status: 'active',
      category: 'reasoning',
      type: 'daily',
      prize_coins: 0,
    })
    .select('id')
    .single();

  if (error) {
    console.error('  ❌ challenge seed failed:', error.message);
    throw error;
  }

  console.log('  ✅ Created test challenge:', data.id);
  return data.id;
}

async function upsertAgent(userId) {
  if (!userId) {
    console.warn('  ⚠️  No TEST_USER_ID — skipping agent seed');
    return null;
  }

  // Check if test agent already exists
  const { data: existing } = await supabase
    .from('agents')
    .select('id, api_key_hash')
    .eq('user_id', userId)
    .ilike('name', `%${TEST_MARKER}%`)
    .single();

  if (existing) {
    console.log('  ⏭️  Test agent already exists:', existing.id);
    return existing.id;
  }

  const { data, error } = await supabase
    .from('agents')
    .insert({
      user_id: userId,
      name: `${TEST_MARKER} E2E Agent - Safe to delete`,
      model_name: 'gpt-4o-mini',
      mps: 0,
      is_online: false,
      api_key_hash: 'test_hash_not_real', // Not a real key
    })
    .select('id')
    .single();

  if (error) {
    console.error('  ❌ agent seed failed:', error.message);
    throw error;
  }

  console.log('  ✅ Created test agent:', data.id);
  return data.id;
}

async function upsertChallengeEntry(challengeId, agentId, userId) {
  if (!agentId || !userId) {
    console.warn('  ⚠️  Missing agentId or userId — skipping entry seed');
    return null;
  }

  // Check if test entry already exists
  const { data: existing } = await supabase
    .from('challenge_entries')
    .select('id')
    .eq('challenge_id', challengeId)
    .eq('agent_id', agentId)
    .single();

  if (existing) {
    console.log('  ⏭️  Test entry already exists:', existing.id);
    return existing.id;
  }

  const { data, error } = await supabase
    .from('challenge_entries')
    .insert({
      challenge_id: challengeId,
      agent_id: agentId,
      user_id: userId,
      status: 'pending',
      submission_text: `${TEST_MARKER} test submission`,
    })
    .select('id')
    .single();

  if (error) {
    console.error('  ❌ entry seed failed:', error.message);
    throw error;
  }

  console.log('  ✅ Created test entry:', data.id);
  return data.id;
}

// ── Verification ──────────────────────────────────────────────────────────────

async function verifySeed(challengeId, agentId, entryId) {
  console.log('\n🔍 Verifying seed...');
  let ok = true;

  if (challengeId) {
    const { data } = await supabase.from('challenges').select('id, status').eq('id', challengeId).single();
    if (data?.status === 'active') console.log('  ✅ Challenge active:', challengeId);
    else { console.error('  ❌ Challenge not active or not found'); ok = false; }
  }

  if (agentId) {
    const { data } = await supabase.from('agents').select('id').eq('id', agentId).single();
    if (data) console.log('  ✅ Agent exists:', agentId);
    else { console.error('  ❌ Agent not found'); ok = false; }
  }

  if (entryId) {
    const { data } = await supabase.from('challenge_entries').select('id').eq('id', entryId).single();
    if (data) console.log('  ✅ Entry exists:', entryId);
    else { console.error('  ❌ Entry not found'); ok = false; }
  }

  return ok;
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function seed() {
  console.log('🌱 Seeding test data...');
  const challengeId = await upsertChallenge();
  const agentId = await upsertAgent(TEST_USER_ID);
  const entryId = await upsertChallengeEntry(challengeId, agentId, TEST_USER_ID);
  const ok = await verifySeed(challengeId, agentId, entryId);

  const ids = { challengeId, agentId, entryId };
  console.log('\n📋 Seed output:', JSON.stringify(ids, null, 2));

  if (!ok) {
    console.error('❌ Seed verification failed');
    process.exit(1);
  }

  console.log('✅ Seed complete\n');
  return ids;
}

// ── Entry point ───────────────────────────────────────────────────────────────

(async () => {
  const isCleanup = process.argv.includes('--cleanup');

  if (isCleanup) {
    await cleanup();
  } else {
    await cleanup(); // Always clean first for fresh state
    await seed();
  }
})();
```

## Playwright Integration (before/after hooks)

```javascript
// In your Playwright test file:
const { execSync } = require('child_process');

// Before all tests
async function beforeAll() {
  execSync('node /tmp/arena-seed.js', {
    env: {
      ...process.env,
      ARENA_SUPABASE_URL: 'https://gojpbtlajzigvyfkghrg.supabase.co',
      ARENA_SUPABASE_SERVICE_KEY: process.env.ARENA_SERVICE_KEY,
      ARENA_TEST_USER_ID: process.env.ARENA_TEST_USER_ID,
    },
    stdio: 'inherit'
  });
}

// After all tests
async function afterAll() {
  execSync('node /tmp/arena-seed.js --cleanup', {
    env: { /* same env */ },
    stdio: 'inherit'
  });
}
```

## Running Manually

```bash
# Seed (cleans first, then seeds)
ARENA_SUPABASE_URL=https://... ARENA_SUPABASE_SERVICE_KEY=... node /tmp/arena-seed.js

# Cleanup only
ARENA_SUPABASE_URL=https://... ARENA_SUPABASE_SERVICE_KEY=... node /tmp/arena-seed.js --cleanup
```

## Safety Rules

1. **Always use `[E2E-TEST]` marker** in every seeded row title/name/text
2. **Service key stays server-side only** — never in browser context or client code
3. **Clean before seeding** — prevents duplicate test data from interrupted runs
4. **Verify after seed** — don't start tests if seed failed
5. **Never seed into production without --dry-run confirmation** (add flag if needed)
