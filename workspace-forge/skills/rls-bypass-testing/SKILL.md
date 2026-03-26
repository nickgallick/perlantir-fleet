---
name: rls-bypass-testing
description: Systematic testing and review of Supabase Row Level Security (RLS) policies for bypasses, misconfigurations, and logic errors. Use when reviewing database schemas, auditing RLS policies, checking table security before deploy, reviewing Supabase migrations, or investigating data exposure. Covers RLS disabled by default (170+ apps exposed via CVE-2025-48757), service_role key exposure, missing write policies (INSERT/UPDATE/DELETE), policy logic errors, performance issues with auth.uid() vs (select auth.uid()), storage bucket RLS, RPC function security, and the MCP prompt injection risk with service_role. The #1 security issue in Supabase apps is broken RLS.
---

# RLS Bypass Testing

## The Core Problem

Supabase auto-generates REST APIs from your schema. Every table is accessible via the public anon key. **RLS is disabled by default.** Without RLS + correct policies, the anon key embedded in your frontend is a master key to your entire database.

**Scale of the problem**: 83% of exposed Supabase databases involve RLS misconfigurations. 170+ apps exposed in the Lovable CVE alone. Researchers dump entire databases with:
```bash
curl -X GET 'https://project.supabase.co/rest/v1/users?select=*' \
  -H "apikey: YOUR_ANON_KEY"
```

## RLS Bypass Categories

### Bypass 1: RLS Not Enabled
The table has no RLS at all. This is the most common vulnerability.

**Detection**:
```sql
-- Find all tables without RLS enabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' AND rowsecurity = false;
```

**Fix**: `ALTER TABLE <table> ENABLE ROW LEVEL SECURITY;`

**Review rule**: EVERY table in the `public` schema MUST have RLS enabled. No exceptions.

### Bypass 2: RLS Enabled, No Policies
RLS is enabled but no policies exist. Result: deny-all (safe from reads but breaks the app). Developers often disable RLS to "fix" the app instead of writing correct policies.

**Detection**:
```sql
-- Find tables with RLS enabled but no policies
SELECT t.tablename 
FROM pg_tables t
LEFT JOIN pg_policies p ON t.tablename = p.tablename
WHERE t.schemaname = 'public' AND t.rowsecurity = true
GROUP BY t.tablename
HAVING COUNT(p.policyname) = 0;
```

