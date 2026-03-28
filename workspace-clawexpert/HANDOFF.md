# HANDOFF.md — ClawExpert COO State

## Role
ClawExpert is the COO of the 14-agent fleet. This file tracks current operational state.

## Fleet Status (2026-03-29)
- **Agents**: 14 active (all healthy, all bound correctly in openclaw.json)
- **OpenClaw version**: 2026.3.24
- **Gateway**: Running (PID check with `pgrep -f openclaw-gateway`)
- **Config**: /data/.openclaw/openclaw.json (valid JSON, 14 agents + 14 bindings)
- **Git**: perlantir-fleet repo, all committed and pushed

## Agent Bindings (critical — missing binding = routes to Maks)
All 14 agents have explicit bindings in openclaw.json. The binding format is:
`{ "agentId": "ID", "match": { "channel": "telegram", "accountId": "ID" } }`
Verify with: `python3 -c "import json; c=json.load(open('/data/.openclaw/openclaw.json')); print(len(c.get('bindings',[])))"` (should be 14)

## Active Projects
- **Bouts**: Live at https://agent-arena-roan.vercel.app
  - Gate 3 PASSED (2026-03-28): 109 checks / 0 real failures
  - Launch package ready — awaiting Nick's go-signal
  - Blocker: Migration 00024 (Forge), Stripe keys (Nick), bouts.gg (Nick)
- **QA Fleet**: 4 agents deployed (Sentinel, Polish, Aegis, Relay) — awaiting first audit tasks
- **Paperclip VPS2**: Scoped — awaiting Nick to provision VPS2
- **Ballot agent**: Planned — calibration/learning feedback loop

## Cron Jobs Active
- fleet-git-commit (e1e68d15): 2 AM KL daily
- handoff-refresh (3924a862): Every 48h

## Known Issues
- Forge: Migration 00024 partial — challenge_bundles table needs re-run
- Nick pending: Stripe, Iowa address, bouts.gg, ORACLE_WALLET_ADDRESS, BASE_RPC_URL

## How to Update
After every significant session: update Fleet Status, Active Projects, Known Issues.
