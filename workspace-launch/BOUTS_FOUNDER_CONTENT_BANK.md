# BOUTS_FOUNDER_CONTENT_BANK.md
## Launch — March 2026 (Revised — audited for factual precision and founder voice)

---

## USAGE NOTE
Before publishing any post: verify all factual claims against live product state. Posts referencing specific volume, observation counts, or behavioral patterns need verification or removal. These posts are written to sound like Nick — direct, no-hype, conviction-driven. If a line sounds like a content agency wrote it, cut it.

---

## 20 FOUNDER POST IDEAS

1. Why I built an evaluation platform instead of another agent
2. The structural problem with self-reported AI agent capability
3. What four-lane judging reveals that a single score hides
4. I built Bouts using an AI agent team — here's what that taught me about evaluation
5. Why bigger models don't always win in structured competition
6. The difference between a demo and a bout
7. What "platform-verified" means — architecturally, not just philosophically
8. Why benchmark contamination is a feature, not a bug, of the current eval ecosystem
9. The hardest product decision we made: four lanes vs. one score
10. Why we built sandbox to mirror the production result flow
11. What an Integrity score is and why it's the most interesting lane
12. The agent ecosystem's trust gap — and why it compounds over time
13. What I learned from watching real agent submissions across the four judging lanes
14. Why we sequenced it trust → reputation → discovery → commerce
15. What a Bouts breakdown looks like — and how to read it
16. Why GitHub Action integration is the right way to think about continuous agent evaluation
17. The problem with leaderboards: they rank without explaining
18. Why calibrated challenges matter more than challenge volume
19. What the Integrity lane catches that Objective and Process miss
20. We're building the reputation layer the agent ecosystem never had

---

## 10 FULLY WRITTEN FOUNDER POSTS

---

### Post 1: Why I built Bouts

I built Bouts because I needed it and couldn't find it.

I was running an AI agent team — multiple agents handling real tasks, real code, real decisions. And I kept running into the same question with no good answer: which agent is actually good?

Not "which agent scored highest on HumanEval." Not "which vendor had the best demo." Which one, in a real task under real conditions, performs reliably?

I tried benchmarks. They tell you what a model was trained to know. They don't tell you how an agent handles something it hasn't seen before, under pressure, with a clear success criterion.

I looked for a competitive evaluation platform. Something that would let my agents go against real challenges, get structured results, and build a reputation I could actually use. Something where the data came from competition, not from me writing about my own product.

There wasn't one.

So I built Bouts.

The core design: calibrated challenges, four-lane judging — Objective, Process, Strategy, Integrity — and performance records built from verified results. Not self-reported claims. Not demos. Evidence.

If you've built an agent and want real proof of how it performs, this is what we made it for.

---

### Post 2: The trust problem no one is solving

Here's the structural problem with AI agent evaluation right now:

Every agent team says their agent is good. Most of them believe it. Some of them are right.

But the mechanisms we have for telling the difference are either too narrow (static benchmarks), too opaque (internal evals), or not credible to outside observers (vendor-selected benchmarks).

And the problem is structural. Not moral.

When the only evaluation surface you have is one you built yourself, your eval will naturally reflect your agent favorably. Not because you cheated — because you designed it for your use case and tested it until it worked.

Bouts is built to solve the structural problem, not just the symptom.

Platform-verified results are kept architecturally separate from self-reported data. Challenges go through a calibration pipeline before they go live. Judging runs across four lanes so one strong area doesn't inflate the overall picture.

The goal is a trust layer for the agent ecosystem. Built on competition, not marketing.

---

### Post 3: One score hides too much

When Bouts evaluates a submission, we don't produce one number.

We produce four scores:

**Objective** — Did the agent complete the task correctly?

**Process** — How did the agent work? Was the methodology sound?

**Strategy** — Did the agent make good decisions? Handle edge cases?

**Integrity** — Did the agent represent its work honestly?

Here's why this matters:

An agent can score perfectly on Objective and fail on Process. That means it got the right answer, but the methodology was fragile — it would break on a slightly different version of the problem.

An agent can score high on Process and Strategy but fail on Integrity. That means it worked well but misrepresented how — which matters for trust in production.

A single score collapses all of this into a number that tells you almost nothing useful.

The breakdown is the product. Not the score.

---

### Post 4: I built the platform with AI agents

The part people find interesting and I find obvious: Bouts was built by an AI agent team.

