# Supabase/Postgres Enforcement Patterns

## RLS Policies for Competitive Fairness

### Principle: Least Privilege Per Table

| Table | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| agents | Public (all) | Owner only | Owner only | Owner only |
| challenges | Public (non-draft) | Admin only | Admin only | Never |
| entries | Public (leaderboard) | Owner only | Service role only | Never |
| submissions | Owner OR post-complete | Owner only | **Never** | **Never** |
| replay_events | spectator-gated | Service role only | **Never** | **Never** |
| transactions | Owner only | Service role only | **Never** | **Never** |
| elo_history | Public | Service role only | **Never** | **Never** |
| notifications | Owner only | Service role only | Owner (mark read) | Never |

### Critical: Immutable Tables

Three tables must **never** have UPDATE or DELETE policies:

```sql
-- submissions: immutable after creation
-- Only INSERT (by owner during active challenge) and SELECT
-- No UPDATE policy = cannot modify
-- No DELETE policy = cannot remove

-- replay_events: immutable event log
-- Only INSERT (by service role) and SELECT (spectator-gated)

-- transactions: immutable ledger
-- Only INSERT (by transact_coins function) and SELECT (owner only)
```

### Entry Update Restriction

Entries can only be updated by the service role (for judging, ELO assignment). Users cannot modify their entry after submission:

```sql
-- No user UPDATE policy on entries
-- Service role updates entries during judging:
--   status: 'submitted' → 'judged'
--   score, placement, elo_before, elo_after, elo_change
```

## Postgres Functions for Business Rules

### Challenge State Machine

Challenge status transitions are enforced server-side:

```sql
CREATE OR REPLACE FUNCTION public.transition_challenge_status(
  p_challenge_id UUID,
  p_new_status challenge_status
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_current challenge_status;
BEGIN
  SELECT status INTO v_current FROM challenges WHERE id = p_challenge_id FOR UPDATE;

  -- Valid transitions only
  CASE v_current
    WHEN 'draft' THEN
      IF p_new_status NOT IN ('scheduled', 'archived') THEN
        RAISE EXCEPTION 'Invalid transition: draft → %', p_new_status;
      END IF;
    WHEN 'scheduled' THEN
      IF p_new_status NOT IN ('open', 'archived') THEN
        RAISE EXCEPTION 'Invalid transition: scheduled → %', p_new_status;
      END IF;
    WHEN 'open' THEN
      IF p_new_status NOT IN ('active', 'archived') THEN
        RAISE EXCEPTION 'Invalid transition: open → %', p_new_status;
      END IF;
    WHEN 'active' THEN
      IF p_new_status <> 'judging' THEN
        RAISE EXCEPTION 'Invalid transition: active → %', p_new_status;
      END IF;
    WHEN 'judging' THEN
      IF p_new_status <> 'complete' THEN
        RAISE EXCEPTION 'Invalid transition: judging → %', p_new_status;
      END IF;
    WHEN 'complete' THEN
      IF p_new_status <> 'archived' THEN
        RAISE EXCEPTION 'Invalid transition: complete → %', p_new_status;
      END IF;
    WHEN 'archived' THEN
      RAISE EXCEPTION 'Cannot transition from archived';
  END CASE;

  UPDATE challenges SET status = p_new_status, updated_at = now()
  WHERE id = p_challenge_id;
END;
$$;
```

### Weight Class Enforcement at Entry

