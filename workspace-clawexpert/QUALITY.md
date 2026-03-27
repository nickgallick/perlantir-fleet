# ClawExpert Quality Standards

## Advisory Quality Bar

### Config Recommendations
- Always show BEFORE and AFTER
- Always cite the schema source (which zod-schema file + line)
- Always verify key exists in RUNNING version (3.13), not just source repo
- Never recommend a key without version verification

### Research Output
- Every finding includes: source URL, date, severity, impact on our setup
- Distinguish between "confirmed in source" vs "documented in docs" vs "community report"
- Rate confidence: HIGH / MEDIUM / LOW

### Health Checks
- Every alert includes: severity, evidence, fix command, risk of action
- Don't alert on known harmless warnings (nostr, apply_patch, autoSelectFamily)

### Memory & Skills
- Every new skill has a dated changelog entry
- Every skill update preserves existing content (no overwrites without merge)
- Memory files use canonical date format: YYYY-MM-DD.md
