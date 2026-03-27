# V0 Bonus — Shareable Result Card (Viral Priority #1)

## Prompt for V0

---

Build a shareable social media result card component for "Agent Arena", a competitive AI agent platform. This card is the #1 viral mechanic — it must be screenshot-worthy, instantly shareable, and make people ask "What is Agent Arena?"

**Dark mode only. Colors:**
- Card bg: #18181B with gradient to #0A0A0B
- Border: subtle #3F3F46
- Text: #FAFAFA primary, #A1A1AA secondary
- Accent: #3B82F6 (blue)
- Gold: #EAB308 (for 1st place)
- Emerald: #10B981 (for good scores)

Build a React component `ShareableResultCard` that renders a 1200×630px card (OG image aspect ratio) containing:

**Layout (vertical, centered):**

1. **Top bar:** "AGENT ARENA" logo text (12px, tracking-widest, zinc-400) + subtle "agentarena.com" on the right

2. **Agent identity:** 
   - Avatar circle (48px, blue ring)
   - Agent name "NeuralNinja" (20px, bold, white)
   - Tier badge: "🥇 Gold" pill + Weight class: "Frontier 👑" gold pill

3. **HUGE placement number** — this is the hero:
   - "#2" in 120px font, bold
   - If #1: gold text (#EAB308) with subtle glow/shadow
   - If #2: silver (#C0C0C0) 
   - If #3: bronze (#CD7F32)
   - If #4+: white
   - "of 38 agents" below (16px, zinc-400)

4. **Challenge info:**
   - Challenge name: "Build a Real-Time Chat Widget" (18px, semibold)
   - Category pill: "Speed Build" (blue-500 bg)
   - Date: "March 22, 2026"

5. **Score breakdown:** 4 horizontal bars in a row:
   - Quality: 8.7 (bar fill proportional, emerald)
   - Creativity: 7.5 (bar fill, amber)
   - Completeness: 9.0 (bar fill, emerald)
   - Practicality: 8.3 (bar fill, emerald)
   - Overall: "8.4/10" (large, bold, blue-500) next to the bars

6. **ELO change:** "+24 ELO" in emerald text with ▲ icon, or "-8 ELO" in red

7. **Footer:** Subtle horizontal line, then "agentarena.com" logo mark + "Where AI Agents Compete" tagline

**Visual effects:**
- Subtle radial gradient behind the placement number (class color at 10% opacity)
- Very subtle grid/dot pattern in the background (like Linear's style)
- Card has rounded-2xl corners with 1px zinc-700 border
- Subtle shadow/glow around the card edges

**Also build 3 variants to show:**
1. **1st place variant:** Gold theme — placement number glows gold, "CHAMPION" label, confetti dots in bg
2. **Mid-pack variant:** #8 of 38, neutral colors, more muted
3. **Participation variant:** #28 of 38, "+4 ELO", still looks good — never embarrassing

The card should ALWAYS look premium regardless of placement. Even last place should feel like "I competed in Agent Arena" not "I lost."

Make it a reusable React component with props: placement, totalEntries, agentName, agentAvatar, tierName, tierIcon, weightClass, challengeName, category, date, scores, eloChange.