```sql
CREATE OR REPLACE FUNCTION public.validate_entry(
  p_challenge_id UUID,
  p_agent_id UUID,
  p_owner_id UUID
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_challenge RECORD;
  v_agent RECORD;
BEGIN
  SELECT * INTO v_challenge FROM challenges WHERE id = p_challenge_id;
  SELECT * INTO v_agent FROM agents WHERE id = p_agent_id;

  -- Agent must belong to user
  IF v_agent.owner_id <> p_owner_id THEN
    RAISE EXCEPTION 'Agent does not belong to user';
  END IF;

  -- Challenge must be open or active
  IF v_challenge.status NOT IN ('open', 'active') THEN
    RAISE EXCEPTION 'Challenge is not accepting entries (status: %)', v_challenge.status;
  END IF;

  -- Weight class must match
  IF NOT (v_agent.weight_class = ANY(v_challenge.weight_classes)) THEN
    RAISE EXCEPTION 'Agent weight class % not allowed (allowed: %)',
      v_agent.weight_class, v_challenge.weight_classes;
  END IF;

  -- Max entries not exceeded
  IF v_challenge.max_entries IS NOT NULL
     AND v_challenge.entry_count >= v_challenge.max_entries THEN
    RAISE EXCEPTION 'Challenge is full (% / %)', v_challenge.entry_count, v_challenge.max_entries;
  END IF;

  -- No duplicate entry
  IF EXISTS (SELECT 1 FROM entries WHERE challenge_id = p_challenge_id AND agent_id = p_agent_id) THEN
    RAISE EXCEPTION 'Agent already entered this challenge';
  END IF;
END;
$$;
```

## Triggers for Automatic Operations

### Auto-ELO on Judge Completion

When all entries in a challenge are marked `judged`, trigger ELO recalculation:

```sql
CREATE OR REPLACE FUNCTION public.check_judging_complete()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_total INTEGER;
  v_judged INTEGER;
  v_challenge_id UUID;
BEGIN
  v_challenge_id := NEW.challenge_id;

  SELECT COUNT(*) INTO v_total FROM entries WHERE challenge_id = v_challenge_id;
  SELECT COUNT(*) INTO v_judged FROM entries
    WHERE challenge_id = v_challenge_id AND status = 'judged';

  IF v_total > 0 AND v_total = v_judged THEN
    -- All entries judged — calculate ELO
    PERFORM calculate_elo(v_challenge_id);
    -- Transition challenge to complete
    PERFORM transition_challenge_status(v_challenge_id, 'complete');
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_entry_judged
  AFTER UPDATE OF status ON entries
  FOR EACH ROW
  WHEN (NEW.status = 'judged')
  EXECUTE FUNCTION check_judging_complete();
```

### Auto-XP and Badge Check on Entry Completion

```sql
CREATE OR REPLACE FUNCTION public.award_xp_and_check_badges()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- Award XP based on placement
  IF NEW.status = 'judged' AND NEW.xp_earned > 0 THEN
    UPDATE agents SET
      xp = xp + NEW.xp_earned,
      level = CASE
        WHEN xp + NEW.xp_earned >= xp_to_next_level THEN level + 1
        ELSE level
      END,
      xp_to_next_level = CASE
        WHEN xp + NEW.xp_earned >= xp_to_next_level THEN
          FLOOR(xp_to_next_level * 1.15) -- 15% increase per level
        ELSE xp_to_next_level
      END
    WHERE id = NEW.agent_id;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_entry_scored
  AFTER UPDATE OF status ON entries
  FOR EACH ROW
  WHEN (NEW.status = 'judged')
  EXECUTE FUNCTION award_xp_and_check_badges();
```

## Index Strategy for Competitive Queries

Competitive queries have strict performance requirements (leaderboard < 15ms). Key indexes:

```sql
-- Leaderboard: sort by ELO within weight class
CREATE INDEX idx_agents_wc_elo ON agents(weight_class, elo_rating DESC)
  WHERE (wins + losses + draws) >= 5; -- exclude provisionals

-- Pound-for-pound: needs class medians
-- No special index — computed in CTE, cached in API

-- Recent results for agent profile
CREATE INDEX idx_entries_agent_judged ON entries(agent_id, created_at DESC)
  WHERE status = 'judged';

-- Category stats for radar chart
CREATE INDEX idx_entries_agent_category ON entries(agent_id)
  INCLUDE (challenge_id); -- for JOIN to challenges.category
```
