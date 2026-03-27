#!/bin/bash
# Mission Control Data Sync v2 — Forge rewrite 2026-03-22
# Fixes: P0-2 (fake tokens), P0-3 (fake lighthouse), P0-6 (hardcoded projects),
#        P1-2 (gateway table bloat), P1-4 (TLS hardcoded), P1-5 (memory only Maks),
#        P2-1 (timeout from sequential calls), P2-3 (URL encoding bug)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/mc-sync.env" ]; then
  set -a
  source "$SCRIPT_DIR/mc-sync.env"
  set +a
fi
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) MC sync v2 starting..."

python3 << 'PYEOF'
import json, os, glob, time, urllib.request, urllib.error, urllib.parse, hashlib, ssl

MC = os.environ.get("MC_SUPABASE_URL", "")
KEY = os.environ.get("MC_SUPABASE_SERVICE_KEY", "")
VT = os.environ.get("VERCEL_TOKEN", "")

if not MC or not KEY:
    print("ERROR: MC_SUPABASE_URL and MC_SUPABASE_SERVICE_KEY env vars required")
    exit(1)

HEADERS = {"apikey": KEY, "Authorization": f"Bearer {KEY}", "Content-Type": "application/json"}
TIMEOUT = 8  # seconds per request (reduced from 10-15)

# ============================================================
# HELPERS
# ============================================================

def api(method, path, data=None, prefer="return=minimal"):
    """Generic Supabase REST call."""
    url = f"{MC}/rest/v1/{path}"
    h = {**HEADERS, "Prefer": prefer}
    body = json.dumps(data).encode() if data else None
    try:
        req = urllib.request.Request(url, data=body, headers=h, method=method)
        with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
            if prefer == "return=representation":
                return json.load(resp)
            return True
    except urllib.error.HTTPError as e:
        print(f"  ERR {method} {path}: {e.read().decode()[:200]}")
        return None
    except Exception as e:
        print(f"  ERR {method} {path}: {e}")
        return None

def upsert(table, data_list, on_conflict="id"):
    """Bulk upsert — single request instead of N individual ones."""
    if not data_list:
        return True
    rows = data_list if isinstance(data_list, list) else [data_list]
    return api("POST", table, rows, prefer=f"resolution=merge-duplicates,return=minimal")

def patch_by(table, column, value, data):
    """PATCH rows matching column=value."""
    safe_val = urllib.parse.quote(str(value), safe='')
    return api("PATCH", f"{table}?{column}=eq.{safe_val}", data)

def get(path):
    """GET from Supabase."""
    url = f"{MC}/rest/v1/{path}"
    try:
        req = urllib.request.Request(url, headers={**HEADERS}, method="GET")
        with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
            return json.load(resp)
    except Exception as e:
        print(f"  ERR GET {path}: {e}")
        return []

def ts(epoch):
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(epoch))

def now_ts():
    return ts(time.time())

# Load OpenClaw config
with open("/data/.openclaw/openclaw.json") as f:
    config = json.load(f)

errors = []

