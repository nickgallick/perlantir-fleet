---
name: email-system-architecture
description: Email infrastructure — transactional vs marketing vs cold, React Email templates, Resend integration, deliverability fundamentals, and review checklist.
---

# Email System Architecture

## Review Checklist

- [ ] Transactional and cold email use SEPARATE domains
- [ ] React Email templates tested in Gmail, Outlook, Apple Mail
- [ ] Unsubscribe link in every marketing/notification email
- [ ] SPF/DKIM/DMARC configured on sending domain
- [ ] Bounce handling implemented (hard bounces removed)
- [ ] Email sending is async (doesn't block API response)
- [ ] Failed sends logged but don't crash the operation

---

## Three Email Categories (NEVER Mix Infrastructure)

| Category | Purpose | Service | Domain |
|----------|---------|---------|--------|
| **Transactional** | Password reset, purchase confirmation, challenge result | Resend, Postmark, SES | `notifications@agentarena.com` |
| **Marketing** | Newsletter, product updates | Resend, ConvertKit | `updates@agentarena.com` |
| **Cold outreach** | First contact (OUTBOUND) | Instantly, SmartLead | `hello@outbound-domain.com` |

**Rule:** If cold email domain gets blacklisted, password resets must still work. SEPARATE domains.

## React Email + Resend Pattern

```tsx
// emails/challenge-result.tsx
import { Html, Head, Preview, Body, Container, Text, Button } from '@react-email/components'

export function ChallengeResultEmail({ agentName, placement, challengeTitle, score }: Props) {
  return (
    <Html>
      <Head />
      <Preview>Your agent placed #{placement} in {challengeTitle}</Preview>
      <Body style={{ backgroundColor: '#1A1A1A', color: '#F5F0E8', fontFamily: 'sans-serif' }}>
        <Container style={{ maxWidth: 600, margin: '0 auto', padding: 40 }}>
          <Text style={{ fontSize: 24, fontWeight: 'bold' }}>
            🏆 Challenge Results
          </Text>
          <Text>
            {agentName} placed <strong>#{placement}</strong> in "{challengeTitle}" 
            with a score of {score}/30.
          </Text>
          <Button
            href="https://agentarena.com/results"
            style={{ backgroundColor: '#C8A97E', color: '#1A1A1A', padding: '12px 24px', borderRadius: 9999 }}
          >
            View Full Results
          </Button>
        </Container>
      </Body>
    </Html>
  )
}
```

```ts
// lib/email.ts
import { Resend } from 'resend'
import { ChallengeResultEmail } from '@/emails/challenge-result'

const resend = new Resend(process.env.RESEND_API_KEY)

export async function sendChallengeResult(to: string, data: ChallengeResultData) {
  try {
    await resend.emails.send({
      from: 'Agent Arena <notifications@agentarena.com>',
      to,
      subject: `Your agent placed #${data.placement} in ${data.challengeTitle}`,
      react: ChallengeResultEmail(data),
    })
  } catch (error) {
    // Log but don't crash — email failure shouldn't block the operation
    console.error('[email] Failed to send challenge result:', error)
  }
}
```

## Deliverability Fundamentals

| Factor | Target | Impact |
|--------|--------|--------|
| Spam complaint rate | <0.1% | Gmail enforces strictly. Above = spam folder. |
| Bounce rate | <2% | Remove hard bounces immediately |
| Authentication | SPF + DKIM + DMARC | All three required for inbox placement |
| Unsubscribe | One-click `List-Unsubscribe` header | Required by Gmail/Yahoo since Feb 2024 |
| Sender reputation | Build gradually | Ramp up volume slowly on new domains |

### Gmail/Yahoo Requirements (Since Feb 2024)
1. SPF or DKIM authentication (both preferred)
2. DMARC policy (at least `p=none`)
3. One-click unsubscribe header on bulk email
4. Spam complaint rate below 0.1%
5. Valid forward/reverse DNS for sending IP

### Bounce Handling
```ts
// Webhook from email provider
async function handleBounce(event: EmailEvent) {
  if (event.type === 'bounce') {
    if (event.bounceType === 'hard') {
      // Invalid email — remove immediately
      await supabase.from('users').update({ email_verified: false }).eq('email', event.email)
      // Don't send to this address again
      await supabase.from('suppression_list').upsert({ email: event.email, reason: 'hard_bounce' })
    }
    // Soft bounces (mailbox full) — retry 3x, then suppress
  }
}
```

## Sources
- resend/react-email component library
- resend/resend-node SDK
- Gmail sender guidelines (2024 update)
- DMARC.org specification

## Changelog
- 2026-03-21: Initial skill — email system architecture
