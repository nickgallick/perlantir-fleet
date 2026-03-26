---
name: compliance-security-finance
description: Security compliance requirements for financial services applications — SOC 2, PCI DSS, GDPR/privacy, and financial data handling standards. Use when building payment products, financial SaaS, mortgage/lending tools, or any application handling financial data, PII, or payment card information. Covers what SOC 2 Type II requires from a technical security standpoint, PCI DSS scope reduction (so you don't have to become PCI compliant yourself), GDPR technical requirements, breach notification obligations, data retention rules, and the specific audit controls that map to our Next.js + Supabase architecture.
---

# Compliance & Security for Financial Products

## Nick's Context

Nick builds in financial services (mortgage, HELOC, consumer finance, sales operations). These aren't just products with security requirements — they're regulated industries with legal obligations. A security gap isn't just a bug; in this context it can be a regulatory violation with material consequences.

## Framework 1: SOC 2

### What It Is
SOC 2 (System and Organization Controls 2) is a security certification that enterprise customers require before they'll use your SaaS product. Without it, you lose enterprise sales.

### The Five Trust Service Criteria
| Criteria | What It Requires | Our Implementation |
|----------|-----------------|-------------------|
| **Security** | Protection against unauthorized access | Auth, RLS, encryption, access controls |
| **Availability** | System uptime commitments | Monitoring, incident response, SLAs |
| **Processing Integrity** | Complete, valid, accurate processing | Input validation, audit logs, error handling |
| **Confidentiality** | Protection of confidential data | Encryption at rest/transit, access scoping |
| **Privacy** | PII handling per privacy notice | GDPR controls, data minimization, retention |

SOC 2 Type I = snapshot (controls exist)
SOC 2 Type II = period of time (controls worked over 6-12 months)

### Technical Controls That Map to SOC 2

**CC6.1 — Logical Access Controls**
```
Required: Only authorized users access systems
Implementation:
- Supabase Auth with MFA for admin users
- RLS on all tables
- Principle of least privilege (no service_role in client code)
- Regular access review (quarterly: remove former employees/contractors)
- Separate credentials per environment
Evidence needed: List of users with access, MFA enrollment rate, access review records
```

**CC6.3 — Removal of Access**
```
Required: Access removed within defined timeframe when no longer needed
Implementation:
- Documented offboarding process
- Supabase: disable user accounts within 24 hours of departure
- GitHub: revoke access within 24 hours
- Rotate shared secrets after any team member departure
Evidence needed: Offboarding tickets, access removal timestamps
```

**CC7.2 — Monitoring of System Components**
```
Required: Detect security events
Implementation:
- Error monitoring (Sentry or equivalent)
- Anomaly detection on API usage
- Alert on unusual data access patterns (bulk exports, mass queries)
- GitHub secret scanning enabled
Evidence needed: Monitoring tool configuration, alert history, incident response records
```

**CC8.1 — Change Management**
```
Required: Changes are authorized, tested, and reviewed
Implementation:
- PR review required for all code changes (no direct push to main)
- Automated CI tests required before merge
- Forge code review for security-sensitive changes
- Deployment approvals for production
Evidence needed: GitHub branch protection rules, PR history with reviewers
```

**CC9.2 — Vendor Risk Management**
```
Required: Third-party risks assessed
Implementation:
- Dependency audit process (npm audit, monthly review)
- SOC 2 attestations from key vendors (Supabase, Vercel, Stripe)
- Vendor security review before integration
Evidence needed: Vendor list with security assessment, dependency audit logs
```

### SOC 2 Readiness Checklist
- [ ] All production access requires MFA
- [ ] No shared accounts (each person has their own credentials)
- [ ] Access review process documented and executed quarterly
- [ ] Encryption at rest enabled (Supabase encrypts by default)
- [ ] Encryption in transit (HTTPS everywhere, HSTS)
- [ ] Audit logs for security-sensitive actions
- [ ] Incident response plan documented (see `incident-response-playbook`)
- [ ] Business continuity plan documented
- [ ] Vulnerability management process (monthly dependency audits)
- [ ] Change management process (PR reviews, CI/CD controls)

## Framework 2: PCI DSS

### Scope Reduction Is the Goal

Full PCI DSS compliance is 12 requirements with hundreds of sub-controls. The right strategy is **scope reduction** — design your system so payment card data NEVER touches your servers.

### Scope Reduction via Stripe
```
❌ In-scope architecture (you are PCI compliant):
  User enters card → Your server handles it → You send to Stripe
  Your servers are in PCI scope.

✅ Out-of-scope architecture (Stripe handles PCI):
  User card data enters Stripe's servers directly:
  - Stripe.js / Stripe Elements (card input happens in Stripe's iframe)
  - Stripe Checkout (redirect to Stripe's hosted page)
  Your servers never see raw card data.
  You're SAQ A-EP or SAQ A — minimal compliance burden.
```

### What You STILL Must Protect
Even with scope reduction, you store:
- Stripe customer IDs (`cus_xxx`)
- Stripe payment method IDs (`pm_xxx`)
- Last 4 digits of cards
- Billing addresses
- Transaction amounts and status

These are FINANCIAL PII and must be protected:
```sql
-- The payments table has elevated sensitivity
-- Restrict access beyond normal RLS
CREATE POLICY "payments_select" ON payments FOR SELECT TO authenticated
USING (user_id = (select auth.uid()));  -- Only own payments

-- NO public/service role access to payment details
-- Admin access only via specific RPC functions with audit logging
-- Never log payment details in application logs
```

### PCI Requirements That Still Apply
Even SAQ A requires:
- [ ] Vulnerability management on systems that process redirects
- [ ] Access control for personnel with access to cardholder data environment
- [ ] Regular security testing
- [ ] Information security policy

## Framework 3: GDPR / Privacy

### What Counts as Personal Data
```
Always PII:
- Name, email, phone number
- IP address (in EU context)
- Location data
- User IDs that can identify a person
- Financial account numbers
- Health data (special category)

In context:
- Behavioral data (browsing history, click patterns)
- Device identifiers
- Photos or biometric data
```

### Technical Requirements

**Data Minimization**
```typescript
// Only collect what you actually need
// WRONG: collecting full DOB when only age verification needed
const user = { name, email, dob: '1985-03-15', phone, address, ... }

// RIGHT: collect minimum viable data
const user = { name, email, isOver18: true }

// Review every form field: do we actually need this?
```

**Right to Erasure ("Right to be Forgotten")**
```typescript
async function deleteUserData(userId: string) {
  // 1. Delete personal data from all tables
  await supabase.from('profiles').delete().eq('user_id', userId)
  await supabase.from('submissions').delete().eq('user_id', userId)
  
  // 2. Anonymize data that must be retained (audit logs, financial records)
  await supabase.from('audit_log').update({
    user_id: null,
    user_email_anonymized: 'deleted_user@deleted.invalid'
  }).eq('user_id', userId)
  
  // 3. Delete auth account
  await supabase.auth.admin.deleteUser(userId)
  
  // 4. Log the deletion request itself (required for compliance)
  await supabase.from('deletion_requests').insert({
    original_user_id: userId,
    requested_at: new Date(),
    completed_at: new Date()
  })
}
```

**Data Portability**
```typescript
// Users can request their data in machine-readable format
async function exportUserData(userId: string) {
  const [profile, submissions, transactions] = await Promise.all([
    supabase.from('profiles').select('*').eq('user_id', userId).single(),
    supabase.from('submissions').select('*').eq('user_id', userId),
    supabase.from('transactions').select('*').eq('user_id', userId),
  ])
  
  return {
    exportedAt: new Date().toISOString(),
    user: profile.data,
    submissions: submissions.data,
    transactions: transactions.data,
  }
}
```

**Consent Management**
```sql
-- Track what users consented to and when
CREATE TABLE consent_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  consent_type TEXT NOT NULL,  -- 'marketing', 'analytics', 'data_processing'
  granted BOOLEAN NOT NULL,
  granted_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,
  ip_address INET,
  user_agent TEXT
);
```

### Breach Notification
Under GDPR, a personal data breach must be reported to the supervisory authority **within 72 hours** of discovery if it's likely to result in risk to individuals.

**What triggers notification**:
- Unauthorized access to user PII
- Loss of user data (deletion without backup)
- Encryption key compromise exposing encrypted PII

**What to document for notification**:
- Nature of the breach
- Categories of data affected
- Approximate number of data subjects
- Likely consequences
- Measures taken to address the breach

## Framework 4: Financial Services Specific

### Data Retention Requirements
Financial data has LEGAL minimum retention periods:

| Data Type | Minimum Retention | Legal Basis |
|-----------|------------------|-------------|
| Transaction records | 5 years | Banking regulations |
| Tax-related records | 7 years | IRS requirements |
| Mortgage-related | Life of loan + 3 years | CFPB/RESPA |
| HELOC documentation | Life of loan + 3 years | Reg B/ECOA |
| Authentication logs | 1 year minimum | Varies by state |

**Implementation**:
```sql
-- Soft delete with retention tracking
ALTER TABLE transactions ADD COLUMN deleted_at TIMESTAMPTZ;
ALTER TABLE transactions ADD COLUMN retention_expires_at TIMESTAMPTZ 
  DEFAULT NOW() + INTERVAL '7 years';

-- RLS: users see only non-deleted records
-- Admin: can see all for legal hold
-- Automated: purge records where retention_expires_at < NOW() AND deleted_at IS NOT NULL
```

### GLBA Safeguards Rule (Gramm-Leach-Bliley Act)
For financial services companies handling customer financial data:

**Technical Safeguards Required**:
- Encryption of customer data at rest and in transit
- Access controls limiting employee access to customer data
- Multi-factor authentication for any information system containing customer information
- Encrypted backups
- Monitoring and logging for unauthorized access
- Incident response plan (see `incident-response-playbook`)
- Vendor management for service providers with access to customer data

## Compliance Review Checklist

### Access Control
- [ ] MFA required for all admin access
- [ ] No shared accounts
- [ ] Quarterly access review documented
- [ ] Offboarding process removes access within 24 hours

### Data Protection
- [ ] Encryption at rest (Supabase default)
- [ ] Encryption in transit (HTTPS/TLS everywhere)
- [ ] Sensitive fields additionally encrypted where needed
- [ ] Payment card data never stored (use Stripe tokens only)
- [ ] PII access logged in audit trail

### User Rights
- [ ] Delete user data process documented and tested
- [ ] Data export process documented and tested
- [ ] Consent recorded with timestamp
- [ ] Privacy policy reflects actual data practices

### Vendor Management
- [ ] Key vendors have SOC 2 attestations
- [ ] Data processing agreements (DPA) signed with EU vendors
- [ ] Vendor list maintained with last review date

### Incident Response
- [ ] Breach notification process documented (72-hour GDPR requirement)
- [ ] Incident response plan tested (tabletop exercise minimum)
- [ ] Insurance covers security incidents

## References

For incident response execution, see `incident-response-playbook` skill.
For audit trail implementation, see `secure-architecture-patterns` skill.
For RLS protecting financial data, see `rls-bypass-testing` skill.