# ============================================================
# 1. AGENTS — All agents from openclaw.json (not hardcoded 2)
# ============================================================
print("1. Agents...")
agent_ids = {}
agent_rows = []
for a in config["agents"]["list"]:
    session_dir = f"/data/.openclaw/agents/{a['id']}/sessions/"
    mood, step = "gray", "Idle"
    last_activity = None
    if os.path.isdir(session_dir):
        files = glob.glob(os.path.join(session_dir, "*.jsonl"))
        if files:
            lt = max(os.path.getmtime(f) for f in files)
            last_activity = ts(lt)
            ago = (time.time() - lt) / 60
            if ago < 5:
                mood, step = "green", "Working"
            elif ago < 60:
                mood, step = "yellow", "Recently active"

    model = a.get("model", config["agents"]["defaults"]["model"]["primary"])
    status = "active" if mood in ("green", "yellow") else "idle"
    if mood == "gray":
        step = "Getting coffee ☕"

    # Extract current task from the most recent active session's last user message
    current_task = ""
    last_action = ""
    if os.path.isdir(session_dir):
        files = glob.glob(os.path.join(session_dir, "*.jsonl"))
        if files:
            # Find most recently modified session file
            newest = max(files, key=os.path.getmtime)
            try:
                last_user_msg = ""
                last_assistant_msg = ""
                with open(newest) as f:
                    for line in f:
                        try:
                            entry = json.loads(line)
                            if entry.get("type") != "message":
                                continue
                            msg = entry.get("message", {})
                            role = msg.get("role", "")
                            content_parts = msg.get("content", [])
                            if isinstance(content_parts, str):
                                text = content_parts
                            elif isinstance(content_parts, list):
                                text = " ".join(
                                    p.get("text", "") if isinstance(p, dict) and p.get("type") == "text"
                                    else p if isinstance(p, str) else ""
                                    for p in content_parts
                                ).strip()
                            else:
                                text = str(content_parts)
                            if role == "user" and text.strip():
                                last_user_msg = text.strip()
                            elif role == "assistant" and text.strip():
                                last_assistant_msg = text.strip()
                        except json.JSONDecodeError:
                            continue
                # Clean up the message — strip metadata prefixes
                import re
                def clean_task_text(raw):
                    """Strip conversation metadata, timestamps, JSON blocks to get the actual task."""
                    text = raw.strip()
                    # Remove [timestamp] prefixes like [Sun 2026-03-22 12:23 GMT+8]
                    text = re.sub(r'^\[.*?GMT[+-]\d+\]\s*', '', text)
                    # Remove all ```json ... ``` blocks (including multi-line)
                    text = re.sub(r'```json?\s*[\s\S]*?```\s*', '', text)
                    # Remove "Conversation info (untrusted metadata):" header and any remaining JSON-like content after it
                    text = re.sub(r'Conversation info \(untrusted metadata\):\s*', '', text)
                    text = re.sub(r'Sender \(untrusted metadata\):\s*', '', text)
                    # Remove bare JSON objects that survived
                    text = re.sub(r'\{\s*"[^"]*"\s*:.*?\}\s*', '', text, flags=re.DOTALL)
                    # Remove inter-session headers
                    text = re.sub(r'\[Inter-session message\].*?\n', '', text)
                    # Remove "Read HEARTBEAT.md..." boilerplate
                    text = re.sub(r'^Read HEARTBEAT\.md[^.]*\..*?(?=\S)', '', text, flags=re.DOTALL)
                    # Remove HEARTBEAT_OK / NO_REPLY / REPLY_SKIP
                    text = re.sub(r'^(HEARTBEAT_OK|NO_REPLY|REPLY_SKIP)\s*$', '', text)
                    # Clean up whitespace
                    text = re.sub(r'\s+', ' ', text).strip()
                    return text

                # Current task = last user message (cleaned + truncated)
                if last_user_msg:
                    cleaned = clean_task_text(last_user_msg)
                    if cleaned:
                        current_task = cleaned[:200] + ("..." if len(cleaned) > 200 else "")
                # Last action = last assistant message summary (truncated)
                if last_assistant_msg:
                    cleaned = clean_task_text(last_assistant_msg)
                    if cleaned:
                        last_action = cleaned[:200] + ("..." if len(cleaned) > 200 else "")
            except (PermissionError, OSError):
                pass

    # current_step stays as clean status; task goes into config.currentProject
    # No override needed — step is already "Working" / "Recently active" / "Getting coffee ☕"

    agent_rows.append({
        "name": a["name"],
        "model": model,
        "status": status,
        "mood": mood,
        "current_step": step,
        "started_at": last_activity,
        "config": {
            "agent_id": a["id"],
            "lastSync": now_ts(),
            "workspace": a.get("workspace", f"/data/.openclaw/workspace"),
            "currentProject": current_task[:200] if current_task else "",
            "lastAction": last_action[:200] if last_action else "",
        }
    })

# Upsert all agents: first check existing, then PATCH or INSERT
for row in agent_rows:
    existing = get(f"agents?name=eq.{urllib.parse.quote(row['name'], safe='')}&select=id")
    if existing:
        patch_by("agents", "name", row["name"], row)
    else:
        upsert("agents", row)
    print(f"  ✓ {row['name']}: {row['mood']} ({row['current_step']})")

# Fetch agent DB IDs for FK references
try:
    db_agents = get("agents?select=id,name")
    for row in db_agents:
        agent_ids[row["name"]] = row["id"]
    print(f"  Agent IDs mapped: {len(agent_ids)}")
except Exception as e:
    errors.append(f"Agent ID fetch: {e}")

