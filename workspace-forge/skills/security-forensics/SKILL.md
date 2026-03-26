---
name: security-forensics
description: Post-incident forensic analysis — determining what happened, when, what was accessed, and whether data was exfiltrated after a security incident. Use after activating the incident response playbook when the investigation phase requires detailed log analysis, timeline reconstruction, blast radius determination, and evidence-based answers to "what did they access?" Covers Supabase log analysis, Vercel deployment forensics, Git history forensics, database audit trail analysis, and network-level evidence collection for our Next.js + Supabase + Vercel stack.
---

# Security Forensics

## The Questions Forensics Must Answer

After a security incident, stakeholders need definitive answers:

1. **What happened?** — The exact sequence of events
2. **When did it start?** — The earliest evidence of compromise
3. **How did they get in?** — The initial access vector
4. **What did they access?** — Specific data, tables, files
5. **Was data exfiltrated?** — Did data leave our systems?
6. **Is there persistent access?** — Backdoors, new accounts, modified code
7. **Who was affected?** — Which users/customers had data exposed
8. **Is it over?** — Can we confirm the attacker no longer has access

## Evidence Sources in Our Stack

### Supabase Logs
```sql
-- PostgreSQL query log (if enabled)
-- Shows: all SQL queries executed, who executed them, when
-- Location: Supabase Dashboard → Logs → Postgres

-- Auth logs
-- Shows: login attempts, token refreshes, signups
-- Location: Supabase Dashboard → Logs → Auth

-- API logs  
-- Shows: all REST API calls, HTTP method, path, status code, IP
-- Location: Supabase Dashboard → Logs → API

-- Realtime logs
-- Shows: WebSocket connections, subscriptions, messages
-- Location: Supabase Dashboard → Logs → Realtime

-- Storage logs
-- Shows: file uploads, downloads, deletions
-- Location: Supabase Dashboard → Logs → Storage
```

### Vercel Logs
```bash
# Deployment logs — shows when each version was deployed
vercel ls --output json

# Function logs — shows all serverless function invocations
vercel logs --output json --since 2026-03-24

# Access logs — shows all HTTP requests to your app
# Available in Vercel Dashboard → Logs → Runtime
```

### Git History
```bash
# Commits in the incident timeframe
git log --since="2026-03-24" --until="2026-03-26" --all --oneline

# Who authored commits
git log --since="2026-03-24" --format="%H %an %ae %ai %s"

# Detect force pushes (evidence tampering)
git reflog --since="2026-03-24"

# Find commits that modified security-sensitive files
git log --since="2026-03-24" --all -- 'middleware.ts' '.env*' 'next.config.*' '**/auth/**'

# Show exact changes in suspicious commits
git diff <commit>^..<commit>

# Check if commits were signed (unsigned = potentially forged)
git log --show-signature --since="2026-03-24"
```

### GitHub Actions Logs
```bash
# List workflow runs in timeframe
gh run list --created ">2026-03-24"

# Download logs for a specific run
gh run view <run-id> --log

# Check for failed/cancelled runs (might indicate detection avoidance)
gh run list --status failure --created ">2026-03-24"
```

## Forensic Analysis Procedures

### Procedure 1: Timeline Reconstruction

Build a chronological timeline from ALL evidence sources:

```markdown
| Timestamp (UTC) | Source | Event | Significance |
|-----------------|--------|-------|-------------|
| 2026-03-24 14:22 | Supabase Auth | New signup from IP 45.33.x.x | Attacker creates account |
| 2026-03-24 14:23 | Supabase API | GET /rest/v1/users?select=* | Probing for missing RLS |
| 2026-03-24 14:23 | Supabase API | Response: 200, 1500 rows | RLS was missing! Data exposed |
| 2026-03-24 14:25 | Supabase API | GET /rest/v1/api_keys?select=* | Accessing API keys table |
| 2026-03-24 14:25 | Supabase API | Response: 200, 50 rows | API keys exposed |
| 2026-03-24 14:30 | Vercel | Unusual traffic spike from same IP | Automated scraping |
```

### Procedure 2: Data Access Analysis

Determine exactly what data was accessed:

```sql
-- If Supabase query logging is enabled:
-- Check the postgres logs for queries from the suspected session

-- Check for bulk data access patterns:
-- Large SELECT results, no WHERE clause, sequential table access

-- For API-level analysis, export Supabase API logs and filter:
-- 1. By IP address of suspected attacker
-- 2. By time range
-- 3. By response size (large responses = data exfiltration)
-- 4. By endpoint (which tables/RPC functions were called)
```

```bash
# If you have structured logs (JSON), analyze with jq:
cat api-logs.json | jq '
  select(.ip == "45.33.x.x") |
  select(.timestamp >= "2026-03-24T14:00:00Z") |
  { timestamp, method, path, status, response_size }
'
```

