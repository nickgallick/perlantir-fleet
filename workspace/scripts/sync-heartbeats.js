#!/usr/bin/env node

// sync-heartbeats.js — Checks agent activity and logs heartbeats to Supabase.
// If an agent has recent agent_activity entries (within 2 hours), logs 'ok'.
// If no activity for >2h, logs 'missed'.

const SUPABASE_URL = 'https://zjcgoeivuwkrpqezyhqg.supabase.co';
const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpqY2dvZWl2dXdrcnBxZXp5aHFnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MzY5NjA0OCwiZXhwIjoyMDg5MjcyMDQ4fQ.OTKTHrLUtVjAJsTVGsrv3h0AA0wEpeo4uaMjqESMRD4';
const TWO_HOURS_MS = 2 * 60 * 60 * 1000;

async function supabaseRequest(path, options = {}) {
  const url = `${SUPABASE_URL}/rest/v1/${path}`;
  const res = await fetch(url, {
    ...options,
    headers: {
      'apikey': SUPABASE_SERVICE_KEY,
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      'Content-Type': 'application/json',
      'Prefer': options.method === 'POST' ? 'return=representation' : 'return=minimal',
      ...options.headers,
    },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Supabase ${path}: ${res.status} ${text}`);
  }
  const contentType = res.headers.get('content-type') || '';
  if (contentType.includes('json')) return res.json();
  return null;
}

async function main() {
  console.log('[sync-heartbeats] Starting heartbeat sync...');

  // 1. Get all agents
  const agents = await supabaseRequest('agents?select=id,name');
  if (!agents || agents.length === 0) {
    console.log('[sync-heartbeats] No agents found.');
    return;
  }
  console.log(`[sync-heartbeats] Found ${agents.length} agents: ${agents.map(a => a.name).join(', ')}`);

  const now = new Date();
  const twoHoursAgo = new Date(now.getTime() - TWO_HOURS_MS).toISOString();

  for (const agent of agents) {
    // 2. Check for recent agent_activity
    const activity = await supabaseRequest(
      `agent_activity?agent_id=eq.${agent.id}&timestamp=gte.${twoHoursAgo}&select=id,timestamp&order=timestamp.desc&limit=1`
    );

    const hasRecentActivity = activity && activity.length > 0;
    const status = hasRecentActivity ? 'ok' : 'missed';
    const message = hasRecentActivity
      ? `Agent ${agent.name} has recent activity (last: ${activity[0].timestamp})`
      : `Agent ${agent.name} has no activity in the last 2 hours`;

    console.log(`[sync-heartbeats] ${agent.name}: ${status} — ${message}`);

    // 3. Insert heartbeat
    await supabaseRequest('heartbeats', {
      method: 'POST',
      body: JSON.stringify({
        agent_id: agent.id,
        agent_name: agent.name,
        status,
        message,
      }),
    });

    console.log(`[sync-heartbeats] Heartbeat logged for ${agent.name}: ${status}`);
  }

  console.log('[sync-heartbeats] Done.');
}

main().catch(err => {
  console.error('[sync-heartbeats] Fatal error:', err);
  process.exit(1);
});