### Bypass 3: Missing Write Policies
Developer tests SELECT policy (can users read other users' data?), forgets INSERT/UPDATE/DELETE policies. Attacker can't read data but can **modify or delete it**.

**Detection**: For each table, verify policies exist for ALL four operations:
```sql
SELECT tablename, cmd 
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, cmd;
-- Should see SELECT, INSERT, UPDATE, DELETE for each table
```

**Critical gotcha**: INSERT operations require a SELECT policy too. PostgreSQL SELECTs newly inserted rows to return them. Without SELECT policy, inserts fail with cryptic errors.

### Bypass 4: Overly Permissive SELECT Policies
```sql
-- DANGEROUS — anyone can read everything
CREATE POLICY "public_read" ON users FOR SELECT USING (true);
```

Ask: Should anonymous/unauthenticated users really see this data? If the table has emails, phone numbers, addresses, payment info — `USING (true)` is almost certainly wrong.

### Bypass 5: Missing user_id Verification
```sql
-- DANGEROUS — auth check present but doesn't scope to user
CREATE POLICY "auth_only" ON profiles 
FOR ALL TO authenticated 
USING (true);  -- Any authenticated user can see ALL profiles
```

**vs correct**:
```sql
CREATE POLICY "own_data" ON profiles 
FOR ALL TO authenticated 
USING ((select auth.uid()) = user_id);
```

### Bypass 6: USING Without WITH CHECK on Updates
```sql
-- INCOMPLETE — can update own rows, but can change user_id to someone else's
CREATE POLICY "update_own" ON profiles 
FOR UPDATE TO authenticated 
USING ((select auth.uid()) = user_id);
-- Missing WITH CHECK — user could set user_id to another user's ID!
```

**Fix**: Always include both:
```sql
CREATE POLICY "update_own" ON profiles 
FOR UPDATE TO authenticated 
USING ((select auth.uid()) = user_id)
WITH CHECK ((select auth.uid()) = user_id);
```

### Bypass 7: Service Role Key Exposure
`service_role` key bypasses ALL RLS. If it's in:
- Frontend code / client bundle
- `.env` file committed to git
- NEXT_PUBLIC_ environment variable
- Exposed via API response
- Accessible to AI coding agents (MCP vulnerability)

...the attacker has god-mode database access.

**Detection**:
```bash
# Search for service_role in frontend code
grep -rn 'service_role\|SUPABASE_SERVICE_ROLE' --include='*.{ts,tsx,js,jsx}' src/ app/
# Check if NEXT_PUBLIC_ prefix on service role
grep -rn 'NEXT_PUBLIC_SUPABASE_SERVICE_ROLE' .
# Check git history
git log --all -p | grep -i 'service_role' | head -20
```

### Bypass 8: RPC Function Without Auth
```sql
-- DANGEROUS — callable by anyone
CREATE OR REPLACE FUNCTION get_all_users()
RETURNS SETOF users AS $$
  SELECT * FROM users;
$$ LANGUAGE sql SECURITY DEFINER;
```

`SECURITY DEFINER` runs as the function creator (usually postgres), which **bypasses RLS**. If the function is callable by anon users, they get full access.

**Fix**: Add auth check inside the function, or use `SECURITY INVOKER` (default):
```sql
CREATE OR REPLACE FUNCTION get_user_profile(target_id UUID)
RETURNS users AS $$
BEGIN
  -- Verify caller is the user
  IF auth.uid() != target_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;
  RETURN QUERY SELECT * FROM users WHERE id = target_id;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;
```

### Bypass 9: Storage Bucket Without Policies
Supabase Storage uses RLS on the `storage.objects` table. Buckets without policies allow anyone to:
- Upload files (potentially malicious)
- Download private files
- Delete files
- List all files

**Detection**: Check storage policies exist for each bucket.

### Bypass 10: Policy Logic Errors in Multi-Tenant Apps
```sql
-- VULNERABLE — uses org_id from the request, not from auth
CREATE POLICY "org_access" ON documents 
FOR SELECT TO authenticated 
USING (org_id = current_setting('request.jwt.claims')::json->>'org_id');
-- Attacker can forge JWT claims if using getSession() client-side
```

**Fix**: Derive org membership from a trusted source:
```sql
CREATE POLICY "org_access" ON documents 
FOR SELECT TO authenticated 
USING (org_id IN (
  SELECT org_id FROM org_members 
  WHERE user_id = (select auth.uid())
));
```

## Complete RLS Audit Procedure

### Step 1: Enumerate all tables
```sql
SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';
```

### Step 2: Check policies per table
```sql
SELECT tablename, policyname, cmd, qual, with_check 
FROM pg_policies WHERE schemaname = 'public'
ORDER BY tablename;
```

### Step 3: Test as anonymous user
```bash
# For each table, try to read
curl 'https://PROJECT.supabase.co/rest/v1/TABLE?select=*' \
  -H "apikey: ANON_KEY"

# Try to insert
curl -X POST 'https://PROJECT.supabase.co/rest/v1/TABLE' \
  -H "apikey: ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"field": "value"}'

# Try to delete
curl -X DELETE 'https://PROJECT.supabase.co/rest/v1/TABLE?id=eq.1' \
  -H "apikey: ANON_KEY"
```

### Step 4: Test as authenticated user (cross-user access)
```bash
# Get auth token for User A
# Try to access User B's data
curl 'https://PROJECT.supabase.co/rest/v1/profiles?user_id=eq.USER_B_ID' \
  -H "apikey: ANON_KEY" \
  -H "Authorization: Bearer USER_A_TOKEN"
```

### Step 5: Check RPC functions
```sql
SELECT routine_name, security_type 
FROM information_schema.routines 
WHERE routine_schema = 'public';
-- Flag any SECURITY DEFINER functions
```

### Step 6: Check storage buckets
```sql
SELECT id, name, public FROM storage.buckets;
-- Flag any public buckets containing private data
SELECT * FROM storage.objects LIMIT 5;  -- Check if accessible
```

### Step 7: Verify service_role key isolation
- [ ] Not in any frontend file
- [ ] Not in any NEXT_PUBLIC_ variable
- [ ] Not committed to git
- [ ] Only used in server-side code

## Performance Considerations

### Use `(select auth.uid())` not `auth.uid()`
```sql
-- BAD: re-evaluates for every row
USING (auth.uid() = user_id)

-- GOOD: evaluates once per statement
USING ((select auth.uid()) = user_id)
```

### Index policy columns
```sql
-- Add index on columns used in policy USING clauses
CREATE INDEX idx_profiles_user_id ON profiles(user_id);
CREATE INDEX idx_documents_org_id ON documents(org_id);
```

### Avoid expensive subqueries in policies
```sql
-- EXPENSIVE — subquery runs per row without optimization
USING (org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid()))

-- BETTER — materialized CTE or function with proper caching
USING (org_id IN (SELECT org_id FROM get_user_orgs((select auth.uid()))))
```

## Review Checklist (Every PR with Schema Changes)

- [ ] Every new table has `ENABLE ROW LEVEL SECURITY`
- [ ] Every table has policies for SELECT, INSERT, UPDATE, DELETE
- [ ] UPDATE policies have both USING and WITH CHECK
- [ ] No `USING (true)` on tables with sensitive data
- [ ] All policies use `(select auth.uid())` not bare `auth.uid()`
- [ ] No SECURITY DEFINER functions callable by anon role
- [ ] Service role key not in frontend code
- [ ] Storage buckets have appropriate policies
- [ ] Policy columns are indexed
- [ ] Multi-tenant policies derive membership from auth, not JWT claims

## References

For Supabase auth patterns, see the `auth-patterns` and `jwt-session-attacks` skills.
For advanced PostgreSQL patterns, see the `advanced-postgres` skill.
