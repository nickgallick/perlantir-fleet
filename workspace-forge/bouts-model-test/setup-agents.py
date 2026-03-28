#!/usr/bin/env python3
"""
Bouts Model Comparison Test — Setup
Creates two test agents (Sonnet and Haiku) and enters them into the payment challenge.
"""

import json
import hashlib
import secrets
import requests
import sys

SUPA_URL = "https://gojpbtlajzigvyfkghrg.supabase.co"
SUPA_SERVICE = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdvanBidGxhanppZ3Z5ZmtnaHJnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDEyMDg3NywiZXhwIjoyMDg5Njk2ODc3fQ.AnAmAz6_-seg_vkhJzq2MVQKKc4k5XcTgLvFOZ-wxp4"
QA_USER_ID = "e6e37b08-f0cc-4ced-b616-604fabb39bc2"
CHALLENGE_ID = "41f952c5-b302-406e-a75a-c5f7a63a8ea4"  # Debug the Payment Flow

HEADERS = {
    "apikey": SUPA_SERVICE,
    "Authorization": f"Bearer {SUPA_SERVICE}",
    "Content-Type": "application/json",
    "Prefer": "return=representation",
}


def make_api_key():
    raw = "aa_" + secrets.token_urlsafe(48)
    key_hash = hashlib.sha256(raw.encode()).hexdigest()
    prefix = raw[:8]
    return raw, key_hash, prefix


def upsert_agent(name: str, model_name: str, mps: int) -> tuple[str, str]:
    """Create or replace a test agent. Returns (agent_id, raw_api_key)."""
    raw_key, key_hash, prefix = make_api_key()

    # Delete any existing test agent with this name
    requests.delete(
        f"{SUPA_URL}/rest/v1/agents?name=eq.{name}",
        headers=HEADERS,
    )

    payload = {
        "user_id": QA_USER_ID,
        "name": name,
        "bio": f"Model comparison test agent — {model_name}",
        "model_name": model_name,
        "mps": mps,
        "weight_class_id": "frontier" if mps >= 85 else "scrapper",
        "weight_class": "open",
        "is_online": True,
        "is_npc": False,
        "api_key_hash": key_hash,
        "api_key_prefix": prefix,
        "tier": "bronze",
        "elo_rating": 1200,
        "elo_peak": 1200,
        "elo_floor": 800,
    }

    r = requests.post(f"{SUPA_URL}/rest/v1/agents", headers=HEADERS, json=payload)
    if r.status_code not in (200, 201):
        print(f"[ERROR] Create agent {name}: {r.status_code} {r.text}")
        sys.exit(1)

    agent = r.json()
    if isinstance(agent, list):
        agent = agent[0]
    agent_id = agent["id"]
    print(f"[OK] Agent '{name}' created: {agent_id}")
    return agent_id, raw_key


def create_entry(agent_id: str, agent_name: str) -> str:
    """Create a challenge_entry for the agent. Returns entry_id."""
    payload = {
        "agent_id": agent_id,
        "user_id": QA_USER_ID,
        "challenge_id": CHALLENGE_ID,
        "status": "assigned",
    }
    r = requests.post(f"{SUPA_URL}/rest/v1/challenge_entries", headers=HEADERS, json=payload)
    if r.status_code not in (200, 201):
        print(f"[ERROR] Create entry for {agent_name}: {r.status_code} {r.text}")
        sys.exit(1)

    entry = r.json()
    if isinstance(entry, list):
        entry = entry[0]
    entry_id = entry["id"]
    print(f"[OK] Entry for '{agent_name}': {entry_id}")
    return entry_id


def main():
    print("=== Setting up Bouts model comparison test ===\n")

    # Create Sonnet agent
    sonnet_id, sonnet_key = upsert_agent(
        name="BoutsTest-Sonnet-46",
        model_name="claude-sonnet-4-6",
        mps=88,
    )

    # Create Haiku agent
    haiku_id, haiku_key = upsert_agent(
        name="BoutsTest-Haiku-45",
        model_name="claude-haiku-4-5",
        mps=62,
    )

    # Create entries
    sonnet_entry = create_entry(sonnet_id, "BoutsTest-Sonnet-46")
    haiku_entry = create_entry(haiku_id, "BoutsTest-Haiku-45")

    # Save state for next steps
    state = {
        "challenge_id": CHALLENGE_ID,
        "sonnet": {
            "agent_id": sonnet_id,
            "agent_name": "BoutsTest-Sonnet-46",
            "model": "claude-sonnet-4-6",
            "api_key": sonnet_key,
            "entry_id": sonnet_entry,
        },
        "haiku": {
            "agent_id": haiku_id,
            "agent_name": "BoutsTest-Haiku-45",
            "model": "claude-haiku-4-5",
            "api_key": haiku_key,
            "entry_id": haiku_entry,
        },
    }

    with open("/data/.openclaw/workspace-forge/bouts-model-test/test-state.json", "w") as f:
        json.dump(state, f, indent=2)

    print("\n[DONE] State saved to test-state.json")
    print(f"  Sonnet entry_id: {sonnet_entry}")
    print(f"  Haiku  entry_id: {haiku_entry}")


if __name__ == "__main__":
    main()
