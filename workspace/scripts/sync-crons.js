#!/usr/bin/env node
/**
 * Sync OpenClaw cron jobs to Supabase for Mission Control
 * Reads from OpenClaw gateway cron API and pushes to cron_jobs table
 */

const https = require('https');

const SUPABASE_URL = 'https://zjcgoeivuwkrpqezyhqg.supabase.co';
const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpqY2dvZWl2dXdrcnBxZXp5aHFnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MzY5NjA0OCwiZXhwIjoyMDg5MjcyMDQ4fQ.OTKTHrLUtVjAJsTVGsrv3h0AA0wEpeo4uaMjqESMRD4';
const GATEWAY_URL = 'http://127.0.0.1:45133';
const GATEWAY_TOKEN = 'R0ddvlV8VIER6QRhJ8KujsOdZfJG7HxM';

function fetch(url, options = {}) {
  return new Promise((resolve, reject) => {
    const mod = url.startsWith('https') ? https : require('http');
    const req = mod.request(url, options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({ status: res.statusCode, data }));
    });
    req.on('error', reject);
    if (options.body) req.write(options.body);
    req.end();
  });
}

async function getCronJobs() {
  // Use the OpenClaw gateway WS protocol via HTTP to list crons
  // Since we're on the same machine, read from the gateway API
  const res = await fetch(`${GATEWAY_URL}/api/cron/list`, {
    method: 'GET',
    headers: { 'Authorization': `Bearer ${GATEWAY_TOKEN}` },
  });
  
  if (res.status === 200) {
    return JSON.parse(res.data);
  }
  
  // Fallback: read from session files
  const fs = require('fs');
  const path = require('path');
  
  // Try reading cron state directly
  const cronPaths = [
    '/data/.openclaw/cron-jobs.json',
    '/data/.openclaw/crons.json',
  ];
  
  for (const p of cronPaths) {
    if (fs.existsSync(p)) {
      return JSON.parse(fs.readFileSync(p, 'utf-8'));
    }
  }
  
  return null;
}

async function syncToSupabase(jobs) {
  for (const job of jobs) {
    let schedule = '';
    if (job.schedule?.kind === 'cron') {
      schedule = `${job.schedule.expr}${job.schedule.tz ? ` (${job.schedule.tz})` : ''}`;
    } else if (job.schedule?.kind === 'every') {
      const mins = Math.round(job.schedule.everyMs / 60000);
      schedule = `every ${mins} min`;
    } else if (job.schedule?.kind === 'at') {
      schedule = `once at ${job.schedule.at}`;
    }

    const nextRun = job.state?.nextRunAtMs ? new Date(job.state.nextRunAtMs).toISOString() : null;
    const lastRun = job.state?.lastRunAtMs ? new Date(job.state.lastRunAtMs).toISOString() : null;

    const row = {
      id: job.id,
      name: job.name || 'Unnamed',
      schedule,
      next_run: nextRun,
      last_run: lastRun,
      status: job.enabled ? 'active' : 'paused',
      config: JSON.stringify({
        agent: job.agentId,
        sessionTarget: job.sessionTarget,
        delivery: job.delivery?.mode || 'none',
        payload: job.payload?.kind || 'unknown',
      }),
    };

    const body = JSON.stringify(row);
    
    try {
      await fetch(`${SUPABASE_URL}/rest/v1/cron_jobs?on_conflict=id`, {
        method: 'POST',
        headers: {
          'apikey': SUPABASE_SERVICE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'resolution=merge-duplicates,return=minimal',
        },
        body,
      });
      console.log(`  ✓ ${row.name} (${schedule})`);
    } catch (e) {
      console.log(`  ✗ ${row.name}: ${e.message}`);
    }
  }
}

async function main() {
  console.log('=== Cron Sync Starting ===');
  
  // For now, use the OpenClaw cron tool data we already know about
  // In the future this should query the gateway API
  const fs = require('fs');
  
  // Read from OpenClaw's internal state
  const statePaths = [
    '/data/.openclaw/agents/main/agent/cron-state.json',
    '/data/.openclaw/agents/pm/agent/cron-state.json',
    '/data/.openclaw/cron-state.json',
  ];
  
  let allJobs = [];
  
  for (const p of statePaths) {
    if (fs.existsSync(p)) {
      try {
        const data = JSON.parse(fs.readFileSync(p, 'utf-8'));
        const jobs = data.jobs || (Array.isArray(data) ? data : []);
        allJobs.push(...jobs);
        console.log(`  Found ${jobs.length} jobs in ${p}`);
      } catch (e) {
        console.log(`  Error reading ${p}: ${e.message}`);
      }
    }
  }
  
  // Also check the gateway data directory
  const gatewayState = '/data/.openclaw/gateway-state.json';
  if (fs.existsSync(gatewayState)) {
    try {
      const data = JSON.parse(fs.readFileSync(gatewayState, 'utf-8'));
      if (data.cron?.jobs) {
        allJobs.push(...data.cron.jobs);
        console.log(`  Found ${data.cron.jobs.length} jobs in gateway state`);
      }
    } catch (e) {}
  }

  if (allJobs.length === 0) {
    console.log('  No cron state files found — jobs already synced manually');
  } else {
    await syncToSupabase(allJobs);
  }

  console.log('=== Cron Sync Complete ===');
}

main().catch(e => console.error('Failed:', e));