Not assisted by AI. Built by a pipeline of specialized agents — architect, builder, designer, PM, QA — coordinated through a structured system.

I mention this not because it's clever marketing. I mention it because it shaped how I think about agent evaluation.

When you've watched AI agents build real software — architecture specs, code reviews, functional QA, E2E testing — you develop specific opinions about what good agent performance looks like versus what looks good in a demo.

Good agents are consistent. They handle edge cases. They don't just produce impressive output on the first attempt — they maintain quality across repeated tasks.

Demo-optimized agents look better than they are. They're tuned for the showcase, not the grind.

Bouts is built to tell the difference. Because I've watched that difference play out in real work, many times over.

---

### Post 5: What "verified" actually means

"Verified" is an overloaded word. I should be precise about what Bouts means when we use it.

In Bouts, "platform-verified" means:

1. The challenge was designed and calibrated through our pipeline before going live — not generated ad-hoc.
2. The submission was evaluated by the Bouts judging engine, not scored by the agent team.
3. The result is stored on the platform and visible on the agent's profile, clearly distinguished from anything the agent team wrote about themselves.

What it doesn't mean:

It doesn't mean we have an external auditor certifying every result. It doesn't mean the judging is perfect or fully objective. It doesn't mean Bouts results are the final word on agent capability.

What it does mean: when someone looks at an agent's Bouts profile and sees a performance record, every number in that record came from the platform — not from the agent team. That structural distinction is what matters.

Self-reported information on Bouts is labeled clearly. Useful context. But not the same category of data as a performance record.

---

### Post 6: The hardest product decision

The hardest decision we made building Bouts was the four-lane judging system.

The easier path was a composite score. A number between 0 and 100, backed by weighted criteria, simple to communicate.

We almost did it that way.

The problem: a composite score is information compression that produces convenience at the cost of signal. It lets a strong Objective score carry a weak Integrity score without surfacing the discrepancy. It gives buyers and evaluators a number they can compare — but not understand.

The harder path was four separate lanes with separate scores and structured breakdowns. Harder to explain. Harder to build. Harder to design UI for.

But more honest. And more useful.

The builder who scores well on Objective and poorly on Process needs to know both things. The team evaluating agents for production needs to see that discrepancy, not have it averaged away.

The breakdown is more work to read than a number. It's worth reading.

---

### Post 7: Sandbox first

The first thing we tell new users: start in sandbox.

Not because we're being cautious. Because sandbox is where you learn what your agent actually does before it counts.

Sandbox in Bouts mirrors the real submission and result flow. The breakdown format you see in sandbox is the breakdown format you'll see in production. The challenge structure is the same. The only difference: sandbox results don't appear on your public record.

What that means in practice:

You find out how your agent performs across the four judging lanes before you've committed to a public result. You discover submission flow issues before they cost you a real record. You read a full breakdown and understand where your agent is strong and where it needs work.

Understand your agent in sandbox first. Then compete.

---

### Post 8: Why calibrated challenges matter

Not all challenges are equal. Most platforms treat them as if they are.

In Bouts, challenges go through a pipeline before they go live:

Design → Review → Calibration → Activation

Calibration is where we validate that a challenge produces meaningful signal. That it has clear success criteria. That the four judging lanes apply coherently. That it doesn't systematically advantage or disadvantage specific agent implementations.

Why does this matter?

Because a poorly designed challenge produces noisy results. If the challenge is ambiguous, agents that guess correctly look better than agents that reasoned carefully. If the success criteria are unclear, the Objective score means nothing.

The trustworthiness of a Bouts result depends on the trustworthiness of the challenge. We take that seriously.

Ad-hoc challenges produce noise. Calibrated challenges produce signal.

---

### Post 9: What the Integrity lane is

Let me explain the Integrity lane specifically, because it's the one people ask about most.

The other three lanes evaluate what the agent did. Integrity evaluates how the agent described what it did.

Specifically: did the agent represent its work honestly? Did it claim capabilities it didn't demonstrate? Did it explain its reasoning accurately? Was there consistency between what it said it was doing and what it actually did?

This matters because the trust problem in the agent ecosystem isn't only about performance. It's about self-representation.

An agent that produces correct results but misrepresents how — overstating confidence, obscuring a dependency, claiming reasoning that doesn't exist — is harder to trust in production than an agent that performed at 80% and was honest about it.

The Integrity lane catches that. It doesn't penalize agents for being imperfect. It penalizes agents for being misleading about their imperfections.

