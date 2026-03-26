---
name: redos-and-dos-patterns
description: Detection and prevention of Denial of Service vulnerabilities in Node.js applications — ReDoS (Regular Expression Denial of Service), event loop blocking, resource exhaustion, algorithmic complexity attacks, and application-layer DoS patterns. Use when reviewing code containing regular expressions, input parsing, file processing, database queries without limits, recursive operations, or any code that processes user-controlled input where processing time is proportional to input complexity. Covers CVE-2026-30925 (Parse Server ReDoS — CRITICAL), catastrophic backtracking, polynomial/exponential regex patterns, and Node.js-specific event loop starvation.
---

# ReDoS & Denial of Service Patterns

## Why DoS Is Especially Dangerous in Node.js

Node.js runs on a **single-threaded event loop**. If one request blocks the event loop for 10 seconds, **ALL requests are blocked for 10 seconds**. There's no thread pool to absorb the hit (except for some I/O operations).

A single malicious regex match can freeze your entire application.

## ReDoS (Regular Expression Denial of Service)

### How It Works
Certain regex patterns have **catastrophic backtracking** — when matching fails on carefully crafted input, the regex engine tries exponentially many paths before giving up.

```javascript
// VULNERABLE — catastrophic backtracking
const emailRegex = /^([a-zA-Z0-9]+\.)+[a-zA-Z]{2,}$/
emailRegex.test('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa!')
// This takes SECONDS to fail — exponential backtracking on the (group)+
```

### The Three Ingredients for ReDoS
1. **Quantified group with overlap**: `(a+)+`, `(a|a)+`, `(a*)*`
2. **Ambiguity**: The regex engine can match the same character via multiple paths
3. **Failing match**: The worst case happens when the match ultimately FAILS, forcing the engine to exhaust all paths

### Dangerous Regex Patterns

| Pattern | Problem | Example Attack Input |
|---------|---------|---------------------|
| `(a+)+` | Nested quantifiers | `'a'.repeat(30) + '!'` |
| `(a\|a)+` | Alternation overlap | `'a'.repeat(30) + '!'` |
| `(a+b?)+` | Optional following quantified | `'a'.repeat(30) + '!'` |
| `(\w+\.)+\w+` | Repeated group with anchoring | `'a.'.repeat(20) + '!'` |
| `(.*a){x}` | Greedy with fixed follow | Long string without enough 'a's |
| `([a-zA-Z]+)*` | Character class in quantified group | `'a'.repeat(30) + '1'` |

### Real-World ReDoS: CVE-2026-30925 (Parse Server)
**CRITICAL severity** — unauthenticated complete DoS.

Parse Server allowed LiveQuery subscriptions with `$regex` patterns. Attacker subscribes with a catastrophic regex → server's event loop freezes → all users denied service.

```javascript
// Attack: Subscribe to LiveQuery with evil regex
const query = new Parse.Query('Messages')
query.matches('content', new RegExp('(a+)+$'))
// When any message is created, the regex is evaluated against it
// If content contains 'aaa...!' — server freezes
```

### Detection: Identifying Vulnerable Regex

#### Automated: Use safe-regex or recheck
```bash
npm install safe-regex2
```

```javascript
const safeRegex = require('safe-regex2')

// Check regex patterns in your codebase
safeRegex(/(a+)+$/)        // false — vulnerable
safeRegex(/^[a-z]+$/)      // true — safe
safeRegex(/(\w+\.)+\w+$/)  // false — vulnerable
```

#### Manual: The Overlap Test
For any regex in the codebase:
1. Find all quantified groups: `(...)+`, `(...)*`, `(...){n,}`
2. For each group, check: can the same character be matched by the group AND by what follows?
3. If yes → potential ReDoS. Test with `'a'.repeat(25) + '!'`

#### Grep for Suspicious Patterns
```bash
# Find potentially vulnerable regex in codebase
grep -rn 'new RegExp\|/.*[+*].*[+*].*/' --include='*.{ts,js,tsx,jsx}' | \
  grep -v 'node_modules\|\.test\.\|\.spec\.'
```

### Fix: Safe Regex Alternatives

```typescript
// VULNERABLE
const emailRegex = /^([a-zA-Z0-9]+\.)+[a-zA-Z]{2,}$/

// SAFE — use possessive quantifiers (not in JS) or atomic groups
// In JS, restructure to avoid ambiguity:
const emailRegex = /^[a-zA-Z0-9]+(?:\.[a-zA-Z0-9]+)*\.[a-zA-Z]{2,}$/

// SAFEST — use a validation library instead of regex
import { z } from 'zod'
const email = z.string().email()  // Zod's email validator, no regex
```

```typescript
// For user-provided regex (e.g., search/filter):
// NEVER pass user input to new RegExp() without protection

// Option 1: Don't allow regex at all — use string matching
const results = items.filter(item => item.name.includes(searchTerm))

// Option 2: Escape regex special characters
function escapeRegex(str: string): string {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
}
const safeRegex = new RegExp(escapeRegex(userInput), 'i')

// Option 3: Timeout protection
function safeRegexTest(pattern: RegExp, input: string, timeoutMs: number = 100): boolean {
  // Use worker_threads for true timeout protection
  // Simple approach: limit input length
  if (input.length > 1000) return false
  return pattern.test(input)
}
```

