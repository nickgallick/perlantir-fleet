# HEARTBEAT — Pixel

Pixel's recurring self-improvement cycle. Run periodically to stay sharp, current, and calibrated.

---

## Phase 1: Design Trend Research

### 1.1 Pull Repo Updates
Check for updates in our source repositories:
- shadcn/ui — new components, changed APIs, deprecations
- radix-ui/primitives — new primitives, accessibility improvements
- tailwindcss — new utilities, configuration changes
- lucide-icons — new icons, renamed icons
- react-native-paper — component updates, theming changes
- nativewind — version compatibility, new features
- recharts — chart types, API changes

Log any relevant changes to `/data/.openclaw/workspace-pixel/research-logs/`.

### 1.2 Component Library Updates
For each library with updates:
- Note new components that could improve our designs
- Flag deprecated components we currently use
- Identify API changes that affect our design specifications
- Update the design-system skill if our token or component references need adjustment

### 1.3 Search for Design Trends
Run research queries to stay current:
- "UI design trends 2026"
- "dark mode design best practices"
- "dashboard UI patterns"
- "mobile app design patterns"
- "design system updates"
- "accessibility design advances"
- "micro-interaction design"
- "data visualization design"

Evaluate findings against our design principles. Only adopt trends that serve clarity, hierarchy, and user needs. Log findings in research logs.

---

## Phase 2: Design Review Analysis

### 2.1 Review Pattern Tracking
Analyze recent design reviews in `/data/.openclaw/workspace-pixel/design-reviews/`:
- Identify the most common issues flagged
- Track which review points (1-10) catch the most problems
- Note if certain brands have recurring issues
- Look for patterns in P0/P1 issues — are they preventable upstream?
- Update the design-review-protocol skill with any new patterns

### 2.2 Developer Profile Update
Review handoffs to Maks and other developers in `/data/.openclaw/workspace-pixel/developer-profiles/`:
- Track which specs needed clarification after handoff
- Note areas where developers consistently need more detail
- Update developer profiles with implementation preferences
- Calibrate handoff detail level based on feedback

---

## Phase 3: Self-Improvement

### 3.1 Update Skills
Based on research and review analysis:
- Update design-system skill with new tokens or components
- Refine typography skill with new font recommendations
- Enhance color-theory skill with new palette techniques
- Improve layout-composition skill with new patterns
- Add new component patterns to component-architecture skill
- Update mobile-ux and web-ux skills with platform changes
- Strengthen accessibility-design skill with new techniques

### 3.2 Research Log
Write findings to `/data/.openclaw/workspace-pixel/research-logs/` with:
- Date of research
- Sources consulted
- Key findings
- Relevance to our brands
- Action items (skills to update, patterns to adopt/avoid)

### 3.3 Source Recommendations
When high-quality new sources are discovered:
- Evaluate against criteria in the pixel-research skill
- Add to recommended sources if they meet the bar
- Update framework-source-code skill if new repos are relevant

---

## Design Ecosystem Monitoring (every cycle)

### Pull repo updates
```bash
cd /data/.openclaw/workspace-pixel/repos
for repo in v0-sdk magicui awesome-shadcn framer-motion v0-mcp-source shadcn-ui; do
  [ -d "$repo/.git" ] && cd /data/.openclaw/workspace-pixel/repos/$repo && git pull 2>/dev/null
done
```

### Check for updates
- V0 SDK: new methods, breaking changes, new models
- Magic UI: new animated components
- Shadcn ecosystem: new community registries
- Framer Motion: new animation APIs
- V0 MCP: new tools or parameter changes

### Research (rotate with existing searches)
- "V0 new features 2026"
- "Magic UI new components"
- "Shadcn UI community registry new"
- "Framer Motion React animation patterns"

---

## Phase 4: Design Developer Pattern Analysis

### 4.1 Analyze Review History
Look across all design reviews for meta-patterns:
- Are designs getting better over time? Measure by verdict distribution.
- Which design principles are hardest to implement? Target those for better tooling.
- Are there screens or flows that consistently need more iterations?
- What types of designs get APPROVED on first review?

### 4.2 Update Calibration
Based on analysis:
- Adjust review strictness if needed (too many false positives? too lenient?)
- Update confusion testing personas if new user types emerge
- Refine edge state checklist based on real issues found
- Calibrate Stitch prompts based on generation quality patterns

## Blocked Task Dedup Rule
Before re-engaging any blocked/stalled item, check if new context exists since your last action on it (new message from another agent, status change, new file, or explicit directive). If nothing changed → skip it entirely. Do not re-comment, do not re-alert, do not re-attempt. Only re-engage when new information arrives. This prevents wasting tokens on unchanged blockers.
