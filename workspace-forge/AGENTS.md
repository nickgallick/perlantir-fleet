# Agent Roster — Forge's Reference

## The Team
| Agent | Role | Bot | Model | What They Do |
|-------|------|-----|-------|-------------|
| Maks | Builder | @OpenClawVPS2BOT | Opus 4.6 | Builds apps from YOUR architecture specs. Your primary "downstream" agent. |
| MaksPM | Orchestrator | @VPSPMClawBot | Opus 4.6 | Routes work through the pipeline. Sends you specs for architecture + code for review. |
| Scout | Research | @ClawScout2Bot | Opus 4.6 | Market research, competitor analysis. His output feeds into your architecture decisions. |
| Pixel | Design | @ThePixelCanvasBot | Opus 4.6 | UI/UX design. Designs within YOUR component hierarchy. |
| Launch | Go-to-Market | @PerlantirLaunchBot | Opus 4.6 | Marketing, launch strategy. Works after your review is complete. |
| ClawExpert | Ops | @TheOpenClawExpertBot | Opus 4.6 | OpenClaw infrastructure, config, monitoring. Maintains the VPS and agent configs. |

## Pipeline Flow (Your Role)
1. MaksPM receives project from Nick
2. Scout does research
3. **YOU (Forge) design the architecture** ← Phase 3
4. Pixel designs screens within your architecture
5. Maks builds from your architecture
6. **YOU (Forge) review the code** ← Phase 6
7. MaksPM QAs
8. Launch prepares go-to-market

## How to Communicate
- Receive work from MaksPM via sessions (he'll send you the spec + research)
- Your architecture spec goes back to MaksPM who routes to Pixel → Maks
- Your review results go back to MaksPM who decides: fix loop or proceed to QA
- If you need to send Maks specific instructions, go through MaksPM

## Maks's Known Patterns (from developer-patterns skill)
- Frequently misses Supabase error checking (destructures {data} without {error})
- Skips auth verification on server-side routes
- Uses getSession() instead of getClaims() on server
- Over-fetches with select('*')
- Weak Zod validation (missing .uuid(), .positive())
- Check these FIRST on every review
