#!/usr/bin/env python3
"""
extract-agent-decisions.py
──────────────────────────
Extracts agent decisions, thinking, and inter-agent communication
from OpenClaw JSONL session transcripts.

Output: decisions.json in current directory

Usage:
  python3 extract-agent-decisions.py
  python3 extract-agent-decisions.py --agent forge
  python3 extract-agent-decisions.py --out /path/to/output.json
  python3 extract-agent-decisions.py --all          # include all messages, not just decisions
  python3 extract-agent-decisions.py --since 2026-04-01

Author: ClawExpert (COO) — 2026-04-05
"""

import json
import os
import sys
import argparse
from datetime import datetime, timezone
from pathlib import Path

# ─── Config ───────────────────────────────────────────────────────────────────

OPENCLAW_DIR = "/data/.openclaw"
AGENTS_DIR = os.path.join(OPENCLAW_DIR, "agents")

# Tools that represent inter-agent communication
AGENT_TO_AGENT_TOOLS = {
    "sessions_send",
    "sessions_spawn",
    "sessions_history",
    "sessions_list",
    "subagents",
}

# Tools that represent significant decisions (not just reads)
DECISION_TOOLS = {
    # Inter-agent
    "sessions_send",
    "sessions_spawn",
    # System changes
    "exec",
    "process",
    "cron",
    # File creation/edit (decisions materialised as files)
    "write",
    "edit",
    # Web (decision to research something)
    "web_search",
    "web_fetch",
    "image",
}

# Keywords in text that suggest a decision is being articulated
DECISION_KEYWORDS = [
    "decision", "decide", "decided", "choosing", "chose", "choice",
    "will ", "going to", "plan to", "planning to",
    "i'll ", "we'll ",
    "approved", "approve", "approve", "blocked", "block",
    "pass", "passed", "fail", "failed",
    "escalate", "escalating",
    "skip", "skipping",
    "priority", "critical", "urgent",
    "recommend", "recommending",
    "next step", "next action",
    "gate", "verdict", "conclusion",
    "should ", "must ", "need to",
]


# ─── Helpers ──────────────────────────────────────────────────────────────────

def ts_to_iso(ts):
    """Convert millisecond timestamp to ISO string."""
    if isinstance(ts, (int, float)) and ts > 1e12:
        return datetime.fromtimestamp(ts / 1000, tz=timezone.utc).isoformat()
    if isinstance(ts, str):
        return ts
    return None


def is_decision_text(text: str) -> bool:
    """Heuristic: does this text contain decision language?"""
    text_lower = text.lower()
    return any(kw in text_lower for kw in DECISION_KEYWORDS)


def extract_content_blocks(content):
    """
    Parse a content field (list or string) into typed blocks.
    Returns list of dicts with keys: type, text/name/args/result
    """
    blocks = []
    if isinstance(content, str):
        blocks.append({"type": "text", "text": content})
        return blocks

    if not isinstance(content, list):
        return blocks

    for item in content:
        if not isinstance(item, dict):
            continue

        ctype = item.get("type", "unknown")

        if ctype == "thinking":
            blocks.append({
                "type": "thinking",
                "text": item.get("thinking", ""),
            })
        elif ctype == "text":
            blocks.append({
                "type": "text",
                "text": item.get("text", ""),
            })
        elif ctype in ("tool_use", "toolCall"):
            name = item.get("name", "unknown")
            args = item.get("input", item.get("arguments", {}))
            blocks.append({
                "type": "tool_call",
                "name": name,
                "args": args,
                "is_agent_to_agent": name in AGENT_TO_AGENT_TOOLS,
                "is_decision_tool": name in DECISION_TOOLS,
            })
        elif ctype in ("tool_result", "toolResult"):
            raw = item.get("content", "")
            if isinstance(raw, list):
                result_text = " ".join(
                    r.get("text", "") for r in raw if isinstance(r, dict)
                )
            else:
                result_text = str(raw)
            blocks.append({
                "type": "tool_result",
                "tool_use_id": item.get("tool_use_id", item.get("toolUseId", "")),
                "result": result_text[:2000],  # cap at 2000 chars
            })

    return blocks


