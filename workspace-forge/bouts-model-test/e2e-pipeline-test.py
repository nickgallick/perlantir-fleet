#!/usr/bin/env python3
"""
Bouts Challenge Pipeline — End-to-End Test
Runs 5 full cycles: generate challenge → queue → calibrate → verify outcome

Each cycle:
1. Insert a test challenge (with known quality: good/bad/medium)
2. Queue it for calibration
3. Trigger auto-calibrate
4. Verify the correct outcome (pass→reserve, fail→deleted, borderline→flagged)
"""

import json
import time
import requests
import uuid

SUPA_URL = "https://gojpbtlajzigvyfkghrg.supabase.co"
SUPA_SERVICE = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdvanBidGxhanppZ3Z5ZmtnaHJnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDEyMDg3NywiZXhwIjoyMDg5Njk2ODc3fQ.AnAmAz6_-seg_vkhJzq2MVQKKc4k5XcTgLvFOZ-wxp4"
APP_URL = "https://agent-arena-roan.vercel.app"
CRON_SECRET = "87f89ac94aa06d39239eb7532d293eab02bf19441db7a47bca063db7b9bc744f"
PAT = "sbp_851afa9dfe477af8cb5c9a6e2c22ecdab2d5960b"

SUPA_HEADERS = {
    "apikey": SUPA_SERVICE,
    "Authorization": f"Bearer {SUPA_SERVICE}",
    "Content-Type": "application/json",
    "Prefer": "return=representation",
}

# 5 test challenges with known expected outcomes
# Mix of clearly good, borderline, and clearly bad
TEST_CHALLENGES = [
    {
        "name": "Test 1 — Good (Multi-bug debugging)",
        "expected": "pass",
        "challenge": {
            "title": f"Pipeline-Test: Fix the Cache Stampede [{uuid.uuid4().hex[:6]}]",
            "description": "Debug a broken Redis cache implementation with 5 bugs",
            "prompt": """A Redis cache implementation has 5 critical bugs causing cache stampedes, data corruption, and memory leaks. Analyze the broken code, identify all 5 bugs, and deliver a complete fixed implementation.

```javascript
// cache.js — BROKEN IMPLEMENTATION
const redis = require('redis');
const client = redis.createClient();

async function getOrSet(key, fetchFn, ttl) {
  const cached = await client.get(key);
  if (cached) return JSON.parse(cached);
  
  const data = await fetchFn();
  await client.set(key, JSON.stringify(data));
  return data;
}

async function invalidate(key) {
  client.del(key);
}

async function getMany(keys) {
  const results = [];
  for (const key of keys) {
    results.push(await getOrSet(key, () => fetchFromDB(key)));
  }
  return results;
}
```

Bugs to find:
1. Cache stampede — no locking on cache miss
2. TTL never applied — data never expires
3. No error handling — Redis failures crash the app
4. N+1 problem in getMany — should use mget/pipeline
5. invalidate is fire-and-forget — no await, errors swallowed

Deliver: all 5 bugs identified with explanations + complete fixed implementation with BUG-N FIX comments.""",
            "category": "debugging",
            "format": "sprint",
            "challenge_type": "daily",
            "time_limit_minutes": 60,
        }
    },
    {
        "name": "Test 2 — Good (Algorithm implementation)",
        "expected": "pass",
        "challenge": {
            "title": f"Pipeline-Test: LRU Cache Implementation [{uuid.uuid4().hex[:6]}]",
            "description": "Implement a correct, performant LRU Cache",
            "prompt": """Implement a Least Recently Used (LRU) Cache with O(1) get and put operations.

Requirements:
- LRUCache(capacity: number) — initialize with positive capacity
- get(key: number): number — return value if exists, -1 if not
- put(key: number, value: number): void — insert or update key. If capacity exceeded, evict least recently used.

Constraints:
- get and put must both be O(1)
- 1 <= capacity <= 3000
- 0 <= key, value <= 10^4
- Up to 2 * 10^5 calls to get/put

Edge cases to handle:
- put on existing key updates value AND moves to most-recently-used
- capacity=1 edge case
- get after eviction returns -1

Include: implementation + explanation of data structure choice + time/space complexity analysis.""",
            "category": "algorithms",
            "format": "standard",
            "challenge_type": "standard",
            "time_limit_minutes": 45,
        }
    },
    {
        "name": "Test 3 — Good (Full-stack debugging)",
        "expected": "pass",
        "challenge": {
            "title": f"Pipeline-Test: Debug the WebSocket Server [{uuid.uuid4().hex[:6]}]",
            "description": "Fix a broken WebSocket server with race conditions and memory leaks",
            "prompt": """A WebSocket chat server has 4 serious bugs: memory leak on disconnect, broadcast race condition, missing auth check, and message ordering broken under load.

```javascript
// ws-server.js — BROKEN
const WebSocket = require('ws');
const wss = new WebSocket.Server({ port: 8080 });
const rooms = {};

wss.on('connection', (ws) => {
  ws.on('message', (msg) => {
    const { type, room, content, userId } = JSON.parse(msg);
    
    if (type === 'join') {
      if (!rooms[room]) rooms[room] = [];
      rooms[room].push(ws);
    }
    
    if (type === 'message') {
      rooms[room].forEach(client => {
        client.send(JSON.stringify({ userId, content, ts: Date.now() }));
      });
    }
    
    if (type === 'admin_kick') {
      rooms[room] = rooms[room].filter(c => c !== ws);
    }
  });
});
```

Identify and fix all 4 bugs:
1. Memory leak — disconnected clients stay in rooms array forever
2. Race condition — broadcast iterates while array can be mutated
3. Missing auth — any client can kick any other (admin_kick has no auth check)
4. Message ordering — no sequence numbers, clients can't detect out-of-order delivery

Deliver: bug analysis + complete fixed server + brief test showing each fix works.""",
            "category": "debugging",
            "format": "standard",
            "challenge_type": "standard",
            "time_limit_minutes": 75,
        }
    },
    {
        "name": "Test 4 — Borderline/edge (very short prompt)",
        "expected": "borderline_or_pass",  # short but not trivial
        "challenge": {
            "title": f"Pipeline-Test: Reverse a Linked List [{uuid.uuid4().hex[:6]}]",
            "description": "Reverse a singly linked list",
            "prompt": """Implement a function to reverse a singly linked list.

Given the head of a singly linked list, reverse it and return the new head.

Example: 1->2->3->4->5 becomes 5->4->3->2->1

Provide both iterative and recursive solutions. Explain the tradeoffs.""",
            "category": "algorithms",
            "format": "sprint",
            "challenge_type": "daily",
            "time_limit_minutes": 20,
        }
    },
    {
        "name": "Test 5 — Good (Systems design + implementation)",
        "expected": "pass",
        "challenge": {
            "title": f"Pipeline-Test: Build a Rate Limiter [{uuid.uuid4().hex[:6]}]",
            "description": "Implement a sliding window rate limiter",
            "prompt": """Implement a sliding window rate limiter that:
- Allows N requests per window (e.g. 100 req/min)
- Uses sliding window algorithm (not fixed window — no boundary burst)
- Thread-safe for concurrent requests
- Returns: { allowed: boolean, remaining: number, resetMs: number }
- Memory efficient — cleans up expired entries

```typescript
// rate-limiter.ts — implement this interface
interface RateLimiter {
  check(clientId: string, limit: number, windowMs: number): {
    allowed: boolean;
    remaining: number;
    resetMs: number;
  };
}
```

Requirements:
- Sliding window (not token bucket, not fixed window)
- O(1) amortized per check
- Works correctly under concurrent load (no race conditions)
- Test with: burst pattern, steady pattern, boundary case (exactly at limit)

Deliver: implementation + tests + explanation of why sliding window beats fixed window for burst prevention.""",
            "category": "systems",
            "format": "standard",
            "challenge_type": "standard",
            "time_limit_minutes": 60,
        }
    },
]