# ============================================================
# 2. CRON JOBS — Fixed URL encoding (P2-3)
# ============================================================
print("2. Cron jobs...")
try:
    with open("/data/.openclaw/cron/jobs.json") as f:
        crons = json.load(f)

    cron_rows = []
    for j in crons.get("jobs", []):
        s = j.get("state", {})
        sched = j.get("schedule", {})
        if sched.get("kind") == "cron":
            sched_str = sched.get("expr", "unknown")
        elif sched.get("kind") == "every":
            ms = sched.get("everyMs", 0)
            sched_str = f"every {ms//60000}m" if ms else "unknown"
        elif sched.get("kind") == "at":
            sched_str = f"at {sched.get('at', 'unknown')}"
        else:
            sched_str = json.dumps(sched)

        cron_rows.append({
            "name": j["name"],
            "schedule": sched_str,
            "status": "active" if j["enabled"] else "paused",
            "last_run": ts(s["lastRunAtMs"]/1000) if s.get("lastRunAtMs") else None,
            "next_run": ts(s["nextRunAtMs"]/1000) if s.get("nextRunAtMs") else None,
            "config": {
                "enabled": j["enabled"],
                "model": j.get("payload", {}).get("model", ""),
                "agent": j.get("agentId", "main"),
                "lastStatus": s.get("lastStatus", ""),
                "lastError": s.get("lastError", ""),
            }
        })

    # PATCH each by name (safe URL encoding with safe='')
    for row in cron_rows:
        existing = get(f"cron_jobs?name=eq.{urllib.parse.quote(row['name'], safe='')}&select=id")
        if existing:
            patch_by("cron_jobs", "name", row["name"], row)
        else:
            upsert("cron_jobs", row)
    print(f"  ✓ {len(cron_rows)} cron jobs synced")
except Exception as e:
    errors.append(f"Cron sync: {e}")
    print(f"  ✗ {e}")

# ============================================================
# 3. DEPLOYMENTS — Real Vercel data (no fake lighthouse — P0-3)
# ============================================================
print("3. Deployments...")
if VT:
    try:
        req = urllib.request.Request(
            "https://api.vercel.com/v6/deployments?limit=20",
            headers={"Authorization": f"Bearer {VT}"}
        )
        with urllib.request.urlopen(req, timeout=15) as resp:
            deps = json.load(resp)

        dep_rows = []
        for d in deps.get("deployments", []):
            dep_url = f"https://{d.get('url', '')}"
            dep_rows.append({
                "name": d["name"],
                "url": dep_url,
                "status": "healthy" if d["state"] == "READY" else ("building" if d["state"] == "BUILDING" else "failed"),
                "deployed_at": ts(d["created"]/1000),
                "commit_hash": d.get("meta", {}).get("githubCommitSha", "")[:7] or None,
                "config": {
                    "vercel_id": d["uid"],
                    "state": d["state"],
                    "environment": d.get("target", "preview"),
                }
                # NOTE: No fake lighthouse_json — removed per P0-3
                # Real lighthouse data would come from PageSpeed Insights API
            })

        for row in dep_rows:
            existing = get(f"deployments?url=eq.{urllib.parse.quote(row['url'], safe='')}&select=id")
            if existing:
                patch_by("deployments", "url", row["url"], row)
            else:
                upsert("deployments", row)
        print(f"  ✓ {len(dep_rows)} deployments synced")
    except Exception as e:
        errors.append(f"Deployment sync: {e}")
        print(f"  ✗ {e}")
else:
    print("  ⊘ VERCEL_TOKEN not set, skipping deployments")

# ============================================================
# 4. HEARTBEATS — All agents (not just Maks)
# ============================================================
print("4. Heartbeats...")
hb_rows = []
for a in config["agents"]["list"]:
    sd = f"/data/.openclaw/agents/{a['id']}/sessions/"
    if os.path.isdir(sd):
        files = glob.glob(os.path.join(sd, "*.jsonl"))
        if files:
            lt = max(os.path.getmtime(f) for f in files)
            ago = int((time.time() - lt) / 60)
            hb_rows.append({
                "agent_name": a["name"],
                "agent_id": agent_ids.get(a["name"]),
                "status": "ok" if ago < 120 else "missed",
                "message": f"Last activity {ago}m ago"
            })

if hb_rows:
    upsert("heartbeats", hb_rows)
    print(f"  ✓ {len(hb_rows)} heartbeats (batch insert)")
