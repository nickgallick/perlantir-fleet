#!/usr/bin/env node
/**
 * Unified sync: OpenClaw VPS → Supabase Mission Control
 * Syncs: sessions, crons, memory files, heartbeats, workspace files, agent config
 * Run every 5 minutes via background loop
 */

const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');

const SUPABASE_URL = 'https://zjcgoeivuwkrpqezyhqg.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpqY2dvZWl2dXdrcnBxZXp5aHFnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MzY5NjA0OCwiZXhwIjoyMDg5MjcyMDQ4fQ.OTKTHrLUtVjAJsTVGsrv3h0AA0wEpeo4uaMjqESMRD4';

const AGENTS = [
  { name: 'Maks', role: 'main', dir: '/data/.openclaw/agents/main/sessions', workspace: '/data/.openclaw/workspace' },
  { name: 'MaksPM', role: 'pm', dir: '/data/.openclaw/agents/pm/sessions', workspace: '/data/.openclaw/workspace-pm' },
];

async function supaPost(table, body, query = '') {
  return new Promise((resolve, reject) => {
    const url = new URL(`/rest/v1/${table}${query}`, SUPABASE_URL);
    const req = https.request(url, {
      method: 'POST',
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': 'resolution=merge-duplicates,return=minimal',
      },
    }, (res) => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => resolve({ status: res.statusCode, data }));
    });
    req.on('error', reject);
    req.write(JSON.stringify(body));
    req.end();
  });
}

async function supaDelete(table, query) {
  return new Promise((resolve, reject) => {
    const url = new URL(`/rest/v1/${table}${query}`, SUPABASE_URL);
    const req = https.request(url, {
      method: 'DELETE',
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'Prefer': 'return=minimal',
      },
    }, (res) => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => resolve({ status: res.statusCode }));
    });
    req.on('error', reject);
    req.end();
  });
}

async function getAgentId(name) {
  return new Promise((resolve, reject) => {
    const url = new URL(`/rest/v1/agents?name=eq.${encodeURIComponent(name)}&select=id`, SUPABASE_URL);
    https.get(url, {
      headers: { 'apikey': SUPABASE_KEY, 'Authorization': `Bearer ${SUPABASE_KEY}` },
    }, (res) => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => {
        const r = JSON.parse(data);
        resolve(r[0]?.id || null);
      });
    }).on('error', reject);
  });
}

// ====== SESSION SYNC ======
async function syncSessions() {
  console.log('\n📬 Syncing sessions...');
  for (const agent of AGENTS) {
    const agentId = await getAgentId(agent.name);
    if (!agentId || !fs.existsSync(agent.dir)) continue;

    const files = fs.readdirSync(agent.dir).filter(f => f.endsWith('.jsonl') && !f.endsWith('.lock'));
    for (const file of files) {
      const sessionId = file.replace('.jsonl', '');
      const lines = fs.readFileSync(path.join(agent.dir, file), 'utf-8').trim().split('\n');
      const messages = [];
      let model = null;

      for (const line of lines) {
        try {
          const e = JSON.parse(line);
          if (e.type === 'model_change') model = e.modelId;
          if (e.type === 'message' && e.message) {
            let text = '';
            if (Array.isArray(e.message.content)) {
              text = e.message.content.filter(c => c.type === 'text').map(c => c.text).join('\n');
            } else if (typeof e.message.content === 'string') {
              text = e.message.content;
            }
            if (!text || text.length < 2) continue;
            if (text.length > 10000) text = text.substring(0, 10000) + '... [truncated]';
            const tokens = (e.message.usage?.input || 0) + (e.message.usage?.output || 0);
            messages.push({ role: e.message.role === 'user' ? 'user' : 'assistant', content: text, tokens, created_at: e.timestamp });
          }
        } catch {}
      }

      if (messages.length === 0) continue;
      const totalTokens = messages.reduce((s, m) => s + m.tokens, 0);

      await supaPost('sessions', {
        id: sessionId, agent_id: agentId, agent_name: agent.name,
        session_key: `agent:${agent.role}:telegram`, status: 'active', channel: 'telegram',
        model: model || 'unknown', context_tokens: totalTokens, max_context_tokens: 1000000,
        total_messages: messages.length, started_at: messages[0].created_at,
        last_activity_at: messages[messages.length - 1].created_at,
      });

      await supaDelete('session_messages', `?session_id=eq.${sessionId}`);
      const recent = messages.slice(-100);
      for (let i = 0; i < recent.length; i += 50) {
        await supaPost('session_messages', recent.slice(i, i + 50));
      }
      console.log(`  ✓ ${agent.name}: ${messages.length} msgs, ${totalTokens} tokens`);
    }
  }
}