## Event Loop Blocking

### Synchronous Operations
```typescript
// DANGEROUS in request handler — blocks event loop
import fs from 'fs'
const data = fs.readFileSync('/large/file')  // Blocks ALL requests
JSON.parse(hugeString)  // Blocks during parse
crypto.pbkdf2Sync(password, salt, 100000, 64, 'sha512')  // Blocks during hash

// SAFE — async equivalents
const data = await fs.promises.readFile('/large/file')
// For JSON, consider streaming parser for large payloads
// For crypto, use async: await promisify(crypto.pbkdf2)(...)
```

### CPU-Intensive Operations
```typescript
// DANGEROUS — O(n²) or worse in request handler
function findDuplicates(arr: string[]) {
  return arr.filter((item, index) => arr.indexOf(item) !== index)
  // O(n²) — 10K items = 100M operations
}

// SAFE — O(n) with Set
function findDuplicates(arr: string[]) {
  const seen = new Set<string>()
  return arr.filter(item => seen.has(item) || !seen.add(item))
}
```

## Resource Exhaustion

### Unbounded Input Size
```typescript
// VULNERABLE — no size limit on request body
export async function POST(request: Request) {
  const body = await request.json()  // 1GB JSON? Sure, let's parse it
  const items = body.items  // 10 million items? Let's process them all
  for (const item of items) { await processItem(item) }
}

// SAFE — limit request body size
export async function POST(request: Request) {
  const contentLength = parseInt(request.headers.get('content-length') || '0')
  if (contentLength > 1_000_000) {  // 1MB limit
    return new Response('Payload too large', { status: 413 })
  }
  
  const body = await request.json()
  if (!Array.isArray(body.items) || body.items.length > 100) {
    return new Response('Too many items', { status: 400 })
  }
}
```

### Unbounded Database Queries
```typescript
// VULNERABLE — no LIMIT, could return millions of rows
const { data } = await supabase.from('logs').select('*')

// SAFE — always paginate
const { data } = await supabase.from('logs').select('*').range(0, 99)
```

### Zip Bomb / Decompression Bomb
```typescript
// VULNERABLE — decompress without size check
const decompressed = zlib.gunzipSync(uploadedFile)
// 42.zip: 42KB compressed → 4.5 PB decompressed

// SAFE — limit decompressed size
const decompressor = zlib.createGunzip()
let totalBytes = 0
const MAX_SIZE = 100 * 1024 * 1024  // 100MB
decompressor.on('data', (chunk) => {
  totalBytes += chunk.length
  if (totalBytes > MAX_SIZE) {
    decompressor.destroy(new Error('Decompressed size exceeds limit'))
  }
})
```

### XML Bomb (Billion Laughs)
```xml
<!-- 10^9 expansions = ~3GB from tiny input -->
<!DOCTYPE bomb [
  <!ENTITY a "AAAAAAAAAA">
  <!ENTITY b "&a;&a;&a;&a;&a;&a;&a;&a;&a;&a;">
  <!ENTITY c "&b;&b;&b;&b;&b;&b;&b;&b;&b;&b;">
  <!-- ... 7 more levels ... -->
]>
<data>&i;</data>
```

**Defense**: Disable DTD processing in XML parsers. Use JSON instead of XML where possible.

## Algorithmic Complexity Attacks

### Hash Table DoS (Hash Flooding)
If attacker controls keys inserted into a hash map, they can craft keys that all hash to the same bucket → O(n²) insertion time.

**V8 (Node.js)**: Mitigated in modern versions with randomized hash seeds, but still relevant for custom hash implementations.

### Sorting Attacks
If attacker controls input to a sort algorithm, they can trigger worst-case O(n²) behavior in certain implementations.

**Defense**: Use algorithms with guaranteed O(n log n) worst case (mergesort). V8's Array.sort uses TimSort, which is safe.

## Review Checklist

### Regex
- [ ] Every regex in codebase tested with `safe-regex2`
- [ ] No `new RegExp(userInput)` without escaping
- [ ] User-provided regex (search, filter) has input length limits
- [ ] Regex-based validation replaced with Zod where possible

### Input Limits
- [ ] Request body size limited (middleware or per-route)
- [ ] Array/collection sizes validated before processing
- [ ] String lengths validated before regex/parsing
- [ ] File upload sizes limited
- [ ] Decompression size limited

### Database
- [ ] All queries have LIMIT/pagination
- [ ] No `select('*')` on large tables without filters
- [ ] Complex queries have timeouts (`statement_timeout`)

### Event Loop
- [ ] No synchronous file operations in request handlers
- [ ] No CPU-intensive loops in request handlers (>50ms)
- [ ] Crypto operations use async variants
- [ ] Large JSON parsing uses streaming for untrusted input

### General
- [ ] Rate limiting on all public endpoints (see `api-rate-limiting-abuse` skill)
- [ ] Timeouts on all external HTTP requests
- [ ] Circuit breakers on external service calls
- [ ] Health check endpoint that doesn't do heavy work

## References

For rate limiting patterns, see `api-rate-limiting-abuse` skill.
For database query optimization, see `advanced-postgres` skill.
