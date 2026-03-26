# Error Recovery Playbook

Standardized procedures for every known failure mode. When something goes wrong, find the matching scenario and follow the playbook. Do not improvise unless no playbook exists — and if that happens, document the new scenario afterward.

---

## Agent Unresponsive

**Symptoms:** Agent does not respond within expected time window. No output, no error, no acknowledgment.

**Playbook:**

1. **Retry (immediate):** Resend the same `sessions_send` message. Agents may have missed the initial message due to transient issues.
2. **Wait 3 minutes.** Some tasks take longer than expected. Give the agent a reasonable buffer.
3. **First nudge:** Send a status check message: "Status update requested — are you still working on {task}?"
4. **Wait another expected-duration window.**
5. **Second nudge:** Send with urgency: "Second status check — {task} is blocking the pipeline. Please respond with current status or any blockers."
6. **Check with ClawExpert:** Send ClawExpert a diagnostic request: "Is {agent name} reachable? Any infrastructure issues affecting agent availability?" ClawExpert may identify system-level problems.
7. **Escalate to Nick:** If still no response after 2 nudges and ClawExpert check, report to Nick:
   - Which agent is unresponsive.
   - What task they were assigned.
   - How long they've been unresponsive.
   - What you've tried.
   - Recommended action (wait longer, reassign task, manual intervention).

---

## V0 API Failure

**Symptoms:** Pixel reports V0 API is down, timing out, or returning errors. Design pipeline cannot proceed.

**Playbook:**

1. **Retry (immediate):** Ask Pixel to retry the V0 request. Transient failures are common.
2. **Wait 2 minutes and retry again.** V0 outages are often brief.
3. **Stitch fallback:** If V0 remains unavailable, instruct Pixel to switch to Stitch for design generation. Note in the project file that Stitch was used (reduced fidelity).
4. **Text-based specs fallback:** If both V0 and Stitch are unavailable, instruct Pixel to produce detailed text-based design specifications:
   - Layout descriptions with exact measurements.
   - Color values and typography specs.
   - Component hierarchy and behavior descriptions.
   - Wireframe-level sketches if possible.
5. **Note the fallback** in the project file and in the handoff to Maks so he knows designs are text-based and should use best judgment for visual details.
6. **Report to Nick** if the fallback significantly impacts quality or timeline.

---

## Forge Blocks 3+ Times (Circuit Breaker)

**Symptoms:** Maks and Forge have completed 3 fix loops and Forge still has not approved. The circuit breaker has triggered.

**Playbook:**

1. **Stop the loop immediately.** Do not send a 4th fix request to Maks.
2. **Compile a summary:**
   - Original issues Forge raised in loop 1.
   - What Maks fixed in each loop.
   - Remaining issues Forge is still flagging.
   - Pattern analysis: Are these the same issues recurring, or new issues each time?
3. **Escalate to Nick with 3 options:**

   > **Option A: Ship with known issues.**
   > The remaining issues are [{list}]. None are P0 security/data-loss risks. We document them as known issues and address in a follow-up iteration.

   > **Option B: Bring in additional context.**
   > Forge and Maks may be misaligned on [{specific area}]. Nick can provide clarification or additional requirements that resolve the disagreement.

   > **Option C: Redesign the problematic section.**
   > The issues stem from [{root cause — e.g., a specific component, architectural decision}]. Send the affected screen(s) back to Pixel for redesign, then rebuild.

4. **Wait for Nick's decision.** Do not proceed until Nick picks an option or provides an alternative direction.

---

## Build Fails to Deploy

**Symptoms:** Maks reports a deployment failure. Preview or production URL is not accessible.

**Playbook:**

1. **Get the error.** Ask Maks for the exact error message, stack trace, or deployment log output.
2. **Categorize the error:**
   - **Code error** (build fails, type errors, missing imports): Maks debugs and retries. This is within Maks's domain.
   - **Infrastructure error** (DNS, SSL, Vercel config, environment variables, permissions): Consult ClawExpert.
   - **Dependency error** (package conflicts, version mismatches): Maks resolves, or consult ClawExpert if it's a system-level issue.
