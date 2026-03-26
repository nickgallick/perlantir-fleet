# SKILL — Stitch Mastery

Pixel's Stitch MCP design generation knowledge. Stitch is our primary tool for creating designs — a generative design tool accessed via MCP commands.

---

## Automated Design Pipeline

When creating designs, Pixel follows this 7-phase pipeline:

### Phase 1: Create Project
Set up the Stitch project for the design work.
```
Command: create_project
Parameters:
  - name: Project name (descriptive, kebab-case)
  - description: What this project is for
```

### Phase 2: Craft the Prompt
Write a detailed generation prompt using brand tokens and design specifications.

#### Prompt Template
```
Create a [screen type] for [brand name].

## Brand Tokens
- Background: [hex]
- Primary Color: [hex]
- Text Color: [hex]
- Heading Font: [font name]
- Body Font: [font name]
- Border Radius: [value]

## Screen Requirements
[Detailed description of what the screen should contain]

## Layout
[Specific layout requirements]

## Components
[List of components with their states and content]

## Typography
- Page title: [font], [size], [weight]
- Section headings: [font], [size], [weight]
- Body text: [font], [size], [weight]
- Captions: [font], [size], [weight]

## Spacing
- Card padding: [value]
- Section gap: [value]
- Element gap: [value]

## Specific Requirements
[Any special instructions, edge cases, or precise specifications]
```

### Phase 3: Generate Screen
Send the prompt to Stitch for generation.
```
Command: generate_screen
Parameters:
  - project_id: From Phase 1
  - prompt: From Phase 2
  - name: Screen name (descriptive)
```

### Phase 4: Pull and Render
Retrieve the generated design and render it for visual review.
```
Commands:
  - get_screen_code: Get the generated code
  - get_screen_image: Get the rendered screenshot
```

Render the design in a headless browser to get a screenshot for visual review. Never review code alone — always visually verify.

### Phase 5: Review
Apply the full 10-point design review protocol to the rendered screenshot:
1. Visual Hierarchy
2. Layout & Spacing
3. Typography
4. Color
5. Components
6. Interaction Design
7. Edge States
8. Accessibility
9. Confusion Testing
10. Brand Consistency

### Phase 6: Iterate (Max 3x)
If the review identifies issues:
1. Document the specific issues found
2. Craft an updated prompt addressing each issue
3. Regenerate the screen
4. Re-review

**Maximum 3 iterations per screen.** If the design isn't meeting standards after 3 iterations, reassess the approach — the prompt strategy may need rethinking, not just tweaking.

### Phase 7: Approve and Hand Off
When the design passes review:
1. Record the APPROVED verdict with full review notes
2. Create a complete handoff specification (see developer-handoff skill)
3. Save the design to `/data/.openclaw/workspace-pixel/stitch-pulls/`
4. Notify that the design is ready for Maks to build

---

## Stitch MCP Commands

### create_project
Creates a new design project.
```
Parameters:
  name: string        — Project name
  description: string — What the project is for
Returns:
  project_id: string  — Use this for all subsequent commands
```

### generate_screen
Generates a new screen design.
```
Parameters:
  project_id: string  — Project to generate in
  prompt: string      — Detailed design prompt
  name: string        — Screen name
Returns:
  screen_id: string   — Reference for this screen
```

### list_projects
Lists all Stitch projects.
```
Returns:
  projects: array     — List of projects with IDs and names
```

### list_screens
Lists screens within a project.
```
Parameters:
  project_id: string  — Project to list screens for
Returns:
  screens: array      — List of screens with IDs and names
```

### get_screen_code
Retrieves the generated code for a screen.
```
Parameters:
  screen_id: string   — Screen to get code for
Returns:
  code: string        — Generated HTML/CSS/JS code
```

### get_screen_image
Retrieves the rendered screenshot of a screen.
```
Parameters:
  screen_id: string   — Screen to get image for
Returns:
  image: binary       — Rendered screenshot
```

### build_site
Builds a complete site from all screens in a project.
```
Parameters:
  project_id: string  — Project to build
Returns:
  url: string         — Preview URL for the built site
```

---

## Prompt Tips

### Be Specific
❌ "Create a dashboard"
✅ "Create a dark-themed analytics dashboard with a sidebar navigation on the left (240px wide, #111D30 background), a top bar with search and user avatar, and a content area containing: 4 stat cards in a row showing Revenue ($124,500 +12.3%), Users (8,432 +5.7%), Conversion (3.24% -0.8%), Active Sessions (1,247 live). Below the stats, a line chart showing revenue over the last 30 days, and a data table showing recent transactions."

### Include Brand Tokens
Always specify exact colors, fonts, and spacing. Stitch doesn't know our brands unless we tell it.

### Specify Content
Use realistic content, not lorem ipsum. Real names, real numbers, real text. This reveals layout issues early.

### Describe States
If the screen has interactive elements, describe their visual states in the prompt.

### Reference Components
Name specific component types (shadcn Button, Card, Table) so Stitch generates compatible output.

---

## Multi-Screen Projects

When designing multi-screen flows:
1. Create one project for the entire flow
2. Generate screens in order (maintain design consistency)
3. Reference previous screens in prompts ("matching the style of the dashboard screen")
4. Review screens individually AND as a flow
5. Ensure navigation consistency across all screens

---

## Limits

- **Standard generations**: 350 per month
- **Experimental generations**: 50 per month
- Use standard for production designs
- Use experimental for exploratory concepts and style testing
- Track usage to avoid hitting limits mid-project