// ====== CRON SYNC ======
async function syncCrons() {
  console.log('\n⏰ Syncing cron jobs...');
  const cronFile = '/data/.openclaw/cron/jobs.json';
  if (!fs.existsSync(cronFile)) { console.log('  No cron file'); return; }

  const data = JSON.parse(fs.readFileSync(cronFile, 'utf-8'));
  const jobs = Array.isArray(data) ? data : data.jobs || [];

  for (const job of jobs) {
    let schedule = '';
    if (job.schedule?.kind === 'cron') schedule = `${job.schedule.expr}${job.schedule.tz ? ` (${job.schedule.tz})` : ''}`;
    else if (job.schedule?.kind === 'every') schedule = `every ${Math.round(job.schedule.everyMs / 60000)} min`;

    await supaPost('cron_jobs', {
      id: job.id, name: job.name || 'Unnamed', schedule,
      next_run: job.state?.nextRunAtMs ? new Date(job.state.nextRunAtMs).toISOString() : null,
      last_run: job.state?.lastRunAtMs ? new Date(job.state.lastRunAtMs).toISOString() : null,
      status: job.enabled ? 'active' : 'paused',
      config: { agent: job.agentId, sessionTarget: job.sessionTarget, delivery: job.delivery?.mode || 'none' },
    });
    console.log(`  ✓ ${job.name || job.id}`);
  }
}

// ====== MEMORY FILE SYNC ======
async function syncMemoryFiles() {
  console.log('\n🧠 Syncing memory files...');
  for (const agent of AGENTS) {
    const agentId = await getAgentId(agent.name);
    if (!agentId) continue;

    const filesToSync = [];
    
    // Workspace .md files
    const workspace = agent.workspace;
    if (fs.existsSync(workspace)) {
      const mdFiles = fs.readdirSync(workspace).filter(f => f.endsWith('.md'));
      for (const f of mdFiles) {
        const fp = path.join(workspace, f);
        const stat = fs.statSync(fp);
        const content = fs.readFileSync(fp, 'utf-8');
        const type = f === 'MEMORY.md' ? 'memory_long_term' : f === 'SOUL.md' ? 'soul' : f === 'AGENTS.md' ? 'agents' : f === 'TOOLS.md' ? 'tools' : f === 'HEARTBEAT.md' ? 'heartbeat' : f === 'USER.md' ? 'user' : 'agents';
        filesToSync.push({
          agent_id: agentId, agent_name: agent.name, file_path: fp, file_type: type,
          content_preview: content.substring(0, 500), size_bytes: stat.size,
          entries_count: content.split('\n').filter(l => l.startsWith('- ')).length,
          last_modified: stat.mtime.toISOString(),
        });
      }

      // Daily memory files
      const memDir = path.join(workspace, 'memory');
      if (fs.existsSync(memDir)) {
        for (const f of fs.readdirSync(memDir).filter(f => f.endsWith('.md'))) {
          const fp = path.join(memDir, f);
          const stat = fs.statSync(fp);
          const content = fs.readFileSync(fp, 'utf-8');
          filesToSync.push({
            agent_id: agentId, agent_name: agent.name, file_path: fp, file_type: 'memory_daily',
            content_preview: content.substring(0, 500), size_bytes: stat.size,
            entries_count: content.split('\n').filter(l => l.startsWith('- ') || l.startsWith('## ')).length,
            last_modified: stat.mtime.toISOString(),
          });
        }
      }
    }

    for (const f of filesToSync) {
      await supaPost('memory_snapshots', f);
      console.log(`  ✓ ${agent.name}: ${path.basename(f.file_path)} (${f.size_bytes}B)`);
    }
  }
}