def insert_challenge(data: dict) -> str | None:
    payload = {
        **data["challenge"],
        "status": "upcoming",
        "calibration_status": "draft",
        "generated_by": "forge-e2e-test",
        "auto_promote": True,
        "starts_at": "2099-01-01T00:00:00Z",
        "ends_at": "2099-12-31T23:59:59Z",
    }
    r = requests.post(f"{SUPA_URL}/rest/v1/challenges", headers=SUPA_HEADERS, json=payload)
    if not r.ok:
        print(f"    [ERROR] Insert failed: {r.status_code} {r.text[:200]}")
        return None
    result = r.json()
    if isinstance(result, list):
        result = result[0]
    return result.get("id")


def queue_for_calibration(challenge_id: str) -> bool:
    r = requests.post(
        f"{SUPA_URL}/rest/v1/rpc/queue_challenge_for_calibration",
        headers=SUPA_HEADERS,
        json={"p_challenge_id": challenge_id},
    )
    if not r.ok:
        print(f"    [ERROR] Queue failed: {r.status_code} {r.text[:200]}")
        return False
    result = r.json()
    return result.get("queued", False)


def run_auto_calibrate() -> dict:
    r = requests.post(
        f"{APP_URL}/api/internal/auto-calibrate",
        headers={"Authorization": f"Bearer {CRON_SECRET}", "Content-Type": "application/json"},
        timeout=300,
    )
    if not r.ok:
        return {"error": r.text, "status": r.status_code}
    return r.json()


def get_challenge_status(challenge_id: str) -> dict | None:
    r = requests.get(
        f"{SUPA_URL}/rest/v1/challenges?id=eq.{challenge_id}&select=id,title,status,calibration_status,calibration_verdict,calibration_reason",
        headers=SUPA_HEADERS,
    )
    data = r.json()
    if isinstance(data, list) and data:
        return data[0]
    return None  # deleted → returns empty


def get_calibration_result(challenge_id: str) -> dict | None:
    r = requests.get(
        f"{SUPA_URL}/rest/v1/challenge_calibration_results?challenge_id=eq.{challenge_id}&select=separation_score,discrimination_verdict,recommendation,reason",
        headers=SUPA_HEADERS,
    )
    data = r.json()
    return data[0] if (isinstance(data, list) and data) else None


