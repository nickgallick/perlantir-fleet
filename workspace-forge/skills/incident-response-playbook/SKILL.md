---
name: incident-response-playbook
description: Structured incident response procedures for security breaches, data exposure, account compromise, and service abuse. Use when a security incident is detected or suspected — credential leak, data breach, unauthorized access, compromised dependency, defacement, or any event requiring immediate security response. Provides the step-by-step runbook for the first 30 minutes (golden hour), evidence preservation, containment strategies, communication templates, and post-incident analysis. Designed for a small team (Perlantir) where the same people build and respond.
---

# Incident Response Playbook

## When to Activate This Playbook

Activate for ANY of these:
- Confirmed unauthorized data access
- Credential/API key exposed in public (GitHub, logs, error messages)
- Compromised dependency in production
- Unusual database activity or mass data export
- Account takeover (user or admin)
- Malicious code detected in codebase
- Service abuse (cost spike, API abuse)
- Report from external researcher or user

## Phase 1: Triage (First 5 Minutes)

### Immediate Assessment
1. **What happened?** One sentence: "Service role key found in GitHub commit" / "Unusual bulk data export from Supabase"
2. **When?** When was it discovered? When did it likely start?
3. **Is it ongoing?** Is the attacker still active? Is data still being exposed?
4. **Blast radius estimate**: What systems/data could be affected?

### Severity Classification
| Severity | Criteria | Response Time |
|----------|----------|---------------|
| **SEV-1** | Active data breach, production RCE, credential leak in public | Immediate — drop everything |
| **SEV-2** | Compromised dependency, unauthorized access detected and stopped | Within 1 hour |
| **SEV-3** | Potential vulnerability discovered, no exploitation confirmed | Within 24 hours |
| **SEV-4** | Security improvement needed, no active risk | Next sprint |

### Notify
```
SEV-1/SEV-2: Message Nick immediately
Template: "🚨 Security Incident — [SEV-X]: [one-line description]. Currently [containing/investigating]. [What's known so far]."
```

## Phase 2: Contain (Minutes 5-15)

### Containment Actions by Incident Type

#### Exposed Credentials
```bash
# 1. Rotate the exposed credential IMMEDIATELY
# Supabase service role key:
# → Supabase Dashboard → Settings → API → Regenerate service_role key
# → Update all server environments with new key
# → Restart all services

# Stripe secret key:
# → Stripe Dashboard → Developers → API keys → Roll key
# → Update environment, redeploy

# GitHub token:
# → GitHub → Settings → Developer settings → Personal access tokens → Revoke
# → Generate new token with minimum permissions

# 2. Check if credential was used maliciously
# Supabase: Check logs for API calls with the old key
# Stripe: Check for unauthorized charges/refunds
# GitHub: Check for unauthorized commits/repo access
```

#### Compromised Dependency
```bash
# 1. Remove or pin the compromised package
npm uninstall <package>  # or pin to last-known-good version

# 2. Check if postinstall script ran
# Look for persistence mechanisms:
ls ~/.config/systemd/user/  # systemd services
crontab -l                   # cron jobs
cat ~/.bashrc ~/.zshrc       # shell modifications

# 3. Check for token theft
# Were npm tokens, GitHub tokens, or env vars accessible?
npm token list  # Revoke all tokens, regenerate

# 4. Check if any of YOUR packages were republished
npm view <your-package> time --json  # Any unexpected versions?

# 5. Rebuild from clean state
rm -rf node_modules package-lock.json
npm install  # Fresh install from registry
```

#### Unauthorized Data Access
```bash
# 1. If via API: Identify the access pattern
# Check Supabase logs for the query pattern
# Identify the user/IP making unauthorized requests

# 2. Block the attacker
# If authenticated user: disable their account
# If via API key: revoke the key
# If via IP: block at firewall/WAF level

# 3. Assess what was accessed
# Query Supabase logs for all queries from the attacker's session
# Determine which tables/rows were accessed
# This determines breach notification requirements
```

#### Malicious Code in Codebase
```bash
# 1. Revert the malicious commit
git revert <commit-hash>
git push origin main

# 2. Force redeploy from clean state
# Vercel: trigger redeploy from the reverted commit

# 3. Check for backdoors
# Run unicode scanner on entire codebase
python3 scan_unicode.py . --strict

# Search for common backdoor patterns
grep -rn 'exec\|eval\|child_process\|new Function' --include='*.{js,ts,jsx,tsx}' .

# 4. Rotate any secrets the malicious code could have accessed
# All environment variables in the deployment are potentially compromised
```

## Phase 3: Evidence Preservation (Minutes 15-25)

**BEFORE doing any cleanup**, preserve evidence for analysis:

