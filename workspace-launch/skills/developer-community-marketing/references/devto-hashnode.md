# Dev.to / Hashnode Blog Strategy

## Purpose

Technical blog posts serve two functions:
1. **SEO** — Long-tail keyword traffic that compounds over months
2. **Credibility** — "This team writes real technical content" = trust signal

## Post Structure

### Launch Post (Announcement)

```
Title: "How We Built [Product] — [Specific Technical Angle]"
  or: "Introducing [Product]: [What It Does] for [Who]"

Intro (2-3 paragraphs):
  - The problem in concrete terms
  - Why existing solutions fall short
  - What you built (1 sentence)

Section 1: Architecture / How It Works
  - Diagrams, code snippets, system design
  - Technology decisions with reasoning
  - What you considered and rejected

Section 2: The Interesting Problem
  - Pick one technical challenge you solved
  - Deep-dive with code
  - This is what makes the post worth reading

Section 3: Results / What We Learned
  - Data from real usage
  - Surprises, failures, course corrections
  - Screenshots of the product

Section 4: What's Next
  - Roadmap transparency
  - Open questions you're still solving

CTA:
  - Try it: [link]
  - GitHub: [link if applicable]
  - Follow for updates
```

### Technical Deep-Dive (Ongoing)

Posts about specific technical challenges:
- "How We Implemented ELO Ratings for AI Agents"
- "Building a Fair Weight Class System for AI Models"
- "Real-Time Replay Viewer: Architecture Behind Agent Arena"
- "Scaling Concurrent AI Agent Battles with [Technology]"

These posts target long-tail keywords and build domain authority.

### Series Approach

Dev.to and Hashnode both support article series. Use them:
- "Building Agent Arena" series (3-5 posts over 2-3 weeks)
- Each post covers a different technical aspect
- Cross-links between posts (SEO internal linking)
- Series get more followers than standalone posts

## Tag Optimization

### Dev.to Tags (max 4 per post)
Primary: `ai`, `webdev`, `javascript`, `typescript`
Secondary: `machinelearning`, `opensource`, `tutorial`, `productivity`
Niche: `nextjs`, `supabase`, `react`

Pick tags by audience:
- AI audience: `ai`, `machinelearning`, `opensource`
- Web dev audience: `webdev`, `javascript`, `nextjs`
- General builder: `productivity`, `tutorial`, `beginners`

### Hashnode Tags
Similar to Dev.to. Also supports custom tags for your blog.

## Cross-Posting Strategy

1. **Publish on Dev.to first** (larger built-in audience, faster indexing)
2. **Cross-post to Hashnode** 2-3 days later with canonical URL pointing to Dev.to
3. **Or** publish on your own blog first, cross-post to both with canonical URL
4. Never publish identical content simultaneously — Google penalizes duplicate content

## Writing Rules for Developer Audience

- **No fluff intros** — Skip "In today's fast-paced world of AI..."
- **Code early** — Show code in the first 3 scrolls
- **Diagrams > paragraphs** — Use Mermaid, Excalidraw, or simple ASCII diagrams
- **Be specific** — "We use PostgreSQL with row-level security" not "we use a database"
- **Show mistakes** — "Our first approach failed because..." builds massive credibility
- **Include runnable examples** — CodeSandbox, Repl.it, or GitHub links
- **Keep paragraphs short** — 2-3 sentences max. Developers skim.

## SEO Targeting

Target keywords developers actually search:
- "[Technology] tutorial" (e.g., "ELO rating system tutorial")
- "How to build [X]" (e.g., "how to build AI agent competition")
- "[Product category] comparison" (e.g., "AI benchmark comparison")
- "[Framework] + [use case]" (e.g., "Next.js real-time leaderboard")

Include the target keyword in:
- Title (first 60 characters)
- First paragraph
- One H2 heading
- Image alt text
- Meta description (if platform supports it)
