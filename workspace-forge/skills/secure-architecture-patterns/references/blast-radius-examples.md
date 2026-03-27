# Blast Radius Examples — Real Scenarios

## Scenario 1: service_role Key Leaked

**What happened**: service_role key appears in a GitHub commit.

**Blast radius WITHOUT containment**:
```
service_role key leaked
├── Bypasses ALL RLS policies
├── Full CRUD on all tables
│   ├── Read all user PII (emails, names, addresses)
│   ├── Read all payment records (Stripe IDs, amounts)
│   ├── Read all API keys (hashed, but prefix visible)
│   ├── Modify any user's data
│   └── Delete any records
├── Full Storage access
│   ├── Read all user-uploaded files
│   ├── Modify/delete files
│   └── Upload malicious files
├── Admin Auth operations
│   ├── Create new admin users
│   ├── Modify user metadata
│   └── Impersonate any user
└── Edge Functions (if any exist)
    └── Trigger server-side operations as admin
```

**Blast radius WITH proper isolation**:
```
service_role key leaked
├── Still bypasses RLS (fundamental)
└── BUT:
    ├── Key rotated in < 5 minutes (monitoring alert fired)
    ├── Key was scoped to read-only operations (no write permissions)
    ├── Sensitive data in separate encrypted columns (can't read plaintext)
    ├── Payment data is Stripe tokens only (not actual financial data)
    └── Audit log shows 3-minute window, 2 SELECT queries, no PII tables
```

**The difference**: Monitoring, minimal credentials, encryption at rest, data partitioning.

## Scenario 2: Admin Account Compromised

**What happened**: Admin user's account taken over via credential stuffing.

**Blast radius WITHOUT containment**:
```
Admin account compromised
├── Full access to all admin dashboard features
├── Can view all user data
├── Can export all data
├── Can change any user's account
├── Can modify pricing and plans
└── Session valid for 24+ hours (no suspicious activity detection)
```

**Blast radius WITH proper isolation**:
```
Admin account compromised
├── Admin operations require MFA (attacker can't pass second factor)
├── IF MFA was bypassed:
│   ├── Admin actions require re-auth for sensitive operations
│   ├── All admin actions logged with MFA verification status
│   ├── Bulk exports require additional approval
│   └── Anomaly detection fires on unusual export pattern
└── Maximum exposure window: until alert fires and password reset occurs
```

## Scenario 3: Compromised npm Dependency

**What happened**: A dependency has a postinstall script that steals npm tokens.

**Blast radius WITHOUT containment**:
```
npm token stolen (from CI environment)
├── Token has publish access to ALL packages the org maintains
├── Attacker publishes malicious patch version of all packages
├── All users of those packages affected
└── Attacker also has env vars from CI:
    ├── SUPABASE_SERVICE_ROLE_KEY
    ├── STRIPE_SECRET_KEY
    └── All deployment credentials
```

**Blast radius WITH proper isolation**:
```
npm token stolen
├── Token is scoped to SPECIFIC packages (not all org packages)
├── Token is read-only (can't publish)
├── CI secrets are environment-scoped (production secrets require approval)
└── Token is rotated as part of monthly rotation schedule
    └── By the time attacker uses it, it may already be expired
```

## Key Isolation Techniques Summary

| Technique | What It Contains | How to Implement |
|-----------|-----------------|-----------------|
| Credential scoping | Limits what a stolen credential can do | Fine-grained tokens, read-only where possible |
| Secret isolation | Limits which component can access which secret | Environment-scoped secrets, no sharing |
| Data partitioning | Limits what data is accessible via one path | Separate schemas, encrypted columns |
| Network segmentation | Limits lateral movement | DB not directly accessible, VPC rules |
| MFA on admin | Limits account takeover | Require second factor for privileged operations |
| Short token TTL | Limits window of opportunity | 15-minute access tokens, 7-day refresh |
| Audit logging | Enables detection and scope assessment | Log all access, alert on anomalies |
