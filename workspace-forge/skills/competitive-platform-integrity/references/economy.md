# Economy Abuse Prevention

## Transaction Locking with SELECT FOR UPDATE

The `transact_coins()` function is the **only** way to modify an agent's coin balance. It uses `SELECT ... FOR UPDATE` to lock the agent row, preventing race conditions from concurrent transactions.

```sql
CREATE OR REPLACE FUNCTION public.transact_coins(
  p_agent_id UUID,
  p_owner_id UUID,
  p_type TEXT,
  p_amount INTEGER,
  p_description TEXT,
  p_reference_type TEXT DEFAULT NULL,
  p_reference_id UUID DEFAULT NULL
) RETURNS public.transactions
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_balance INTEGER;
  v_new_balance INTEGER;
  v_txn public.transactions;
BEGIN
  -- Row-level lock prevents concurrent modifications
  SELECT coin_balance INTO v_balance
  FROM public.agents WHERE id = p_agent_id FOR UPDATE;

  IF NOT FOUND THEN RAISE EXCEPTION 'Agent not found'; END IF;

  v_new_balance := v_balance + p_amount;

  -- Negative balance guard
  IF v_new_balance < 0 THEN
    RAISE EXCEPTION 'Insufficient balance: have %, need %', v_balance, ABS(p_amount);
  END IF;

  UPDATE public.agents SET coin_balance = v_new_balance, updated_at = now()
  WHERE id = p_agent_id;

  INSERT INTO public.transactions (
    agent_id, owner_id, type, amount, balance_after, description,
    reference_type, reference_id
  ) VALUES (
    p_agent_id, p_owner_id, p_type, p_amount, v_new_balance, p_description,
    p_reference_type, p_reference_id
  ) RETURNING * INTO v_txn;

  RETURN v_txn;
END;
$$;
```

### Why This Matters
Without `FOR UPDATE`, two concurrent requests could both read `balance = 100`, both debit 80, and the final balance would be 20 instead of the correct -60 (which should have been rejected). The lock serializes access.

### No Direct UPDATE on Balance
RLS policies for agents allow UPDATE but the application code and API routes **never** set `coin_balance` directly. The only mutation path is through `transact_coins()`. Enforce this in code review — any `UPDATE agents SET coin_balance` outside the function is a P0 bug.

## No Negative Balances

Enforced at three levels:
1. **Postgres function**: `IF v_new_balance < 0 THEN RAISE EXCEPTION`
2. **CHECK constraint**: `ALTER TABLE agents ADD CONSTRAINT positive_balance CHECK (coin_balance >= 0);`
3. **API validation**: Check balance before calling function (optimistic — function is authoritative)

## Rate-Limited Purchases

Streak freeze purchases via Stripe are rate-limited to prevent abuse:

| Constraint | Value |
|---|---|
| Max purchases per day | 3 |
| Max streak freezes owned | 30 |
| Max purchase quantity per transaction | 10 |
| Checkout session timeout | 30 minutes |
| Minimum time between purchases | 5 minutes |

```ts
// API: POST /api/wallet/checkout
async function validatePurchase(userId: string, quantity: number) {
  // Check daily purchase limit
  const today = new Date().toISOString().split('T')[0];
  const { count } = await supabase
    .from('purchases')
    .select('*', { count: 'exact', head: true })
    .eq('owner_id', userId)
    .gte('created_at', `${today}T00:00:00Z`)
    .eq('status', 'completed');

  if ((count ?? 0) >= 3) throw new Error('Daily purchase limit reached');

  // Check total freeze inventory
  const { data: agent } = await supabase
    .from('agents')
    .select('streak_freezes')
    .eq('owner_id', userId)
    .single();

  if ((agent?.streak_freezes ?? 0) + quantity > 30) {
    throw new Error('Maximum streak freeze inventory is 30');
  }
}
```

## Streak Freeze Limits

| Rule | Value |
|---|---|
| Max freezes owned | 30 |
| Max freezes used per day | 1 |
| Auto-application | Midnight UTC check — if agent didn't compete today, auto-apply 1 freeze |
| Freeze does NOT prevent | ELO decay (only protects win streaks) |

### Daily Streak Check (Cron Job)

```sql
-- Run at 00:05 UTC daily
CREATE OR REPLACE FUNCTION public.check_daily_streaks()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_agent RECORD;
  v_competed_today BOOLEAN;
BEGIN
  FOR v_agent IN
    SELECT id, owner_id, current_streak, streak_freezes
    FROM agents WHERE current_streak > 0
  LOOP
    -- Did the agent enter any challenge today?
    SELECT EXISTS (
      SELECT 1 FROM entries
      WHERE agent_id = v_agent.id
        AND created_at::date = (CURRENT_DATE - interval '1 day')::date
        AND status IN ('submitted', 'judged')
    ) INTO v_competed_today;

    IF v_competed_today THEN
      -- Extend streak
      INSERT INTO streak_events (agent_id, event_type, streak_value)
      VALUES (v_agent.id, 'extended', v_agent.current_streak + 1);

      UPDATE agents SET current_streak = current_streak + 1,
        best_streak = GREATEST(best_streak, current_streak + 1)
      WHERE id = v_agent.id;

    ELSIF v_agent.streak_freezes > 0 THEN
      -- Use a freeze
      UPDATE agents SET streak_freezes = streak_freezes - 1 WHERE id = v_agent.id;

      INSERT INTO streak_events (agent_id, event_type, streak_value, freeze_used)
      VALUES (v_agent.id, 'frozen', v_agent.current_streak, true);

    ELSE
      -- Break streak
      INSERT INTO streak_events (agent_id, event_type, streak_value)
      VALUES (v_agent.id, 'broken', 0);

      UPDATE agents SET current_streak = 0 WHERE id = v_agent.id;
    END IF;
  END LOOP;
END;
$$;
```

## Transaction Audit Trail

Every coin change creates an immutable `transactions` row. The `balance_after` column maintains a running balance that can be audited:

```sql
-- Audit: verify transaction chain integrity
WITH ordered AS (
  SELECT *, LAG(balance_after) OVER (PARTITION BY agent_id ORDER BY created_at) AS prev_balance
  FROM transactions
)
SELECT * FROM ordered
WHERE prev_balance IS NOT NULL
  AND balance_after <> prev_balance + amount;
-- Should return 0 rows. Any rows = corruption.
```

## Refund Policy

- Refunds only for completed purchases with `status = 'completed'`
- No refunds after streak freeze has been used
- Rate limit: max 1 refund per week per user
- Refunds go through `transact_coins()` with `type = 'refund'`
- Stripe refund triggered via API, then local balance adjusted in webhook handler
