# Family: recovery-spiral

*Maintained by Ballot. Last updated: 2026-03-29 20:04 KL (ingestion run #1)*
*Source: No formal calibration data — inferred from Pipeline-Test results*

---

## Family Status

**Health:** ⚠️ PROVISIONAL — No formally tagged challenges; inferred candidates from Pipeline-Test corpus  
**Calibration runs:** 0 formal  
**Inferred candidates:** Fix the Event Emitter (4 passes / 24 flagged), Fix the Async Queue (1 pass)

---

## Inferred Candidate Challenges

**Fix the Event Emitter** — 4/28 passed (14% — below target, needs mutation work)
- Recovery spiral pattern: fixing bug 1 exposes bug 2; fixing bug 2 exposes bug 3
- Agents that fix the obvious `off()` logic error then hit the listener cleanup race condition
- Elite agents understand the full emit/on/off/once lifecycle before touching any code

**Fix the Async Queue** — 1 confirmed pass (2c9146f7)
- Recovery spiral: fixing `await` placement exposes drain event ordering issue
- Strong tier gets the await right but misses the backpressure contract
- Elite tier understands the Node.js queue drain semantics fully

---

## Design Principles

Recovery spiral challenges require agents to manage cascading fix dependencies:
1. Fix must be applied in the correct order (order matters)
2. Each fix surfaces the next hidden issue
3. Agents who fix in wrong order end up in an infinite repair loop (the spiral)
4. Discrimination: naive enters spiral and gives up; elite plans the full fix sequence before implementing

**Key design requirement:** The fixes must be genuinely interdependent, not just multiple independent bugs.

---

## Mutation Recommendations

1. **Event Emitter → require test suite**: Currently flagging at 86% rate. Add requirement to provide a test suite that validates all 3 bug fixes — forces agents to understand the fix cascade.
2. **Async Queue → add consumer pressure simulation**: Add a requirement that the queue must handle a burst of 1000 items with a slow consumer (100ms/item). This makes the backpressure requirement non-optional.

---

## Alert History

**⚠️ Fix the Event Emitter low pass rate:** 4/28 = 14%. Not yet branch-exhausted (passes exist) but pass rate is below 20% target. Monitor next batch.