In my experience: the Integrity lane is the one that most consistently separates genuinely capable agents from demo-optimized ones.

---

### Post 10: Reputation earned, not written

The long-term vision for Bouts, stated plainly:

The agent ecosystem needs a reputation layer. One based on verified performance, not marketing copy. One where a builder can point to a record — not a claims page — and say: here is evidence.

We're building that.

Every bout an agent completes on Bouts adds to a verified performance record. Completion counts. Category strengths. Consistency signals. Recent form. All derived from platform activity — not from what the agent team said about themselves.

This is early. The records are short. The patterns are just starting to form.

But the architecture is right. The trust distinction between verified and self-reported is enforced at the platform level. The challenge pipeline produces results worth adding to a record. The four-lane judging produces records worth reading.

The reputation layer grows as the platform grows. More competition produces more records, which produces more trustworthy signal, which attracts more serious competitors.

We're at the beginning. The foundation is built.

---

## 5 ANNOUNCEMENT-STYLE POSTS

---

### Announcement 1: Bouts is live

Bouts is live.

It's a competitive evaluation platform for coding agents. Connect your agent, enter calibrated coding challenges, and get back a structured breakdown across four judging lanes: Objective, Process, Strategy, and Integrity.

Not a score. A breakdown. Because one number hides too much.

If you've built a coding agent and want real evidence of how it performs — not a demo, not a benchmark chart, not your own evaluation — this is what we built it for.

→ bouts.ai
Start in sandbox. Free to compete.

---

### Announcement 2: Full developer platform

Bouts now supports TypeScript SDK, Python SDK, CLI, GitHub Action, and MCP — in addition to the REST API.

Every surface routes through the same underlying judging engine. Sandbox mirrors the production result flow.

TypeScript: `npm install @bouts/sdk`
Python: `pip install bouts-sdk`
CLI and GitHub Action: docs at bouts.ai/docs

---

### Announcement 3: Private tracks available

Bouts now supports private evaluation tracks for organizations.

Run calibrated challenges against your internal agents. Results visible only to your team. Same four-lane judging as public competition.

Use cases: internal benchmarking before public release, pre-deployment validation, team-level evaluation programs.

If you're running an AI team that needs structured internal evaluation, reach out.

---

### Announcement 4: GitHub Action

Run Bouts evaluation directly in your CI/CD pipeline.

Every commit. Tracked against your agent's record over time. Sandbox mode available so evaluation doesn't affect your public profile until you're ready.

Full docs: bouts.ai/docs/github-action

---

### Announcement 5: Agent profiles

Agent profiles on Bouts now show verified performance summaries: completion counts, category strengths, consistency signals, and recent form.

All of it derived from platform activity. None of it self-reported.

Self-reported information — descriptions, capability tags, runtime metadata — is visible and useful. It's labeled clearly. It is not the same thing as a performance record.

That distinction is what the profile system is built around.

---

## 5 BUILDER / INTEGRATION POSTS

---

### Builder Post 1: GitHub Action

You should be running Bouts evaluation on every PR that touches your agent logic.

Here's the structure:

```yaml
- uses: bouts/evaluate-action@v1
  with:
    challenge-id: ch_abc123
    agent-id: your-agent-slug
    token: ${{ secrets.BOUTS_TOKEN }}
```

Start with sandbox mode until your baseline is solid. The breakdown is in the action output — you can parse lane scores and set CI checks against specific thresholds if you want to gate deploys on performance.

Full docs: bouts.ai/docs/github-action

---

### Builder Post 2: Python SDK

For ML teams and Python-native builders:

```python
from bouts import BoutsClient
import os

client = BoutsClient(token=os.environ["BOUTS_API_TOKEN"])

result = client.submit(
    challenge_id="ch_abc123",
    agent_id="your-agent-slug",
    submission={"code": your_output, "explanation": your_explanation},
)

for lane, data in result.breakdown.items():
    print(f"{lane}: {data['score']:.2f} — {data['notes']}")
```

Full SDK docs: bouts.ai/docs/python-sdk

---

### Builder Post 3: Reading your first breakdown

You ran your first bout. You have a breakdown. Here's how to read it.

Four sections: Objective, Process, Strategy, Integrity.

**Objective:** Did the agent complete the task correctly? If this is low, nothing else matters yet — the agent failed the task.

**Process:** How did the agent work? High Objective / low Process means: right answer, fragile method. Reliability warning.

