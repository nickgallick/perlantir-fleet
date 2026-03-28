#!/usr/bin/env python3
"""
Submit both agent solutions to the Bouts platform and trigger judging.
"""

import json
import time
import requests

APP_URL = "https://agent-arena-roan.vercel.app"
SUPA_URL = "https://gojpbtlajzigvyfkghrg.supabase.co"
SUPA_SERVICE = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdvanBidGxhanppZ3Z5ZmtnaHJnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDEyMDg3NywiZXhwIjoyMDg5Njk2ODc3fQ.AnAmAz6_-seg_vkhJzq2MVQKKc4k5XcTgLvFOZ-wxp4"

SUPA_HEADERS = {
    "apikey": SUPA_SERVICE,
    "Authorization": f"Bearer {SUPA_SERVICE}",
    "Content-Type": "application/json",
    "Prefer": "return=representation",
}

def load_solution(path: str) -> str:
    with open(path) as f:
        return f.read()

def submit_entry(agent_name: str, api_key: str, entry_id: str, solution: str, model: str) -> dict:
    """Submit via the real connector API endpoint."""
    url = f"{APP_URL}/api/v1/submissions"
    headers = {
        "x-arena-api-key": api_key,
        "Content-Type": "application/json",
    }
    import time as _time
    payload = {
        "entry_id": entry_id,
        "submission_text": solution,
        "reported_model": model,
        "actual_mps": 88 if "sonnet" in model else 62,
        "transcript": [
            {
                "timestamp": int(_time.time() * 1000) - 60000,
                "type": "task",
                "title": "Challenge received",
                "content": "Debug the payment flow — identify all 7 bugs and provide a fixed implementation."
            },
            {
                "timestamp": int(_time.time() * 1000),
                "type": "output",
                "title": "Solution submitted",
                "content": solution[:500]
            }
        ]
    }
    
    r = requests.post(url, headers=headers, json=payload, timeout=30)
    print(f"[{agent_name}] Submit status: {r.status_code}")
    print(f"[{agent_name}] Response: {r.text[:300]}")
    return r.json() if r.ok else {"error": r.text, "status": r.status_code}


def trigger_judging(entry_id: str, challenge_id: str, agent_name: str):
    """Directly trigger all judge lanes via Supabase edge functions."""
    print(f"\n[{agent_name}] Triggering judges...")
    lanes = ["process", "strategy", "integrity"]
    results = {}
    
    for lane in lanes:
        r = requests.post(
            f"{SUPA_URL}/functions/v1/judge-entry",
            headers={
                "Authorization": f"Bearer {SUPA_SERVICE}",
                "Content-Type": "application/json",
            },
            json={
                "entry_id": entry_id,
                "challenge_id": challenge_id,
                "lane": lane,
            },
            timeout=60,
        )
        results[lane] = {"status": r.status_code, "ok": r.ok}
        print(f"  [{agent_name}] {lane} judge: {r.status_code}")
        if not r.ok:
            print(f"    Error: {r.text[:200]}")
    
    return results


def get_scores(entry_id: str, agent_name: str) -> dict:
    """Fetch judge scores from DB."""
    r = requests.get(
        f"{SUPA_URL}/rest/v1/judge_scores?entry_id=eq.{entry_id}&select=*",
        headers=SUPA_HEADERS,
        timeout=15,
    )
    scores = r.json() if r.ok else []
    print(f"\n[{agent_name}] Raw judge scores ({len(scores)} lanes):")
    for s in scores:
        lane = s.get("lane") or s.get("provider") or "unknown"
        score = s.get("score", "N/A")
        confidence = s.get("confidence", "N/A")
        rationale = s.get("short_rationale", "")[:100]
        print(f"  {lane}: {score}/100 (confidence: {confidence}) — {rationale}")
    return scores


def get_entry_final_score(entry_id: str, agent_name: str) -> dict:
    """Fetch the final composite score from challenge_entries."""
    r = requests.get(
        f"{SUPA_URL}/rest/v1/challenge_entries?id=eq.{entry_id}&select=id,status,final_score,rank,placement",
        headers=SUPA_HEADERS,
        timeout=15,
    )
    data = r.json()
    entry = data[0] if (isinstance(data, list) and data) else (data if isinstance(data, dict) else {})
    if entry:
        print(f"\n[{agent_name}] Final: status={entry.get('status')} score={entry.get('final_score')} rank={entry.get('rank')} placement={entry.get('placement')}")
    return entry


def main():
    with open("/data/.openclaw/workspace-forge/bouts-model-test/test-state.json") as f:
        state = json.load(f)

    challenge_id = state["challenge_id"]

    sonnet = state["sonnet"]
    haiku = state["haiku"]

    sonnet_sol = load_solution("/data/.openclaw/workspace-forge/bouts-model-test/sonnet-solution.txt")
    haiku_sol = load_solution("/data/.openclaw/workspace-forge/bouts-model-test/haiku-solution.txt")

    print("=" * 60)
    print("SUBMITTING SOLUTIONS")
    print("=" * 60)

    sonnet_result = submit_entry(
        "BoutsTest-Sonnet-46", sonnet["api_key"], sonnet["entry_id"], sonnet_sol, sonnet["model"]
    )
    time.sleep(1)
    haiku_result = submit_entry(
        "BoutsTest-Haiku-45", haiku["api_key"], haiku["entry_id"], haiku_sol, haiku["model"]
    )

    print("\n" + "=" * 60)
    print("WAITING FOR AUTO-JUDGING (30s)...")
    print("=" * 60)
    time.sleep(30)

    # Fetch scores
    print("\n" + "=" * 60)
    print("FETCHING SCORES")
    print("=" * 60)

    sonnet_scores = get_scores(sonnet["entry_id"], "Sonnet-46")
    haiku_scores = get_scores(haiku["entry_id"], "Haiku-45")

    sonnet_final = get_entry_final_score(sonnet["entry_id"], "Sonnet-46")
    haiku_final = get_entry_final_score(haiku["entry_id"], "Haiku-45")

    # Summary
    print("\n" + "=" * 60)
    print("COMPARISON SUMMARY")
    print("=" * 60)
    print(f"Sonnet 4.6 final score: {sonnet_final.get('final_score', 'pending')}")
    print(f"Haiku  4.5 final score: {haiku_final.get('final_score', 'pending')}")

    # Save results
    results = {
        "sonnet": {
            "submission": sonnet_result,
            "judge_scores": sonnet_scores,
            "final": sonnet_final,
        },
        "haiku": {
            "submission": haiku_result,
            "judge_scores": haiku_scores,
            "final": haiku_final,
        },
    }
    with open("/data/.openclaw/workspace-forge/bouts-model-test/results.json", "w") as f:
        json.dump(results, f, indent=2, default=str)

    print("\n[DONE] Results saved to results.json")


if __name__ == "__main__":
    main()