def parse_session_jsonl(path: str, agent_id: str, since_dt=None):
    """
    Parse a JSONL transcript file and return structured turns.
    """
    turns = []

    try:
        with open(path, "r") as f:
            lines = f.readlines()
    except Exception as e:
        return turns, f"read_error: {e}"

    session_meta = {}
    current_tool_names = {}  # id -> name for matching tool results

    for line in lines:
        line = line.strip()
        if not line:
            continue

        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue

        record_type = obj.get("type", "")
        ts = ts_to_iso(obj.get("timestamp"))

        # Filter by date
        if since_dt and ts:
            try:
                record_dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
                if record_dt < since_dt:
                    continue
            except Exception:
                pass

        # Session metadata
        if record_type == "session":
            session_meta = {
                "session_id": obj.get("id"),
                "version": obj.get("version"),
                "cwd": obj.get("cwd"),
                "started_at": ts,
            }
            continue

        # Skip non-message records
        if record_type != "message":
            continue

        msg = obj.get("message", {})
        if not msg:
            continue

        role = msg.get("role", "unknown")
        content = msg.get("content", [])
        usage = msg.get("usage", {})
        model = msg.get("model", "")
        stop_reason = msg.get("stopReason", "")
        msg_id = obj.get("id", "")
        seq = msg.get("__openclaw", {}).get("seq") if isinstance(msg.get("__openclaw"), dict) else None

        blocks = extract_content_blocks(content)

        # Track tool call names for matching results
        for b in blocks:
            if b["type"] == "tool_call":
                current_tool_names[b.get("name", "")] = b.get("name", "")

        # Classify this turn
        has_thinking = any(b["type"] == "thinking" for b in blocks)
        has_agent_to_agent = any(
            b["type"] == "tool_call" and b.get("is_agent_to_agent")
            for b in blocks
        )
        has_decision_tool = any(
            b["type"] == "tool_call" and b.get("is_decision_tool")
            for b in blocks
        )
        has_decision_text = any(
            b["type"] in ("text", "thinking") and is_decision_text(b.get("text", ""))
            for b in blocks
        )

        turn = {
            "agent": agent_id,
            "session_id": session_meta.get("session_id", ""),
            "turn_id": msg_id,
            "seq": seq,
            "timestamp": ts,
            "role": role,
            "model": model,
            "stop_reason": stop_reason,
            "content": blocks,
            "usage": {
                "input_tokens": usage.get("input", 0),
                "output_tokens": usage.get("output", 0),
                "cache_read": usage.get("cacheRead", 0),
                "cache_write": usage.get("cacheWrite", 0),
                "cost_usd": usage.get("cost", {}).get("total", 0) if isinstance(usage.get("cost"), dict) else 0,
            },
            "flags": {
                "has_thinking": has_thinking,
                "has_agent_to_agent": has_agent_to_agent,
                "has_decision_tool": has_decision_tool,
                "has_decision_text": has_decision_text,
                "is_decision_turn": has_thinking or has_agent_to_agent or has_decision_tool or has_decision_text,
            },
        }

        turns.append(turn)

    return turns, None


# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Extract agent decisions from OpenClaw session transcripts")
    parser.add_argument("--agent", help="Filter to specific agent (e.g. forge, pm, scout)")
    parser.add_argument("--out", default="decisions.json", help="Output JSON file path")
    parser.add_argument("--all", action="store_true", dest="all_turns", help="Include all turns (not just decisions)")
    parser.add_argument("--since", help="Only include turns after this date (YYYY-MM-DD)")
    parser.add_argument("--include-system", action="store_true", help="Include system/user messages (default: assistant only)")
    args = parser.parse_args()

    since_dt = None
    if args.since:
        try:
            since_dt = datetime.fromisoformat(args.since).replace(tzinfo=timezone.utc)
        except ValueError:
            print(f"Error: --since must be YYYY-MM-DD format, got: {args.since}")
            sys.exit(1)

    # Find all JSONL transcript files
    all_jsonl = []
    agents_dir = Path(AGENTS_DIR)

    if args.agent:
        agent_path = agents_dir / args.agent / "sessions"
        if agent_path.exists():
            for f in agent_path.glob("*.jsonl"):
                all_jsonl.append((args.agent, str(f)))
        else:
            print(f"No sessions dir found for agent: {args.agent}")
            sys.exit(1)
    else:
        for agent_dir in sorted(agents_dir.iterdir()):
            if not agent_dir.is_dir():
                continue
            agent_id = agent_dir.name
            sessions_dir = agent_dir / "sessions"
            if not sessions_dir.exists():
                continue
            for f in sorted(sessions_dir.glob("*.jsonl")):
                all_jsonl.append((agent_id, str(f)))

    print(f"Found {len(all_jsonl)} JSONL transcript file(s) across {len(set(a for a,_ in all_jsonl))} agent(s)")

    # Parse all files
    all_turns = []
    errors = []
    session_index = {}  # session_id -> agent + metadata

    for agent_id, path in all_jsonl:
        print(f"  Parsing: {agent_id}/{Path(path).name}")
        turns, err = parse_session_jsonl(path, agent_id, since_dt)
        if err:
            errors.append({"agent": agent_id, "file": path, "error": err})
        all_turns.extend(turns)

    # Filter to decision turns unless --all
    if not args.all_turns:
        decision_turns = [t for t in all_turns if t["flags"]["is_decision_turn"]]
    else:
        decision_turns = all_turns

    # Filter to assistant by default (skip system/user unless --include-system)
    if not args.include_system:
        decision_turns = [t for t in decision_turns if t["role"] == "assistant"]

    # Sort by timestamp
    decision_turns.sort(key=lambda t: t.get("timestamp") or "")

    # Build index of agent-to-agent interactions
    agent_to_agent = [
        t for t in decision_turns
        if t["flags"]["has_agent_to_agent"]
    ]

    # Build thinking inventory
    thinking_turns = [
        t for t in decision_turns
        if t["flags"]["has_thinking"]
    ]

    # Stats
    stats = {
        "total_transcripts_parsed": len(all_jsonl),
        "total_turns_found": len(all_turns),
        "decision_turns_extracted": len(decision_turns),
        "agent_to_agent_turns": len(agent_to_agent),
        "thinking_turns": len(thinking_turns),
        "agents_covered": sorted(set(t["agent"] for t in decision_turns)),
        "date_range": {
            "earliest": min((t["timestamp"] for t in decision_turns if t.get("timestamp")), default=None),
            "latest": max((t["timestamp"] for t in decision_turns if t.get("timestamp")), default=None),
        },
        "errors": errors,
    }

    # Final output
    output = {
        "meta": {
            "generated_at": datetime.now(tz=timezone.utc).isoformat(),
            "generated_by": "extract-agent-decisions.py (ClawExpert COO)",
            "openclaw_dir": OPENCLAW_DIR,
            "filters": {
                "agent": args.agent or "all",
                "since": args.since or None,
                "decisions_only": not args.all_turns,
                "assistant_only": not args.include_system,
            },
        },
        "stats": stats,
        "agent_to_agent": agent_to_agent,
        "thinking": thinking_turns,
        "decisions": decision_turns,
    }

    out_path = args.out
    with open(out_path, "w") as f:
        json.dump(output, f, indent=2, default=str)

    print()
    print(f"✅ Done!")
    print(f"   Total turns parsed:     {len(all_turns)}")
    print(f"   Decision turns:         {len(decision_turns)}")
    print(f"   Thinking turns:         {len(thinking_turns)}")
    print(f"   Agent-to-agent calls:   {len(agent_to_agent)}")
    print(f"   Agents covered:         {', '.join(stats['agents_covered'])}")
    print(f"   Output written to:      {out_path}")
    if errors:
        print(f"   ⚠️  Errors: {len(errors)} (see output.stats.errors)")


if __name__ == "__main__":
    main()