// ====== HEARTBEAT SYNC ======
async function syncHeartbeats() {
  console.log('\n💓 Syncing heartbeats...');
  for (const agent of AGENTS) {
    const agentId = await getAgentId(agent.name);
    if (!agentId || !fs.existsSync(agent.dir)) continue;

    // Check for recent activity (within last 2.5 hours)
    const files = fs.readdirSync(agent.dir).filter(f => f.endsWith('.jsonl') && !f.endsWith('.lock'));
    let lastActivity = null;

    for (const file of files) {
      const stat = fs.statSync(path.join(agent.dir, file));
      if (!lastActivity || stat.mtime > lastActivity) lastActivity = stat.mtime;
    }

    const now = new Date();
    const twoHoursAgo = new Date(now - 2.5 * 60 * 60 * 1000);
    const status = lastActivity && lastActivity > twoHoursAgo ? 'ok' : 'missed';

    await supaPost('heartbeats', {
      agent_id: agentId, agent_name: agent.name, status,
      message: status === 'ok' ? `Active — last activity ${Math.round((now - lastActivity) / 60000)}m ago` : 'No recent activity',
    });
    console.log(`  ✓ ${agent.name}: ${status}`);
  }
}

// ====== AGENT STATUS SYNC ======
async function syncAgentStatus() {
  console.log('\n🤖 Syncing agent status...');
  // Check if gateway is alive
  try {
    const res = await new Promise((resolve, reject) => {
      http.get('http://127.0.0.1:45133/health', { headers: { 'Authorization': 'Bearer R0ddvlV8VIER6QRhJ8KujsOdZfJG7HxM' } }, (res) => {
        let data = '';
        res.on('data', c => data += c);
        res.on('end', () => resolve({ status: res.statusCode, data }));
      }).on('error', reject);
    });

    if (res.status === 200) {
      // Gateway alive — mark agents active
      for (const agent of AGENTS) {
        const agentId = await getAgentId(agent.name);
        if (!agentId) continue;
        await supaPost('agents', {
          id: agentId, name: agent.name, status: 'active', mood: 'green',
          current_step: agent.role === 'main' ? 'Ready' : 'Monitoring',
          config: { role: agent.role, gatewayConnected: true, lastSync: new Date().toISOString() },
        });
        console.log(`  ✓ ${agent.name}: active (gateway live)`);
      }
    }
  } catch (e) {
    console.log(`  Gateway unreachable: ${e.message}`);
  }
}

// ====== MAIN ======
async function main() {
  const start = Date.now();
  console.log(`\n${'='.repeat(50)}`);
  console.log(`🔄 Full Sync — ${new Date().toISOString()}`);
  console.log(`${'='.repeat(50)}`);

  try { await syncAgentStatus(); } catch (e) { console.log(`  Agent sync error: ${e.message}`); }
  try { await syncSessions(); } catch (e) { console.log(`  Session sync error: ${e.message}`); }
  try { await syncCrons(); } catch (e) { console.log(`  Cron sync error: ${e.message}`); }
  try { await syncMemoryFiles(); } catch (e) { console.log(`  Memory sync error: ${e.message}`); }
  try { await syncHeartbeats(); } catch (e) { console.log(`  Heartbeat sync error: ${e.message}`); }

  console.log(`\n✅ Sync complete in ${((Date.now() - start) / 1000).toFixed(1)}s`);
}

main().catch(e => console.error('Fatal:', e));

// ====== SKILLS SYNC ======
async function syncSkills() {
  console.log('\n🧩 Syncing skills...');
  const skillDirs = [
    { base: '/data/.openclaw/workspace/skills', source: 'workspace' },
    { base: '/data/.openclaw/skills', source: 'shared' },
  ];

  for (const { base, source } of skillDirs) {
    if (!fs.existsSync(base)) continue;
    const dirs = fs.readdirSync(base).filter(d => fs.statSync(path.join(base, d)).isDirectory());

    for (const dir of dirs) {
      const skillPath = path.join(base, dir);
      const skillMd = path.join(skillPath, 'SKILL.md');
      if (!fs.existsSync(skillMd)) continue;

      const content = fs.readFileSync(skillMd, 'utf-8');
      const descMatch = content.match(/description[:\s]*['""]?([^'""\n]+)/i);
      const allFiles = [];
      const walk = (d) => { fs.readdirSync(d).forEach(f => { const fp = path.join(d, f); fs.statSync(fp).isDirectory() ? walk(fp) : allFiles.push(fp); }); };
      walk(skillPath);

      await supaPost('skills', {
        name: dir,
        location: skillPath,
        description: descMatch ? descMatch[1].trim() : null,
        file_count: allFiles.length,
        has_scripts: fs.existsSync(path.join(skillPath, 'scripts')),
        has_references: fs.existsSync(path.join(skillPath, 'references')),
        source,
        last_modified: fs.statSync(skillMd).mtime.toISOString(),
      });
      console.log(`  ✓ ${dir} (${source}, ${allFiles.length} files)`);
    }
  }
}

