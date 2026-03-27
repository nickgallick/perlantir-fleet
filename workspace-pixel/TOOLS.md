# TOOLS.md — Pixel Design Resources

## Design Tool: Stitch (MANDATORY)

All designs must be produced in Stitch — not spec documents, not mockups, not Figma exports.

- **Stitch MCP**: Available via mcporter bridge
- **Run Stitch**: `mcporter call stitch <method>`
- **Stitch docs**: https://stitch.perlantir.ai (or check mcporter)

## Nick's Design Standard

- **Brand**: Enterprise Confidence with Clean Authority
- **References**: Accenture, Atlassian, Adobe, NVIDIA — clean, structured, authoritative
- **Never**: Gradients, blobs, generic AI design, decorative animations without purpose
- **Typography**: Sharp, structured — Inter, Geist, or similar enterprise-grade fonts
- **Colors**: Restrained palette — dark backgrounds or clean whites, one accent color max
- **Spacing**: Generous, intentional — never cramped

## Active Projects

### Bouts / Agent Arena
- **Live URL**: https://agent-arena-roan.vercel.app
- **GitHub**: https://github.com/nickgallick/Agent-arena
- **Stack**: Next.js App Router, Tailwind, Supabase
- **Design system**: Dark theme, competitive/gaming aesthetic with enterprise polish
- **Screenshots**: in /data/.openclaw/workspace-forge/ (QA screenshots from Forge)

## Design Deliverables Standard

Every design must include:
1. Desktop (1440px)
2. Mobile (375px)
3. All interactive states (hover, active, disabled, loading, empty, error)
4. Component specs: spacing, typography scale, color tokens
5. Implementation notes for Maks

## GitHub Access

- **Token**: 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
- **Agent Arena**: `git clone https://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@github.com/nickgallick/Agent-arena.git`

## Fleet Context

- Pixel reports to ClawExpert (COO)
- Pipeline: Forge (architecture) → Pixel (design) → Maks (build)
- Never design without Forge's architecture spec first
- Handoff to Maks: implementation-grade specs, zero ambiguity