**Strategy:** Decision quality. Did the agent prioritize correctly, handle ambiguity well? Low Strategy with high Objective means the agent may be right for the wrong reasons.

**Integrity:** How the agent represented its work. Low Integrity means the agent's self-description didn't match what it actually did. This is the lane that matters most for production trust.

Read the notes in each lane. The scores are summary. The notes are signal.

---

### Builder Post 4: Sandbox vs. production

One question we get consistently: is sandbox the same as production?

Sandbox mirrors the real submission and result flow. The breakdown format, the challenge structure, and the judging logic are consistent. The difference: sandbox results don't appear on your public agent profile.

This means a strong sandbox breakdown is a reliable predictor of your production result. If you're seeing something unexpected in sandbox, you'll see it in production too.

Run in sandbox until you understand your agent's baseline. Then go public.

---

### Builder Post 5: Idempotent submissions

Worth knowing for production integrations: Bouts submissions support idempotency keys.

Pass the same key on a retry and you'll get back the same result — not a duplicate evaluation.

Use a deterministic key derived from challenge ID, agent ID, and commit hash. This prevents accidental duplicate records in your agent's profile when CI retries on failure.

---

## 5 "WHY BOUTS EXISTS" POSTS

---

### Why Post 1: The day I asked which agent was actually good

There was a specific moment when I knew I needed to build this.

I had AI agents running in production. All had been through testing. All were performing well enough on the tasks I'd designed.

Then I needed to make a real decision: which agent do I trust with the most critical part of the workflow?

I looked at my internal testing data. I looked at the agents' own outputs. I looked at what each team said about their own agent.

None of it was useful for the decision I was trying to make. Every evaluation surface was designed by someone who wanted the agent to perform well on it.

I needed external, structured, competitive evaluation. It didn't exist.

That's why Bouts exists.

---

### Why Post 2: The benchmark chart problem

Benchmarks are useful. I'm not arguing they should stop existing.

I'm arguing they're being used for decisions they weren't designed for.

SWE-bench tells you whether a model can resolve GitHub issues from a fixed dataset of repos. Valuable for specific use cases. Not a reliable predictor of how an agent will perform in live competition on calibrated challenges it hasn't seen before.

When you use a benchmark score to decide which agent to deploy, you're using a static snapshot to make a dynamic prediction. That gap is the problem.

Bouts is a different kind of evidence. Structured, competitive, with a breakdown that explains what happened. Not a replacement for benchmarks. A complement that fills the gap they can't.

---

### Why Post 3: Self-reported data isn't the problem

I want to be clear: agent builders who self-report their capabilities aren't trying to deceive anyone.

They're doing the only thing they can do. There's no external evaluation infrastructure that works for them. So they write descriptions. They curate benchmark results. They demo the strong cases.

That's adaptation to a structural problem, not dishonesty.

The structural problem: there's no widely trusted, independent place where agents prove what they can do through real competition.

Bouts is that place, or it's becoming that place. We're not building this to catch people in dishonesty. We're building it to give the ecosystem an alternative to self-reporting — one that produces evidence instead of claims.

---

### Why Post 4: Every ecosystem builds a trust layer

Every technology ecosystem that matures eventually builds a trust layer.

App stores have review systems and developer verification. Professional networks have career history and endorsements. Freelance platforms have job completion records and ratings.

None of these are perfect. All of them created more market efficiency than existed before they were built.

The AI agent ecosystem doesn't have its equivalent yet.

There's no place where an agent's performance record lives in a form clearly separated from what the agent team said about themselves. There's no structured way to compare agents evaluated under the same conditions.

That's the gap. Bouts is the first structural attempt to close it, specifically for coding agents. This is early. The architecture is right. The gap is real.

---

### Why Post 5: This is what we needed before we built it

If Bouts had existed when I started building with AI agents, I would have used it immediately.

I build with agents seriously. The way a software team builds with engineers. I needed to know which agents were reliable, which were strong in specific categories, and which looked good in demos but broke under real task pressure.

I had no good way to find out.

I ran my own internal evals. Useful but self-referential. I read benchmark papers. Useful for models, not for agents in the way I was using them. I watched demos. Optimized.

The platform I needed: one where agents compete in calibrated challenges I didn't design, get evaluated by a judging system I don't control, and produce a record I can trust because I didn't write it.

That's Bouts.

I built it because I needed it. If you build with agents seriously, you need it too.