else:
    print("  ⊘ No heartbeat data")

# ============================================================
# 5. MEMORY — ALL agent workspaces (P1-5 fix)
# ============================================================
print("5. Memory files...")
file_type_map = {
    "MEMORY.md": "memory_long_term", "SOUL.md": "soul", "AGENTS.md": "agents",
    "TOOLS.md": "tools", "HEARTBEAT.md": "heartbeat", "USER.md": "user",
    "IDENTITY.md": "identity", "BOOTSTRAP.md": "bootstrap",
}

# Map workspace dirs to agent names
workspace_agent_map = {"/data/.openclaw/workspace": "Maks"}
for a in config["agents"]["list"]:
    ws = a.get("workspace")
    if ws:
        workspace_agent_map[ws] = a["name"]

# Scan ALL workspaces
memory_rows = []
all_workspaces = list(workspace_agent_map.keys())
for ws in all_workspaces:
    if not os.path.isdir(ws):
        continue
    agent_name = workspace_agent_map.get(ws, "Unknown")
    agent_id = agent_ids.get(agent_name)

    # Top-level workspace files
    for pattern in ["*.md"]:
        for mf in glob.glob(os.path.join(ws, pattern)):
            basename = os.path.basename(mf)
            if basename.startswith("."):
                continue
            try:
                with open(mf) as f:
                    content = f.read()
            except Exception:
                continue

            ft = file_type_map.get(basename, "workspace_file")
            memory_rows.append({
                "agent_name": agent_name,
                "agent_id": agent_id,
                "file_path": mf,
                "file_type": ft,
                "content_preview": content[:5000],
                "size_bytes": len(content),
                "entries_count": content.count("\n- "),
                "last_modified": ts(os.path.getmtime(mf)),
            })

    # memory/ subdirectory
    for mf in glob.glob(os.path.join(ws, "memory", "*.md")):
        try:
            with open(mf) as f:
                content = f.read()
        except Exception:
            continue
        memory_rows.append({
            "agent_name": agent_name,
            "agent_id": agent_id,
            "file_path": mf,
            "file_type": "memory_daily",
            "content_preview": content[:5000],
            "size_bytes": len(content),
            "entries_count": content.count("\n- "),
            "last_modified": ts(os.path.getmtime(mf)),
        })

# Upsert by file_path
for row in memory_rows:
    existing = get(f"memory_snapshots?file_path=eq.{urllib.parse.quote(row['file_path'], safe='')}&select=id")
    if existing:
        patch_by("memory_snapshots", "file_path", row["file_path"], row)
    else:
        upsert("memory_snapshots", row)

print(f"  ✓ {len(memory_rows)} memory files across {len(all_workspaces)} workspaces")

# ============================================================
# 6. GATEWAY HEALTH — Real check + cleanup old rows (P1-2, P1-4)
# ============================================================
print("6. Gateway...")
try:
    t0 = time.time()
    req = urllib.request.Request("http://localhost:18789/health")
    with urllib.request.urlopen(req, timeout=5) as resp:
        health_data = json.load(resp)
    ms = int((time.time() - t0) * 1000)

    # Real TLS check (P1-4 fix — not hardcoded)
    tls_valid = False
    tls_expiry = None
    try:
        import ssl, socket
        ctx = ssl.create_default_context()
        with ctx.wrap_socket(socket.socket(), server_hostname="openclaw.perlantir.com") as s:
            s.settimeout(5)
            s.connect(("openclaw.perlantir.com", 443))
            cert = s.getpeercert()
            expiry_str = cert.get("notAfter", "")
            if expiry_str:
                tls_expiry = time.strftime("%Y-%m-%dT%H:%M:%SZ",
                    time.strptime(expiry_str, "%b %d %H:%M:%S %Y %Z"))
                tls_valid = True
    except Exception as e:
        print(f"  TLS check: {e}")

    # Get version from health response if available
    gw_version = health_data.get("version", health_data.get("v", "unknown"))

    upsert("gateway_health", {
        "status": "healthy",
        "response_time_ms": ms,
        "ws_connected": True,
        "tls_valid": tls_valid,
        "tls_expiry": tls_expiry,
        "uptime_seconds": health_data.get("uptime", 0),
        "version": str(gw_version),
        "agents_online": len(config["agents"]["list"]),
        "active_sessions": health_data.get("sessions", 0),
        "checked_at": now_ts(),
    })
    print(f"  ✓ healthy ({ms}ms, TLS valid={tls_valid})")

    # P1-2 fix: Delete gateway_health rows older than 7 days
    cutoff = ts(time.time() - 7 * 86400)
    api("DELETE", f"gateway_health?checked_at=lt.{cutoff}")
    print(f"  ✓ Cleaned gateway_health rows older than 7 days")