// ====== CONFIG SYNC ======
async function syncConfig() {
  console.log('\n⚙️ Syncing config...');
  const configFile = '/data/.openclaw/openclaw.json';
  if (!fs.existsSync(configFile)) return;

  const config = JSON.parse(fs.readFileSync(configFile, 'utf-8'));

  // Sync key config sections (redact sensitive values)
  const sections = {
    'model': { primary: config.agents?.defaults?.model?.primary, fallbacks: config.agents?.defaults?.model?.fallbacks },
    'agents': config.agents?.list?.map(a => ({ id: a.id, name: a.name, model: a.model })),
    'channels': Object.keys(config.channels || {}).map(c => ({ channel: c, enabled: config.channels[c].enabled !== false })),
    'heartbeat': config.agents?.defaults?.heartbeat,
    'compaction': config.agents?.defaults?.compaction,
    'tools_profile': config.tools?.profile,
    'search_provider': config.tools?.web?.search?.provider,
  };

  for (const [key, value] of Object.entries(sections)) {
    if (value === undefined) continue;
    await supaPost('config_snapshots', { config_key: key, config_value: value });
    console.log(`  ✓ ${key}`);
  }
}

// ====== DEVICES SYNC ======
async function syncDevices() {
  console.log('\n📱 Syncing devices...');
  const pairedFile = '/data/.openclaw/devices/paired.json';
  if (!fs.existsSync(pairedFile)) return;

  const data = JSON.parse(fs.readFileSync(pairedFile, 'utf-8'));
  const devices = Array.isArray(data) ? data : data.devices || Object.values(data);

  for (const dev of devices) {
    if (typeof dev !== 'object') continue;
    await supaPost('devices', {
      device_id: dev.deviceId || dev.id || 'unknown',
      role: dev.role || 'user',
      status: 'paired',
      paired_at: dev.pairedAt || dev.createdAt,
      metadata: dev,
    });
    console.log(`  ✓ ${dev.deviceId || dev.id || 'device'}`);
  }
}

// ====== PROJECTS SYNC ======
async function syncLocalProjects() {
  console.log('\n📁 Syncing local projects...');
  const projectsDir = '/data/Projects';
  if (!fs.existsSync(projectsDir)) return;

  const dirs = fs.readdirSync(projectsDir).filter(d => fs.statSync(path.join(projectsDir, d)).isDirectory());
  for (const dir of dirs) {
    const projPath = path.join(projectsDir, dir);
    const pkgFile = path.join(projPath, 'package.json');
    let name = dir;
    if (fs.existsSync(pkgFile)) {
      try { name = JSON.parse(fs.readFileSync(pkgFile, 'utf-8')).name || dir; } catch {}
    }

    // Log as activity rather than overwriting projects table
    console.log(`  ✓ ${name} (${projPath})`);
  }
}

// Extend main to include new syncs
const _origMain = main;
main = async function() {
  await _origMain();
  try { await syncSkills(); } catch (e) { console.log(`  Skills sync error: ${e.message}`); }
  try { await syncConfig(); } catch (e) { console.log(`  Config sync error: ${e.message}`); }
  try { await syncDevices(); } catch (e) { console.log(`  Devices sync error: ${e.message}`); }
  try { await syncLocalProjects(); } catch (e) { console.log(`  Projects sync error: ${e.message}`); }
  console.log('\n🏁 All syncs complete');
};

main().catch(e => console.error('Fatal:', e));
