#!/usr/bin/env node
/**
 * Sync OpenClaw session transcripts to Supabase for Mission Control
 * Reads JSONL session files and pushes to sessions + session_messages tables
 * Run via OpenClaw cron or manually: node scripts/sync-sessions.js
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

const SUPABASE_URL = 'https://zjcgoeivuwkrpqezyhqg.supabase.co';
const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpqY2dvZWl2dXdrcnBxZXp5aHFnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MzY5NjA0OCwiZXhwIjoyMDg5MjcyMDQ4fQ.OTKTHrLUtVjAJsTVGsrv3h0AA0wEpeo4uaMjqESMRD4';

const AGENTS = [
  { name: 'Maks', role: 'main', sessionsDir: '/data/.openclaw/agents/main/sessions' },
  { name: 'MaksPM', role: 'pm', sessionsDir: '/data/.openclaw/agents/pm/sessions' },
];

async function supabaseRequest(method, table, body, query = '') {
  const url = new URL(`/rest/v1/${table}${query}`, SUPABASE_URL);
  const options = {
    method,
    headers: {
      'apikey': SUPABASE_SERVICE_KEY,
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      'Content-Type': 'application/json',
      'Prefer': method === 'POST' ? 'resolution=merge-duplicates,return=minimal' : 'return=minimal',
    },
  };

  return new Promise((resolve, reject) => {
    const req = https.request(url, options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(data ? JSON.parse(data) : null);
        } else {
          reject(new Error(`${res.statusCode}: ${data}`));
        }
      });
    });
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

function parseSessionFile(filePath) {
  const lines = fs.readFileSync(filePath, 'utf-8').trim().split('\n');
  const messages = [];
  let sessionMeta = null;
  let model = null;

  for (const line of lines) {
    try {
      const entry = JSON.parse(line);
      
      if (entry.type === 'session') {
        sessionMeta = entry;
      } else if (entry.type === 'model_change') {
        model = entry.modelId;
      } else if (entry.type === 'message' && entry.message) {
        const msg = entry.message;
        let text = '';
        let tokens = 0;

        if (Array.isArray(msg.content)) {
          text = msg.content
            .filter(c => c.type === 'text')
            .map(c => c.text)
            .join('\n');
        } else if (typeof msg.content === 'string') {
          text = msg.content;
        }

        // Skip empty messages and system/metadata messages
        if (!text || text.length < 2) continue;
        
        // Clean up user messages — strip metadata headers
        if (msg.role === 'user') {
          const match = text.match(/(?:^|\n)(?!Conversation info|Sender|System:|```json)(.+)/s);
          if (match) {
            // Find actual user content after metadata blocks
            const parts = text.split('\n\n');
            const userContent = parts.filter(p => 
              !p.startsWith('Conversation info') && 
              !p.startsWith('Sender') && 
              !p.startsWith('```json') &&
              !p.startsWith('System:') &&
              !p.includes('"message_id"') &&
              !p.includes('"sender_id"')
            ).join('\n\n').trim();
            if (userContent) text = userContent;
          }
        }

        // Skip if still empty after cleaning
        if (!text.trim()) continue;
        // Truncate very long messages for DB storage
        if (text.length > 10000) text = text.substring(0, 10000) + '... [truncated]';

        if (msg.usage) {
          tokens = (msg.usage.input || 0) + (msg.usage.output || 0);
        }

        messages.push({
          role: msg.role === 'user' ? 'user' : msg.role === 'assistant' ? 'assistant' : 'system',
          content: text,
          tokens,
          created_at: entry.timestamp,
        });
      }
    } catch (e) {
      // Skip malformed lines
    }
  }

  return { sessionMeta, model, messages };
}

async function getAgentId(agentName) {
  const url = new URL(`/rest/v1/agents?name=eq.${encodeURIComponent(agentName)}&select=id`, SUPABASE_URL);
  const options = {
    headers: {
      'apikey': SUPABASE_SERVICE_KEY,
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
    },
  };

  return new Promise((resolve, reject) => {
    https.get(url, options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        const results = JSON.parse(data);
        resolve(results[0]?.id || null);
      });
    }).on('error', reject);
  });
}

async function syncAgent(agent) {
  console.log(`\nSyncing ${agent.name}...`);
  
  const agentId = await getAgentId(agent.name);
  if (!agentId) {
    console.log(`  Agent ${agent.name} not found in DB, skipping`);
    return;
  }

  const sessionsDir = agent.sessionsDir;
  if (!fs.existsSync(sessionsDir)) {
    console.log(`  Sessions dir not found: ${sessionsDir}`);
    return;
  }

  const files = fs.readdirSync(sessionsDir)
    .filter(f => f.endsWith('.jsonl') && !f.endsWith('.lock'));

  console.log(`  Found ${files.length} session files`);

  for (const file of files) {
    const filePath = path.join(sessionsDir, file);
    const sessionId = file.replace('.jsonl', '');
    
    console.log(`  Processing ${sessionId}...`);
    
    const { sessionMeta, model, messages } = parseSessionFile(filePath);
    if (messages.length === 0) {
      console.log(`    No messages, skipping`);
      continue;
    }

    const stats = fs.statSync(filePath);
    const firstMsg = messages[0];
    const lastMsg = messages[messages.length - 1];
    const totalTokens = messages.reduce((sum, m) => sum + m.tokens, 0);

    // Upsert session
    const sessionData = {
      id: sessionId,
      agent_id: agentId,
      agent_name: agent.name,
      session_key: `agent:${agent.role}:telegram`,
      status: 'active',
      channel: 'telegram',
      model: model || 'unknown',
      context_tokens: totalTokens,
      max_context_tokens: 1000000,
      total_messages: messages.length,
      started_at: firstMsg.created_at,
      last_activity_at: lastMsg.created_at,
    };

    try {
      await supabaseRequest('POST', 'sessions', sessionData);
      console.log(`    Session upserted: ${messages.length} messages, ${totalTokens} tokens`);
    } catch (e) {
      console.log(`    Session upsert failed: ${e.message}`);
      continue;
    }

    // Delete existing messages for this session and re-insert latest
    try {
      await supabaseRequest('DELETE', 'session_messages', null, `?session_id=eq.${sessionId}`);
    } catch (e) {
      // OK if nothing to delete
    }

    // Insert messages in batches of 50 (only last 100 messages to keep it manageable)
    const recentMessages = messages.slice(-100);
    const batches = [];
    for (let i = 0; i < recentMessages.length; i += 50) {
      batches.push(recentMessages.slice(i, i + 50));
    }

    for (const batch of batches) {
      const rows = batch.map(m => ({
        session_id: sessionId,
        role: m.role,
        content: m.content,
        tokens: m.tokens,
        created_at: m.created_at,
      }));

      try {
        await supabaseRequest('POST', 'session_messages', rows);
      } catch (e) {
        console.log(`    Message batch insert failed: ${e.message}`);
      }
    }

    console.log(`    Synced ${recentMessages.length} recent messages`);
  }
}

async function main() {
  console.log('=== Session Sync Starting ===');
  console.log(`Time: ${new Date().toISOString()}`);

  for (const agent of AGENTS) {
    await syncAgent(agent);
  }

  console.log('\n=== Session Sync Complete ===');
}

main().catch(e => {
  console.error('Sync failed:', e);
  process.exit(1);
});