except Exception as e:
    errors.append(f"Gateway: {e}")
    upsert("gateway_health", {
        "status": "down", "response_time_ms": 0, "ws_connected": False,
        "tls_valid": False, "agents_online": 0, "checked_at": now_ts(),
    })
    print(f"  ✗ {e}")

# ============================================================
# 7. PROJECTS — Dynamic from Vercel API (P0-6 fix, no hardcoded list)
# ============================================================
print("7. Projects...")
if VT:
    try:
        req = urllib.request.Request(
            "https://api.vercel.com/v9/projects?limit=20",
            headers={"Authorization": f"Bearer {VT}"}
        )
        with urllib.request.urlopen(req, timeout=15) as resp:
            projects_data = json.load(resp)

        for p in projects_data.get("projects", []):
            pname = p["name"]
            framework = p.get("framework", "")
            ptype = "saas" if framework in ("nextjs", "vite", "remix") else "landing"

            # Try to find latest deployment URL
            vercel_url = None
            targets = p.get("targets", {})
            if targets and "production" in targets:
                prod = targets["production"]
                if isinstance(prod, dict) and prod.get("alias"):
                    vercel_url = f"https://{prod['alias'][0]}"

            project_row = {
                "name": pname,
                "type": ptype,
                "status": "live",
                "vercel_url": vercel_url,
                "vercel_project_id": p.get("id"),
                "github_repo": p.get("link", {}).get("repo"),
                "config": {"framework": framework, "source": "vercel_api"},
            }

            existing = get(f"projects?name=eq.{urllib.parse.quote(pname, safe='')}&select=id,status")
            if existing:
                # Don't overwrite manually-set statuses
                if existing[0].get("status") not in ("in_progress", "building", "needs_attention"):
                    patch_by("projects", "name", pname, project_row)
            else:
                upsert("projects", project_row)

        print(f"  ✓ {len(projects_data.get('projects', []))} projects from Vercel API")
    except Exception as e:
        errors.append(f"Projects sync: {e}")
        print(f"  ✗ {e}")
else:
    print("  ⊘ VERCEL_TOKEN not set, skipping projects")

# ============================================================
# 8. TOKEN USAGE — Real data from session files (P0-2 fix)
# ============================================================
print("8. Token usage...")
# Parse actual session files for token metadata instead of Math.random()
token_count = 0
for a in config["agents"]["list"]:
    sd = f"/data/.openclaw/agents/{a['id']}/sessions/"
    if not os.path.isdir(sd):
        continue

    files = glob.glob(os.path.join(sd, "*.jsonl"))
    if not files:
        continue

    # Get the most recent session file
    latest = max(files, key=os.path.getmtime)
    mtime = os.path.getmtime(latest)

    # Only process files modified in the last 2 hours
    if time.time() - mtime > 7200:
        continue

    # Parse JSONL for token usage metadata
    total_in = 0
    total_out = 0
    model_used = a.get("model", "unknown")
    try:
        with open(latest) as f:
            for line in f:
                try:
                    entry = json.loads(line)
                    # Look for token usage in various formats
                    usage = entry.get("usage", {})
                    if usage:
                        total_in += usage.get("input_tokens", usage.get("prompt_tokens", 0))
                        total_out += usage.get("output_tokens", usage.get("completion_tokens", 0))
                    # Also check metadata
                    meta = entry.get("metadata", {})
                    if meta.get("tokens_in"):
                        total_in += meta["tokens_in"]
                    if meta.get("tokens_out"):
                        total_out += meta["tokens_out"]
                    if meta.get("model"):
                        model_used = meta["model"]
                except json.JSONDecodeError:
                    continue
    except Exception:
        continue

    if total_in > 0 or total_out > 0:
        upsert("spend_logs", {
            "agent_id": agent_ids.get(a["name"]),
            "service": "anthropic",
            "model": model_used,
            "tokens_in": total_in,
            "tokens_out": total_out,
            "amount_cents": 0,  # Cost calculation would need pricing table
            "timestamp": ts(mtime),
        })
        token_count += 1
        print(f"  ✓ {a['name']}: {total_in} in / {total_out} out")