### Procedure 3: Persistence Check

Verify the attacker didn't leave persistent access:

```bash
# 1. Check for unauthorized accounts
# Supabase Dashboard → Authentication → Users
# Look for: accounts created during incident timeframe
# Look for: accounts with unusual email patterns

# 2. Check for unauthorized API keys
# Query api_keys table for keys created during incident

# 3. Check for modified files in deployment
git status
git diff HEAD~10..HEAD --name-only  # Changes in recent commits

# 4. Check for unauthorized environment variables
# Vercel Dashboard → Settings → Environment Variables
# Look for: variables added during incident

# 5. Check for cron jobs, webhooks, or scheduled tasks
# Supabase: Edge Functions, Database webhooks
# Vercel: Cron configuration

# 6. Check for modified GitHub Actions
git log --all -- '.github/workflows/*'

# 7. System-level persistence (if VPS/server)
crontab -l
ls ~/.config/systemd/user/
cat ~/.bashrc ~/.profile ~/.zshrc | tail -5  # Check for additions
```

### Procedure 4: Blast Radius Determination

```
Credential exposed: SERVICE_ROLE_KEY
├── What does this credential access?
│   ├── ALL Supabase tables (bypasses RLS)
│   ├── ALL Storage buckets
│   ├── ALL Edge Functions
│   └── User management (create/delete users)
│
├── Was it actually used?
│   ├── Check API logs for service_role auth
│   ├── Check for unusual API patterns
│   └── Check response sizes (data volume)
│
├── What data could have been accessed?
│   ├── users table: emails, names, metadata
│   ├── profiles table: [whatever's stored]
│   ├── payments table: Stripe customer IDs, amounts
│   └── api_keys table: hashed keys, user associations
│
└── Who is affected?
    ├── Count: total users in database
    ├── Sensitivity: what PII was in accessible tables
    └── Regulatory: does this trigger notification requirements?
```

### Procedure 5: Exfiltration Assessment

Was data actually stolen, or just accessed?

**Evidence of exfiltration**:
- Large response bodies in API logs
- Outbound network connections to unusual IPs (server-level)
- Multiple sequential requests covering all pages of data
- Requests to data export endpoints
- Unusual database dump patterns (sequential scans)

**Evidence against exfiltration**:
- Single exploratory query with small response
- No subsequent requests after initial probe
- Attacker session ended quickly (may have found nothing useful)

**When uncertain**: Assume exfiltration occurred. It's better to over-notify than under-notify.

## Forensic Report Template

```markdown
# Forensic Analysis Report

## Executive Summary
[2-3 sentences: what happened, confirmed impact, confidence level]

## Evidence Sources Analyzed
- [ ] Supabase API logs (date range)
- [ ] Supabase Auth logs (date range)
- [ ] Supabase Postgres logs (date range)
- [ ] Vercel deployment logs (date range)
- [ ] Git history (date range)
- [ ] GitHub Actions logs (date range)
- [ ] Network logs (if available)

## Reconstructed Timeline
[Chronological table as shown above]

## Initial Access Vector
[How the attacker gained access — confirmed or suspected]

## Data Accessed
| Table/Resource | Records Accessed | Data Types | Confirmed/Suspected |
|---------------|-----------------|------------|-------------------|

## Data Exfiltration Assessment
[Confirmed/Suspected/Ruled Out with evidence]

## Persistence Assessment
[Were backdoors found? New accounts? Modified code?]

## Affected Users/Data
- Total users potentially affected: [count]
- Data types exposed: [list]
- Regulatory notification required: [Yes/No with reasoning]

## Confidence Level
[High/Medium/Low — what evidence supports the conclusions, what gaps exist]

## Recommendations
1. [Immediate action]
2. [Preventive measure]
3. [Detection improvement]
```

## Proactive Forensic Readiness

### Enable Logging BEFORE You Need It
```sql
-- Supabase: Enable pgaudit for query logging
-- (Requires contacting Supabase support for managed instances)

-- At minimum, ensure these are enabled:
-- Dashboard → Settings → Logs → Enable API logs
-- Dashboard → Settings → Logs → Enable Auth logs
```

### Log Retention
- API logs: minimum 90 days (align with incident discovery timeframe)
- Auth logs: minimum 1 year (account compromise may be discovered late)
- Git history: permanent (never force-push, never delete branches during investigation)
- Deployment history: minimum 90 days

### Audit Trail in Application
See `secure-architecture-patterns` skill → Pattern 7: Audit Trail Architecture.

Every security-sensitive operation should log: who, what, when, from where.

## References

For incident response procedures, see `incident-response-playbook` skill.
For secure logging practices, see `error-handling-infodisclosure` skill.
