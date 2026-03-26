---
name: compliance-and-regulatory
description: COPPA (MathMind), CAN-SPAM (OUTBOUND), GDPR (Arena), and implementation patterns for account deletion, data export, consent tracking.
---

# Compliance & Regulatory

## Product-Specific Requirements

### MathMind → COPPA (Children Under 13)
| Requirement | Implementation |
|-------------|---------------|
| Verifiable parental consent | Parent email verification before child can create account |
| No third-party analytics | No Firebase, Mixpanel, Google Analytics — Apple will reject |
| Parental gate on purchases | Require parent password/PIN for any IAP |
| Data retention policy | Written policy, retain minimum necessary, auto-delete after inactivity |
| No behavioral advertising | No ad SDKs, no tracking pixels |
| **Penalty** | **$53,088 per violation** |

**Updated June 2025, enforcement deadline April 2026.** MathMind MUST comply before App Store submission.

### OUTBOUND → CAN-SPAM (Commercial Email)
| Requirement | Implementation |
|-------------|---------------|
| Physical address in every email | Footer: "Perlantir AI Studio, [address]" |
| Unsubscribe mechanism | One-click unsubscribe, honored within 10 business days |
| Accurate sender info | From name matches business, no spoofing |
| Accurate subject line | No deceptive subjects |
| **B2B cold email is legal** | But must comply with all requirements |
| **Penalty** | **$51,744 per email** |

### Arena → GDPR (EU Users)
| Requirement | Implementation |
|-------------|---------------|
| Lawful basis | Consent for marketing, legitimate interest for core service |
| Right to access | Data export endpoint returning user's data as JSON |
| Right to erasure | Account deletion cascading to ALL related tables |
| Right to portability | Export in machine-readable format (JSON) |
| 72-hour breach notification | Incident response plan + contact procedure |
| DPAs with processors | Supabase, Vercel, Anthropic, Stripe all have DPAs |
| Cookie consent | Banner for non-essential cookies (analytics, marketing) |

---

## Implementation Patterns

### Account Deletion (CASCADE)
```sql
-- Must delete ALL user data, not just the users row
-- Test this with a real account — missed foreign keys = GDPR violation

-- Option 1: ON DELETE CASCADE on all foreign keys
ALTER TABLE entries ADD CONSTRAINT fk_entries_user
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Option 2: Deletion function (more control, audit trail)
CREATE OR REPLACE FUNCTION delete_user_data(p_user_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- Log deletion for audit (keep 30 days)
  INSERT INTO deletion_log (user_id, deleted_at) VALUES (p_user_id, now());
  
  -- Delete in dependency order
  DELETE FROM votes WHERE user_id = p_user_id;
  DELETE FROM entries WHERE user_id = p_user_id;
  DELETE FROM agents WHERE user_id = p_user_id;
  DELETE FROM subscriptions WHERE user_id = p_user_id;
  DELETE FROM team_members WHERE user_id = p_user_id;
  
  -- Delete storage files
  -- (handled separately via Edge Function)
  
  -- Finally delete auth user
  -- (triggers Supabase cascade)
END; $$;
```

### Data Export
```ts
// API route: GET /api/account/export
export async function GET() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return unauthorized()
  
  const [profile, agents, entries, votes] = await Promise.all([
    supabase.from('profiles').select('*').eq('user_id', user.id),
    supabase.from('agents').select('*').eq('user_id', user.id),
    supabase.from('entries').select('*').eq('user_id', user.id),
    supabase.from('votes').select('*').eq('user_id', user.id),
  ])
  
  return NextResponse.json({
    exported_at: new Date().toISOString(),
    profile: profile.data,
    agents: agents.data,
    entries: entries.data,
    votes: votes.data,
  })
}
```

### Consent Tracking (Append-Only)
```sql
CREATE TABLE consent_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id),
  consent_type text NOT NULL, -- 'marketing', 'analytics', 'cold_email'
  granted boolean NOT NULL,
  ip_address text,
  user_agent text,
  created_at timestamptz DEFAULT now()
  -- NO UPDATE or DELETE — append only
);
```

## Review Checklist

- [ ] Account deletion tested (deletes ALL user data across ALL tables)
- [ ] Data export endpoint exists and returns complete data
- [ ] Consent tracked in append-only table
- [ ] Unsubscribe link in every marketing/notification email
- [ ] No third-party analytics in children's app (COPPA)
- [ ] Privacy policy accessible from app + website
- [ ] DPAs signed with all data processors

## Sources
- FTC COPPA Rule (updated June 2025)
- CAN-SPAM Act requirements
- GDPR official text (Articles 15-20: data subject rights)
- Supabase GDPR compliance documentation

## Changelog
- 2026-03-21: Initial skill — compliance and regulatory