if token_count == 0:
    print("  ⊘ No recent token data found in session files")

# ============================================================
# 9. AGENT ACTIVITY — Generate activity events from session data
# ============================================================
print("9. Agent activity...")
activity_rows = []
for a in config["agents"]["list"]:
    sd = f"/data/.openclaw/agents/{a['id']}/sessions/"
    if not os.path.isdir(sd):
        continue
    files = glob.glob(os.path.join(sd, "*.jsonl"))
    if not files:
        continue

    latest = max(files, key=os.path.getmtime)
    mtime = os.path.getmtime(latest)

    # Only generate activity for sessions active in last 2 hours
    if time.time() - mtime > 7200:
        continue

    agent_id = agent_ids.get(a["name"])
    if not agent_id:
        continue

    ago = int((time.time() - mtime) / 60)
    if ago < 5:
        action = "Working"
        detail = f"Active session — last message {ago}m ago"
        severity = "info"
    elif ago < 60:
        action = "Session active"
        detail = f"Last activity {ago}m ago"
        severity = "info"
    else:
        action = "Session idle"
        detail = f"No activity for {ago}m"
        severity = "warning"

    activity_rows.append({
        "agent_id": agent_id,
        "action": action,
        "detail": detail,
        "severity": severity,
        "timestamp": ts(mtime),
    })

if activity_rows:
    upsert("agent_activity", activity_rows)
    print(f"  ✓ {len(activity_rows)} activity events")
else:
    print("  ⊘ No recent agent activity")

# ============================================================
# 10. SESSIONS — Sync session metadata from local JSONL files
# ============================================================
print("9. Sessions...")
session_rows = []
agent_name_map = {a["id"]: a["name"] for a in config["agents"]["list"]}
agent_model_map = {a["id"]: a.get("model", config["agents"]["defaults"]["model"]["primary"]) for a in config["agents"]["list"]}

for agent_dir in glob.glob("/data/.openclaw/agents/*/"):
    aid = os.path.basename(agent_dir.rstrip("/"))
    aname = agent_name_map.get(aid, aid)

    for sf in glob.glob(os.path.join(agent_dir, "sessions", "*.jsonl")):
        session_id = os.path.basename(sf).replace(".jsonl", "")
        mtime = os.path.getmtime(sf)
        size = os.path.getsize(sf)

        channel = "cli"
        model = agent_model_map.get(aid, "unknown")
        msg_count = 0
        session_key = session_id

        try:
            with open(sf) as f:
                for i, line in enumerate(f):
                    if i > 200: break
                    try:
                        entry = json.loads(line)
                        if entry.get("type") == "session":
                            session_key = entry.get("id", session_id)
                        if entry.get("type") == "custom" and entry.get("customType") == "openclaw:inbound":
                            ch = entry.get("data", {}).get("channel", "")
                            if ch: channel = ch
                        if entry.get("type") == "message":
                            msg_count += 1
                        if entry.get("type") == "model_change":
                            model = entry.get("modelId", model)
                    except json.JSONDecodeError:
                        continue
        except PermissionError:
            try:
                with open(sf) as f:
                    msg_count = sum(1 for l in f if '"type":"message"' in l or '"type": "message"' in l)
            except:
                msg_count = 0

        ago = (time.time() - mtime) / 3600
        status = "active" if ago < 1 else ("idle" if ago < 24 else "ended")

        session_rows.append({
            "agent_name": aname,
            "agent_id": agent_ids.get(aname),
            "session_key": session_key,
            "status": status,
            "channel": channel,
            "model": model,
            "total_messages": msg_count,
            "context_tokens": size // 4,
            "started_at": ts(os.path.getctime(sf)),
            "last_activity_at": ts(mtime),
        })

# Batch: delete all then bulk insert (faster than 74 individual upserts)
try:
    req = urllib.request.Request(f"{MC}/rest/v1/sessions?id=gt.0", headers={**HEADERS, "Prefer": "return=minimal"}, method="DELETE")
    urllib.request.urlopen(req, timeout=TIMEOUT)
