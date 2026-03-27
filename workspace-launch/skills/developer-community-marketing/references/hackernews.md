# Hacker News Strategy

## Show HN Format

Show HN is the only acceptable self-promotion format on HN. Everything else gets flagged or ignored.

### Title Formula

```
Show HN: [Product Name] – [What it does in plain English]
```

**Rules:**
- Max ~80 characters (longer titles get truncated)
- No superlatives ("best", "revolutionary", "game-changing")
- No emoji
- No ALL CAPS words
- Be specific about what it does, not vague about the category
- Technical specificity wins — "ELO rating system for AI coding agents" beats "AI competition platform"

**Examples:**
- ✅ "Show HN: Agent Arena – ELO ratings and weight classes for AI coding agents"
- ✅ "Show HN: Agent Arena – AI agents compete in timed coding challenges, ranked by model tier"
- ❌ "Show HN: Agent Arena – The Future of AI Agent Evaluation"
- ❌ "Show HN: We built an amazing platform for AI competitions"

### First Comment (Critical)

The Show HN first comment is the most important piece of copy you'll write. It determines whether the post gets upvoted or ignored.

**Structure:**
1. **What it is** (1-2 sentences, plain English)
2. **Why you built it** (the personal/technical motivation — HN loves genuine origin stories)
3. **How it works technically** (architecture, stack, interesting decisions — 2-3 sentences)
4. **Honest limitations** (what it doesn't do yet, known issues — THIS IS CRITICAL)
5. **What you're looking for** (feedback, specific questions for the community)

**Template:**
```
Hey HN, I built [Product] because [genuine motivation].

[1-2 sentences on what it does concretely]

Technically, it [interesting architecture detail]. We chose [technology decision] because [reasoning]. The [specific feature] works by [brief technical explanation].

Some limitations worth noting:
- [Honest limitation 1]
- [Honest limitation 2]
- [What you plan to add]

I'd love feedback on [specific question]. The [component] is open source at [link].

Stack: [concise stack list]
```

**What HN values in first comments:**
- Technical honesty (admitting what's hard, what's not solved)
- Architecture decisions with reasoning
- Open source components
- Specific questions (not "what do you think?")
- Brevity — respect their time

**What kills a Show HN:**
- Marketing language in the first comment
- No technical depth
- Defensive responses to criticism
- Not responding to comments (fatal — HN penalizes inactive threads)

## Posting Time

| Time (UTC) | Quality | Why |
|------------|---------|-----|
| 14:00-15:00 | Best | US East Coast morning, catches full US workday |
| 15:00-17:00 | Good | US morning through lunch |
| 11:00-13:00 | Decent | Catches EU afternoon + US East morning |
| 18:00+ | Poor | US afternoon, less engagement velocity |

**Best days:** Tuesday, Wednesday, Thursday
**Avoid:** Friday afternoon, weekends (lower traffic, but less competition — some use this strategically)

## What HN Upvotes

1. **Technical novelty** — "We solved X in an unusual way"
2. **Developer tools** — HN is builders. Tools for builders always resonate.
3. **Honest post-mortems** — "Here's what went wrong and what we learned"
4. **Open source** — Even partial OSS gets more upvotes than fully closed
5. **Data-driven insights** — "We ran 1000 agent battles. Here's what the data shows."
6. **Elegant simplicity** — Simple solutions to real problems beat complex solutions to imaginary ones
7. **Fair comparisons** — Benchmarks that don't cherry-pick

## What HN Downvotes/Flags

1. **Marketing speak** — Any sentence that sounds like a landing page
2. **Hype without substance** — Claims without evidence
3. **Defensive founders** — Arguing with criticism instead of engaging
4. **"AI wrapper" products** — Just calling an API with a UI on top
5. **Ignoring comments** — Post and ghost = thread death
6. **Astroturfing** — Fake accounts commenting "wow great product"
7. **Duplicate posts** — Reposting if first attempt didn't get traction (wait 2+ weeks)

## Comment Engagement Rules

- **Respond to every comment** in the first 3 hours minimum
- **Be technically specific** in responses — code snippets, architecture details
- **Embrace criticism** — "Good point, we haven't solved X yet. Here's our current thinking..."
- **Never be defensive** — HN users can smell it instantly
- **Add value in replies** — Each response should teach something or reveal a decision
- **Upvote good questions** about your post (yes, this matters for thread ranking)

## HN-Specific Angles for AI Products

- Lead with the evaluation methodology, not the platform
- Compare to existing benchmarks (MMLU, HumanEval) and explain why competitive eval is different
- Mention the weight class system — HN loves elegant classification systems
- If any component is open source, lead with that
- Data from real competitions >> theoretical architecture
