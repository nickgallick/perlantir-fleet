---
name: weekly-security-scan
description: Proactive weekly security scan across all active Perlantir projects in ~/Projects/. Finds issues without waiting for a PR.
---

# Weekly Security Scan Protocol

## When to Run
- Every Sunday during heartbeat cycle
- On-demand: "forge, scan [project]"

## What to Scan

### Step 1: Discover active projects
```bash
ls ~/Projects/
# Focus on projects with Vercel deploys (have vercel.json or .vercel/)
find ~/Projects -name "vercel.json" -maxdepth 3 | head -20
```

### Step 2: Secret scan (highest priority)
```bash
# Look for exposed credentials
grep -r "sk-\|api_key\|apiKey\|SECRET\|PASSWORD\|TOKEN" ~/Projects/ \
  --include="*.ts" --include="*.tsx" --include="*.js" \
  --exclude-dir=node_modules --exclude-dir=.git \
  -l 2>/dev/null

# Check .env files committed accidentally
find ~/Projects -name ".env" -not -path "*/node_modules/*" 2>/dev/null
find ~/Projects -name ".env.local" -not -path "*/node_modules/*" 2>/dev/null

# Check .gitignore has .env entries
for project in ~/Projects/*/; do
  grep -l "\.env" "$project/.gitignore" 2>/dev/null || echo "⚠️  $project missing .env in .gitignore"
done
```

### Step 3: Dependency vulnerability scan
```bash
# Check each project for known vulnerable packages
for project in ~/Projects/*/; do
  [ -f "$project/package.json" ] && \
    echo "=== $(basename $project) ===" && \
    cd "$project" && \
    npm audit --audit-level=high 2>/dev/null | grep -E "high|critical|moderate" | head -5
  cd ~/Projects
done
```

### Step 4: RLS coverage check
For each project using Supabase, look for tables without RLS:
```bash
# Find migration files and check for RLS
grep -r "CREATE TABLE\|enable row level" ~/Projects/ \
  --include="*.sql" -l 2>/dev/null

# Check if RLS is enabled (look for policy definitions)
for project in ~/Projects/*/; do
  migrations=$(find "$project" -name "*.sql" -not -path "*/node_modules/*" 2>/dev/null)
  for m in $migrations; do
    tables=$(grep -c "CREATE TABLE" "$m" 2>/dev/null || echo 0)
    rls=$(grep -c "enable row level security\|ENABLE ROW LEVEL SECURITY" "$m" 2>/dev/null || echo 0)
    [ "$tables" -gt "$rls" ] && echo "⚠️  Possible missing RLS in $m: $tables tables, $rls RLS statements"
  done
done
```

### Step 5: Auth boundary check
```bash
# Find API routes missing auth checks
grep -r "export.*GET\|export.*POST\|export.*PUT\|export.*DELETE" \
  ~/Projects/ --include="route.ts" -l 2>/dev/null | while read f; do
  auth=$(grep -c "getUser\|getSession\|auth\|session" "$f" 2>/dev/null || echo 0)
  [ "$auth" -eq 0 ] && echo "⚠️  Possibly unprotected route: $f"
done
```

## Report Format
```
## Forge Weekly Security Scan — [Date]

### Projects Scanned: [list]

### 🚨 Critical Findings
[file:line:issue:fix]

### ⚠️ Warnings
[file:line:issue]

### ✅ All Clear
[what was checked and passed]

### Next Scan: [date]
```

## What to Do With Findings
- Critical (secrets, auth bypass, exposed data) → Message Nick immediately via Telegram
- Warnings (missing RLS, vulnerable deps) → Include in next heartbeat report
- Clean scan → Log to runbook, no message needed

## Changelog
- 2026-03-20: Created