3. **If code error:** Tell Maks the specific error and ask for a fix. Allow 2 attempts.
4. **If infrastructure error:** Send ClawExpert the error with context:
   - What was being deployed.
   - The deployment platform and configuration.
   - The exact error message.
   - Wait for ClawExpert's diagnostic and fix.
5. **If still failing after 2 Maks attempts + ClawExpert consultation:** Escalate to Nick with the error details and what's been tried.

---

## Design Mismatch After Build

**Symptoms:** QA or visual inspection reveals that the build doesn't match Pixel's designs for specific screens.

**Playbook:**

1. **Identify the specific mismatches.** Document which screens don't match and what's different (layout, colors, spacing, missing elements, wrong behavior).
2. **Assess severity:**
   - **Minor** (slight spacing, color shade): Note for Maks with specific corrections. No need to involve Pixel.
   - **Major** (wrong layout, missing sections, broken user flow): Send back to Maks with Pixel's original specs highlighted.
3. **Send Maks targeted fix requests** for each mismatched screen:
   - Reference the specific Pixel design (V0 chat ID, preview URL).
   - Point out exactly what's different.
   - Ask for a match to the design, not a "close enough."
4. **If Maks cannot match the design** due to technical constraints, notify Pixel and ask for an alternative design approach that's feasible to implement.
5. **Re-QA the fixed screens** before proceeding.

---

## Nick Changes Requirements Mid-Build

**Symptoms:** Nick sends updated requirements while the project is in BUILD, REVIEW, or later phases.

**Playbook:**

1. **Acknowledge immediately.** Tell Nick you've received the changes and are assessing impact.
2. **Assess the change type:**
   - **Cosmetic** (copy changes, color tweaks, minor layout adjustments): Send directly to Maks as a patch. No need to loop back to earlier phases.
   - **Structural** (new screens, removed screens, different user flows, new features, changed backend requirements): Requires re-evaluation.
3. **For cosmetic changes:**
   - Send Maks the specific changes.
   - Note the change in the project file.
   - Continue the pipeline from current phase.
4. **For structural changes:**
   - Pause the current pipeline.
   - Update the project file with the new requirements.
   - Determine which phase to re-enter:
     - New screens → Back to DESIGN for those screens only.
     - New features/backend → Back to DESIGN or BUILD depending on scope.
     - Changed ICP/positioning → Back to RESEARCH.
   - Report to Nick: "Structural change received. This resets us to {phase}. New ETA: {estimate}."
5. **Never silently absorb structural changes.** Always report the impact to Nick.

---

## Gateway Crash / MaksPM Restart

**Symptoms:** MaksPM loses context — conversation resets, memory is gone, no awareness of active projects.

**Playbook:**

1. **Read active-projects/.** List all project files and their current states.
2. **For each active project:**
   - Read the project file to determine current phase and last activity.
   - Check the Phase Log for the most recent transition.
   - Identify what was in progress when the crash occurred.
3. **Resume from the project file.** The project file is the source of truth. Pick up from the last completed phase:
   - If a brief was sent but no response received → Resend the brief.
   - If a response was received but the gate wasn't checked → Run the gate check.
   - If a phase was complete but the next wasn't started → Start the next phase.
4. **Send Nick a recovery report:**
   - "MaksPM restarted. Recovered {n} active project(s). Current status: {summary per project}. Resuming from last known state."
5. **Re-establish contact with any agents that had pending tasks** via `sessions_send` status checks.

---

## Subagent Spawn Failed or Timed Out
1. Check if the spawn completed: look at the auto-announce message for errors
2. If timeout (no response after runTimeoutSeconds): spawn again with longer timeout
3. If agent errored: read the error, fix the task prompt, spawn again
4. After 2 failed spawns → escalate to Nick: "[Agent] failed twice on [task]. Error: [details]. Options: (A) retry with different approach (B) skip this phase (C) you intervene"

## Subagent Returns Incomplete Work
1. Check what's missing against the quality gate
2. Spawn the same agent again with: "Previous output was incomplete. Missing: [specific items]. Complete only the missing items."
3. If still incomplete after retry → proceed with what you have + note the gap to Nick

## Auto-Announce Didn't Arrive
1. Check sessions_list for the spawned session — is it still running?
2. If still running → wait (don't re-spawn and create duplicates)
3. If completed but no announce → read result via sessions_history with the session key
4. If session doesn't exist → spawn again
