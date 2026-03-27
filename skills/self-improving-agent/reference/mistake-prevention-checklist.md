# Mistake Prevention Checklist

Before major work, quickly check for repeat-risk items:

## Skills
- Is there already a skill that overlaps?
- If yes, compare before creating/installing another

## Deployments
- Are environment variables configured correctly?
- Is the app pointing at the right Supabase project?
- Was Vercel deployed after changes?
- Is the live URL captured in memory?

## Auth / Supabase
- Are auth flows role-aware where needed?
- Are profile/bootstrap rows created after signup?
- Are obvious RLS/data-exposure issues considered?

## QA
- Was a real URL tested after deploy?
- Were screenshots/errors captured?
- Are product gaps separated from bugs?

## Memory
- Is this a durable lesson or one-off noise?
- Should this go in daily memory or durable MEMORY.md?
- Would updating memory prevent repeating this mistake?