```bash
# 1. Export all relevant logs
# Supabase: Dashboard → Logs → Export
# Vercel: vercel logs --output logs-$(date +%Y%m%d).json
# GitHub Actions: Download workflow run logs

# 2. Snapshot current state
# Database: pg_dump or Supabase backup
# File system: tar -czf incident-snapshot-$(date +%Y%m%d).tar.gz .

# 3. Screenshot any relevant dashboards
# Supabase Dashboard, Vercel Dashboard, Stripe Dashboard

# 4. Document timeline so far
# Write down everything you know with timestamps
# Include: who reported, when discovered, actions taken
```

### Evidence Checklist
- [ ] Server/application logs exported
- [ ] Database access logs exported
- [ ] Authentication logs (Supabase Auth logs)
- [ ] Network/WAF logs if available
- [ ] Git history preserved (don't force-push over evidence)
- [ ] Deployment history (which versions were live when)
- [ ] Screenshot of current state before changes
- [ ] Written timeline with timestamps

## Phase 4: Investigate (Minutes 25-60)

### Determine Blast Radius
```
What the attacker could access:
├── With this credential → what APIs/services does it unlock?
├── From this IP → what other endpoints did they hit?
├── In this timeframe → what deployments were live?
├── With this data → what downstream damage is possible?
│   ├── PII exposure → breach notification required?
│   ├── Payment data → PCI implications?
│   ├── Auth tokens → account takeover possible?
│   └── Source code → intellectual property?
└── Was there lateral movement → did they access other systems?
```

### Key Questions to Answer
1. **Entry point**: How did the attacker get in?
2. **Dwell time**: How long did they have access?
3. **Data accessed**: Exactly what tables/rows/files were touched?
4. **Data exfiltrated**: Was data actually stolen, or just accessed?
5. **Persistence**: Did they establish any backdoor or persistent access?
6. **Scope**: Are other systems/services compromised?

## Phase 5: Remediate

### After Investigation Is Complete
1. **Fix the root cause** — not just the symptom
2. **Rotate ALL potentially compromised credentials** — not just the confirmed ones
3. **Deploy fixes** with verification
4. **Monitor for re-exploitation** — the attacker may try again
5. **Update security skills/checklists** with the new pattern

### Remediation Verification
```bash
# After rotating credentials:
# 1. Verify old credentials no longer work
curl -H "apikey: OLD_KEY" https://project.supabase.co/rest/v1/test
# Expected: 401 Unauthorized

# 2. Verify new credentials work
curl -H "apikey: NEW_KEY" https://project.supabase.co/rest/v1/test
# Expected: 200 OK (or empty array if RLS is working)

# 3. Verify the vulnerability is fixed
# Attempt the same attack that was used — should now fail
```

## Phase 6: Post-Incident

### Incident Report Template
```markdown
# Incident Report: [Title]

## Summary
[1-2 sentences: what happened, severity, impact]

## Timeline
| Time (UTC) | Event |
|------------|-------|
| [time] | [event] |

## Root Cause
[What vulnerability or misconfiguration allowed this to happen]

## Impact
- Data accessed: [tables, row count, data types]
- Data exfiltrated: [confirmed/suspected/ruled out]
- Users affected: [count]
- Financial impact: [if any]
- Regulatory implications: [breach notification required?]

## Response Actions Taken
1. [action and timestamp]

## Root Cause Fix
[What was changed to prevent recurrence]

## Lessons Learned
- What went well in the response
- What could be improved
- What detection was missing

## Action Items
- [ ] [preventive action 1]
- [ ] [preventive action 2]
- [ ] [detection improvement]
```

### Post-Incident Improvements
- [ ] Add the attack pattern to relevant security skill
- [ ] Update threat model for the affected system
- [ ] Add monitoring/alerting for this attack pattern
- [ ] Update secure coding standards if a coding pattern caused the issue
- [ ] Brief the team on what happened and how to prevent recurrence

## Communication Templates

### To Nick (Internal)
```
🚨 Security Incident Report — [SEV-X]

What: [One sentence]
When: Discovered [time], estimated start [time]
Status: [Contained / Investigating / Remediated]
Impact: [Blast radius assessment]
Actions: [What's been done, what's in progress]
Need: [Any decisions or approvals needed]
```

### To Affected Users (if needed)
```
Subject: Important Security Update

We recently identified [general description without technical details].
We have [actions taken]. As a precaution, we recommend you [user actions: change password, etc.].

[If data was exposed]: The following information may have been affected: [list].
We have [remediation steps].

For questions: [contact info]
```

## References

For forensic analysis techniques, see `security-forensics` skill.
For specific vulnerability remediation, see the relevant security skills.