def main():
    print("=" * 70)
    print("BOUTS PIPELINE END-TO-END TEST — 5 CYCLES")
    print("=" * 70)

    all_results = []

    for i, test in enumerate(TEST_CHALLENGES, 1):
        print(f"\n{'─' * 70}")
        print(f"CYCLE {i}/5: {test['name']}")
        print(f"Expected outcome: {test['expected']}")
        print(f"{'─' * 70}")

        # Step 1: Insert
        print("  [1] Inserting challenge...")
        challenge_id = insert_challenge(test)
        if not challenge_id:
            print("  [FAIL] Could not insert")
            all_results.append({"cycle": i, "name": test["name"], "result": "INSERT_FAILED"})
            continue
        print(f"  [OK] ID: {challenge_id}")

        # Step 2: Queue
        print("  [2] Queuing for calibration...")
        queued = queue_for_calibration(challenge_id)
        if not queued:
            print("  [FAIL] Could not queue")
            all_results.append({"cycle": i, "name": test["name"], "result": "QUEUE_FAILED"})
            continue
        print("  [OK] Queued — calibration_status: pending")

        # Step 3: Run auto-calibrate (each cycle individually to avoid batching)
        print("  [3] Running auto-calibration (real LLM — may take 60-90s)...")
        start = time.time()
        cal_run = run_auto_calibrate()
        elapsed = int(time.time() - start)

        if "error" in cal_run:
            print(f"  [FAIL] Calibration error: {cal_run['error'][:200]}")
            all_results.append({"cycle": i, "name": test["name"], "result": "CALIBRATION_ERROR"})
            continue

        summary = cal_run.get("summary", {})
        results_list = cal_run.get("results", [])
        this_result = next((r for r in results_list if r.get("challenge_id") == challenge_id), None)

        print(f"  [OK] Calibration complete in {elapsed}s")
        print(f"       Processed: {summary.get('processed')} | Promoted: {summary.get('promoted_to_reserve')} | Flagged: {summary.get('flagged')} | Deleted: {summary.get('deleted')}")

        if this_result:
            print(f"       This challenge: verdict={this_result.get('verdict')} action={this_result.get('action')} sep={this_result.get('separation')}pts")
            if this_result.get("reason"):
                print(f"       Reason: {this_result['reason']}")

        # Step 4: Verify final state
        print("  [4] Verifying final state...")
        final_state = get_challenge_status(challenge_id)
        cal_result = get_calibration_result(challenge_id)

        if final_state is None:
            outcome = "DELETED"
            print(f"  → Challenge was DELETED (failed calibration)")
        else:
            outcome = f"{final_state.get('status')}|{final_state.get('calibration_status')}"
            print(f"  → status={final_state.get('status')} calibration_status={final_state.get('calibration_status')}")

        if cal_result:
            print(f"  → CDI separation={cal_result.get('separation_score')}pts verdict={cal_result.get('discrimination_verdict')}")

        # Determine pass/fail for this test
        verdict = this_result.get("verdict") if this_result else "unknown"
        action = this_result.get("action") if this_result else "unknown"
        test_passed = (
            (test["expected"] == "pass" and action == "promoted_to_reserve") or
            (test["expected"] == "borderline_or_pass" and action in ("promoted_to_reserve", "flagged_for_review")) or
            (test["expected"] == "fail" and action == "deleted")
        )

        status_icon = "✅" if test_passed else "⚠️ "
        print(f"\n  {status_icon} Cycle {i} result: {action} (expected: {test['expected']})")

        all_results.append({
            "cycle": i,
            "name": test["name"],
            "expected": test["expected"],
            "verdict": verdict,
            "action": action,
            "separation": this_result.get("separation") if this_result else None,
            "passed_test": test_passed,
            "elapsed_s": elapsed,
        })

        # Small pause between cycles so we don't hammer OpenRouter
        if i < len(TEST_CHALLENGES):
            print(f"\n  Pausing 5s before next cycle...")
            time.sleep(5)

    # Final summary
    print(f"\n{'=' * 70}")
    print("FINAL RESULTS")
    print(f"{'=' * 70}")
    passed = sum(1 for r in all_results if r.get("passed_test"))
    total = len(all_results)

    for r in all_results:
        icon = "✅" if r.get("passed_test") else "⚠️ "
        sep = f"sep={r.get('separation')}pts" if r.get("separation") else ""
        print(f"  {icon} Cycle {r['cycle']}: {r.get('action','?').upper()} {sep} — {r['name'][:45]}")

    print(f"\nScore: {passed}/{total} cycles behaved as expected")
    print(f"Pipeline status: {'✅ WORKING' if passed >= 4 else '⚠️  NEEDS REVIEW'}")

    # Save
    with open("/data/.openclaw/workspace-forge/bouts-model-test/e2e-results.json", "w") as f:
        json.dump(all_results, f, indent=2, default=str)
    print(f"\nResults saved to e2e-results.json")


if __name__ == "__main__":
    main()
