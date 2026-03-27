# Reddit Strategy for Developer Products

## Core Rule: Comment-First Approach

Reddit rewards members, not marketers. The algorithm and community both punish accounts that only post their own stuff.

**Before any product post:**
1. Have 2+ weeks of genuine comment history in the target subreddit
2. Comment on others' posts with real technical insight (not "great post!")
3. Answer questions in the subreddit — build reputation
4. Only then share your own work, framed as contribution not promotion

**Account health signals Reddit checks:**
- Comment-to-post ratio (aim for 10:1 minimum)
- Account age (new accounts get auto-filtered in most dev subs)
- Karma distribution across subreddits
- Post history — if every post is self-promotion, you're flagged

## Subreddit Playbook

### r/LocalLLaMA (~800K members)
**Audience:** Local model enthusiasts, fine-tuners, quantization nerds, open-weight advocates
**What gets upvoted:**
- Benchmarks comparing local models to closed APIs
- Tools that make local models more competitive
- Anything that levels the playing field vs OpenAI/Anthropic
- Performance optimization tricks
- Fair comparisons (not cherry-picked)

**What gets flagged:**
- Closed-source products without local model support
- "AI wrapper" vibes — products that just call GPT
- Marketing language ("revolutionary", "game-changing")
- Paywalled tools without free tier

**Angle template:** "I built [X] that lets you [specific capability] with your local models. Here's how [local model] compared to [closed model] — results surprised me."

**Post format:** Text post with inline results/screenshots. Not a link post to your landing page.

### r/MachineLearning (~3M members)
**Audience:** ML researchers, PhD students, industry ML engineers, paper readers
**What gets upvoted:**
- Novel evaluation methodologies
- Reproducible results with code
- Honest analysis of limitations
- Papers and research-adjacent projects
- Systematic comparisons (not vibes-based)

**What gets flagged:**
- Products without technical substance
- "We used AI to..." without depth
- Anything that feels like a press release
- Claims without evidence

**Angle template:** "[D] We built a competitive evaluation platform for coding agents — here's what we learned about [specific insight from data]"

**Post format:** Discussion [D] tag. Lead with insight, not product. Link to product is secondary — buried in the post or comments.

### r/artificial (~900K members)
**Audience:** AI generalists, enthusiasts, some technical, some not
**What gets upvoted:**
- Demos that show AI doing something impressive
- Accessible explanations of complex AI concepts
- Tools people can try immediately
- Competitive/comparison content

**What gets flagged:**
- Hype without substance
- "My startup" posts without providing value
- Duplicate content from other subs

**Angle template:** "I built an arena where AI agents compete in coding challenges — here's what happens when GPT-5 faces Claude Opus [with results]"

### r/SideProject (~200K members)
**Audience:** Indie builders, solo founders, people building in public
**What gets upvoted:**
- Build stories with real numbers
- Technical deep-dives on interesting architecture decisions
- Revenue/growth transparency
- "Here's what I learned building X"

**What gets flagged:**
- Pure product launches with no story
- "Check out my SaaS" one-liners
- Fake engagement ("wow this is amazing" from alt accounts)

**Angle template:** "I've been building [product] for [timeframe] — here's the architecture decisions that shaped it and what I'd do differently"

### r/webdev (~2M members)
**Audience:** Web developers, frontend/backend/fullstack, framework users
**What gets upvoted:**
- Technical implementations with code
- Stack decisions and tradeoffs
- Performance optimization stories
- Open source tools they can use

**What gets flagged:**
- Non-web-specific products
- "Hire me" or obvious self-promotion
- Products without technical discussion

**Angle template:** "Show /r/webdev: How I built [specific technical feature] using [stack] — here's the code and architecture"

### r/startups and r/entrepreneur
**Audience:** Founders, aspiring founders, business-minded builders
**What gets upvoted:**
- Traction stories with real metrics
- Lessons learned (especially failures)
- Market analysis and positioning decisions
- Revenue/pricing strategy transparency

**Angle template:** "I built [product] targeting [specific niche]. Here's the market gap I found and how I'm approaching distribution."

## Post Timing

| Subreddit | Best Post Time (UTC) | Best Days | Why |
|-----------|---------------------|-----------|-----|
| r/LocalLLaMA | 14:00-16:00 | Tue-Thu | US afternoon, catches both US and EU |
| r/MachineLearning | 13:00-15:00 | Mon-Wed | Workweek, research-active hours |
| r/artificial | 14:00-17:00 | Any weekday | Broad audience, consistent traffic |
| r/SideProject | 14:00-16:00 | Mon, Sat | Monday for work crowd, Saturday for builders |
| r/webdev | 14:00-16:00 | Tue-Thu | Workweek engagement |

## Post Format Rules

1. **Title:** Specific, no clickbait. Include what it does and one concrete detail.
   - ✅ "I built an ELO rating system for AI coding agents — here's what happened when local models competed against GPT-5"
   - ❌ "Check out my new AI platform!"
   - ❌ "This AI tool is going to change everything"

2. **Body:** Lead with value. First paragraph should teach or reveal something — not pitch.

3. **Media:** Include screenshots, results tables, or short GIFs. Text-only posts get less engagement in most subs.

4. **Links:** Put your product link naturally in the body or comments, never as the post URL (except r/SideProject which allows link posts).

5. **Engagement:** Reply to EVERY comment in the first 2 hours. Reddit's algorithm heavily weights early engagement.

6. **Cross-posting:** Don't post the same content to multiple subs simultaneously. Stagger by 2-3 days and adjust the angle for each community.

## Comment Strategy

When others post about related topics (AI agents, benchmarks, coding challenges):
- Add genuine technical insight in comments
- Mention your product only if directly relevant and helpful
- Format: "[Useful insight about the topic]. We found similar results when building [product] — [specific data point]."
- Never reply to every related post — that's obvious astroturfing
