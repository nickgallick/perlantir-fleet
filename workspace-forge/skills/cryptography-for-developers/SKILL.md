---
name: cryptography-for-developers
description: Using crypto correctly — hashing, HMAC, encryption, JWT internals, and review flags for cryptographic anti-patterns.
---

# Cryptography for Developers

## Review Flags (Instant P0)

- [ ] `Math.random()` for security tokens → use `crypto.randomBytes(32)` (P0)
- [ ] MD5 or SHA-1 for security purposes → use SHA-256 minimum (P0)
- [ ] String comparison (`===`) for signatures → use `crypto.timingSafeEqual()` (P1)
- [ ] Hardcoded encryption keys → use env vars minimum, KMS for production (P0)
- [ ] Custom crypto implementation → use standard library (P0)
- [ ] Passwords hashed with SHA-256 → use bcrypt or argon2id (P0)

---

## Hashing

### Passwords: bcrypt or argon2id (NEVER SHA-256)
```ts
import bcrypt from 'bcryptjs' // pure JS, works in Vercel serverless

// Hash
const hash = await bcrypt.hash(password, 12) // 12 rounds

// Verify
const match = await bcrypt.compare(inputPassword, storedHash)
```
**Why not SHA-256:** SHA-256 is too fast — attacker can try billions per second. bcrypt is intentionally slow (configurable work factor).

### Data Integrity: SHA-256
```ts
import { createHash } from 'crypto'

// File checksums, cache keys, webhook signatures
const hash = createHash('sha256').update(data).digest('hex')

// Transcript hash chain
const eventHash = createHash('sha256')
  .update(previousHash + sequenceNum + eventData)
  .digest('hex')
```

### Tokens: crypto.randomBytes
```ts
import { randomBytes } from 'crypto'

// ✅ Cryptographically secure random
const token = randomBytes(32).toString('hex') // 64 char hex string
const apiKey = randomBytes(24).toString('base64url') // URL-safe

// ❌ NOT secure — predictable, low entropy
const bad = Math.random().toString(36).slice(2)
```

---

## HMAC (Webhook Signature Verification)

```ts
import { createHmac, timingSafeEqual } from 'crypto'

function verifyWebhookSignature(
  payload: string,
  signature: string,
  secret: string
): boolean {
  const expected = createHmac('sha256', secret)
    .update(payload)
    .digest('hex')
  
  // MUST use timing-safe comparison
  // === leaks info about which bytes match via timing differences
  return timingSafeEqual(
    Buffer.from(signature, 'hex'),
    Buffer.from(expected, 'hex')
  )
}
```

**Why `timingSafeEqual`:** String `===` returns false as soon as it finds a mismatched byte. Attacker measures response time to learn which bytes are correct, one byte at a time. `timingSafeEqual` always compares all bytes in constant time.

---

## Encryption (AES-256-GCM)

```ts
import { createCipheriv, createDecipheriv, randomBytes } from 'crypto'

const ALGORITHM = 'aes-256-gcm'
const KEY = Buffer.from(process.env.ENCRYPTION_KEY!, 'hex') // 32 bytes

function encrypt(plaintext: string): string {
  const iv = randomBytes(12) // 12 bytes for GCM — NEVER reuse
  const cipher = createCipheriv(ALGORITHM, KEY, iv)
  
  const encrypted = Buffer.concat([
    cipher.update(plaintext, 'utf8'),
    cipher.final()
  ])
  const authTag = cipher.getAuthTag()
  
  // Return: iv.encrypted.authTag (all needed for decryption)
  return [
    iv.toString('hex'),
    encrypted.toString('hex'),
    authTag.toString('hex')
  ].join('.')
}

function decrypt(ciphertext: string): string {
  const [ivHex, encHex, tagHex] = ciphertext.split('.')
  const iv = Buffer.from(ivHex, 'hex')
  const encrypted = Buffer.from(encHex, 'hex')
  const authTag = Buffer.from(tagHex, 'hex')
  
  const decipher = createDecipheriv(ALGORITHM, KEY, iv)
  decipher.setAuthTag(authTag)
  
  return Buffer.concat([
    decipher.update(encrypted),
    decipher.final()
  ]).toString('utf8')
}
```

**Use for:** Gateway tokens at rest, API keys in database, sensitive configuration.

---

## JWT Internals

```
header.payload.signature

header:  {"alg":"HS256","typ":"JWT"}  → base64url encoded (readable, NOT encrypted)
payload: {"sub":"user-id","exp":1234} → base64url encoded (readable, NOT encrypted)
signature: HMAC-SHA256(header.payload, secret) → verifies integrity
```

**Critical rules:**
- JWT payload is NOT encrypted — anyone can read it (just base64 decode)
- NEVER store secrets in JWT payload
- ALWAYS verify: `exp` (expiration), `iss` (issuer), `aud` (audience)
- NEVER trust `alg: none` — reject unsigned JWTs

## Sources
- Node.js crypto documentation
- OWASP Cryptographic Storage Cheat Sheet
- OWASP Password Storage Cheat Sheet
- RFC 7519 (JWT specification)

## Changelog
- 2026-03-21: Initial skill — cryptography for developers