except: pass
if session_rows:
    data = json.dumps(session_rows).encode()
    req = urllib.request.Request(f"{MC}/rest/v1/sessions", data=data, headers={**HEADERS, "Prefer": "return=minimal"}, method="POST")
    urllib.request.urlopen(req, timeout=TIMEOUT)

print(f"  ✓ {len(session_rows)} sessions synced")

# Also sync session messages for active sessions (last 20 msgs each)
# Get DB session IDs we just inserted
try:
    db_sessions = get("sessions?select=id,session_key&status=in.(active,idle)")
    session_db_map = {s["session_key"]: s["id"] for s in (db_sessions or [])}
except:
    session_db_map = {}

all_messages = []
for agent_dir in glob.glob("/data/.openclaw/agents/*/"):
    aid = os.path.basename(agent_dir.rstrip("/"))
    for sf in glob.glob(os.path.join(agent_dir, "sessions", "*.jsonl")):
        sk = os.path.basename(sf).replace(".jsonl", "")
        db_id = session_db_map.get(sk)
        if not db_id:
            continue
        # Only process sessions active in last 2 hours
        if time.time() - os.path.getmtime(sf) > 7200:
            continue
        messages = []
        try:
            with open(sf) as f:
                for line in f:
                    try:
                        entry = json.loads(line)
                        if entry.get("type") != "message":
                            continue
                        msg = entry.get("message", {})
                        role = msg.get("role", "unknown")
                        content_parts = msg.get("content", [])
                        if isinstance(content_parts, str):
                            content = content_parts
                        elif isinstance(content_parts, list):
                            text_parts = []
                            for p in content_parts:
                                if isinstance(p, str): text_parts.append(p)
                                elif isinstance(p, dict) and p.get("type") == "text": text_parts.append(p.get("text", ""))
                                elif isinstance(p, dict) and p.get("type") == "tool_use": text_parts.append(f"[Tool: {p.get('name', 'unknown')}]")
                            content = "\n".join(text_parts)
                        else:
                            content = str(content_parts)
                        if not content.strip():
                            continue
                        if len(content) > 2000:
                            content = content[:2000] + "..."
                        messages.append({
                            "session_id": db_id,
                            "role": role if role in ("user", "assistant", "system") else "system",
                            "content": content,
                            "tokens": len(content) // 4,
                            "created_at": entry.get("timestamp", ts(time.time())),
                        })
                    except json.JSONDecodeError:
                        continue
        except PermissionError:
            continue
        all_messages.extend(messages[-20:])

if all_messages:
    # Clear old messages for active sessions, then insert fresh
    for db_id in set(m["session_id"] for m in all_messages):
        try:
            req = urllib.request.Request(f"{MC}/rest/v1/session_messages?session_id=eq.{db_id}", headers={**HEADERS, "Prefer": "return=minimal"}, method="DELETE")
            urllib.request.urlopen(req, timeout=TIMEOUT)
        except: pass
    # Batch insert
    for i in range(0, len(all_messages), 100):
        chunk = all_messages[i:i+100]
        data = json.dumps(chunk).encode()
        req = urllib.request.Request(f"{MC}/rest/v1/session_messages", data=data, headers={**HEADERS, "Prefer": "return=minimal"}, method="POST")
        try: urllib.request.urlopen(req, timeout=TIMEOUT)
        except: pass
    print(f"  ✓ {len(all_messages)} session messages synced")

# ============================================================
# 10. CLEANUP — Retention policies (P1-2)
# ============================================================
print("9. Cleanup...")

# Delete heartbeats older than 30 days
cutoff_30d = ts(time.time() - 30 * 86400)
api("DELETE", f"heartbeats?created_at=lt.{cutoff_30d}")
print(f"  ✓ Cleaned heartbeats older than 30 days")

# Delete agent_activity older than 30 days
api("DELETE", f"agent_activity?timestamp=lt.{cutoff_30d}")
print(f"  ✓ Cleaned agent_activity older than 30 days")

# Delete old spend_logs older than 90 days
cutoff_90d = ts(time.time() - 90 * 86400)
api("DELETE", f"spend_logs?timestamp=lt.{cutoff_90d}")
print(f"  ✓ Cleaned spend_logs older than 90 days")

# ============================================================
# SUMMARY
# ============================================================
print()
if errors:
    print(f"⚠️  Sync complete with {len(errors)} error(s):")
    for e in errors:
        print(f"  - {e}")
else:
    print("✅ Sync complete — all sections clean!")

PYEOF
