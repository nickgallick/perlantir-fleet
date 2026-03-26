---
name: prototype-pollution-chains
description: Detection and exploitation understanding of JavaScript prototype pollution vulnerabilities, from source identification through gadget chains to RCE. Use when reviewing code that merges objects, parses JSON, uses lodash/underscore deep operations, processes GraphQL responses, handles deserialization (React Flight, devalue, flatted), or any code where user input flows into object property assignment. Covers CVE-2025-13465 (Lodash), CVE-2025-55182 (React2Shell via pollution), CVE-2026-30226 (Svelte devalue), CVE-2026-33228 (flatted), CVE-2026-12345 (Apollo Federation CRITICAL). Essential for Next.js + Supabase stack review.
---

# Prototype Pollution Chains

## What Is Prototype Pollution?

Every JavaScript object inherits from `Object.prototype`. If an attacker can write a property to `Object.prototype`, that property appears on ALL objects in the application.

```javascript
// The attack
const obj = {}
obj.__proto__.isAdmin = true

// Now EVERY object has isAdmin
const user = {}
console.log(user.isAdmin)  // true — user never had this property
```

**Why it matters**: Alone, it's often "just" DoS or type confusion. But combined with the right gadget chain, it escalates to **full RCE**.

## Pollution Sources (Where It Enters)

### Source 1: Recursive Object Merge / Deep Clone
```javascript
// VULNERABLE — any deep merge without __proto__ filtering
function merge(target, source) {
  for (let key in source) {
    if (typeof source[key] === 'object') {
      target[key] = merge(target[key] || {}, source[key])
    } else {
      target[key] = source[key]
    }
  }
  return target
}

// Attacker sends:
merge({}, JSON.parse('{"__proto__": {"isAdmin": true}}'))
```

**Affected libraries** (check versions):
- `lodash.merge`, `lodash.defaultsDeep`, `lodash.set` — CVE-2025-13465
- `hoek.merge` (hapi ecosystem)
- `deep-extend`
- `deepmerge` (older versions)
- `jQuery.extend(true, ...)` (deep mode)
- Any custom recursive merge

### Source 2: JSON.parse + Property Assignment
```javascript
// VULNERABLE — user-controlled JSON assigned to object
const config = JSON.parse(userInput)
Object.assign(defaults, config)  // If config has __proto__, it's set
```

### Source 3: URL Query Parameter Parsing
```javascript
// VULNERABLE — qs library with allowPrototypes
const qs = require('qs')
const parsed = qs.parse('__proto__[isAdmin]=true')
// parsed.__proto__.isAdmin = 'true'
```

### Source 4: GraphQL Response Merging (CVE-2026-12345 — CRITICAL)
Apollo Federation gateway merges subgraph responses. A compromised subgraph can return:
```json
{"__proto__": {"polluted": true}}
```
Gateway merges without sanitization → global prototype pollution.

### Source 5: Deserialization Libraries
- **React Flight protocol** (CVE-2025-55182) — deserialized RSC payloads can pollute prototypes → RCE via `child_process.execSync`
- **Svelte devalue** (CVE-2026-30226) — `unflatten()` allows pollution
- **flatted** (CVE-2026-33228) — `parse()` returns object with live reference to Array.prototype

### Source 6: Path-Based Property Assignment
```javascript
// VULNERABLE — lodash.set or manual path assignment
function setByPath(obj, path, value) {
  const keys = path.split('.')
  let current = obj
  for (let i = 0; i < keys.length - 1; i++) {
    current = current[keys[i]] = current[keys[i]] || {}
  }
  current[keys[keys.length - 1]] = value
}

// Attacker: setByPath({}, '__proto__.isAdmin', true)
```

## Gadget Chains (How Pollution → RCE)

### Gadget 1: child_process via Shell Option
```javascript
// If Object.prototype.shell is polluted:
Object.prototype.shell = true
Object.prototype.NODE_OPTIONS = '--require /proc/self/environ'

// Any subsequent child_process.spawn/exec inherits polluted options
const { execSync } = require('child_process')
execSync('echo pwned')  // Uses polluted shell option
```

### Gadget 2: EJS Template Engine
```javascript
// If Object.prototype.outputFunctionName is polluted:
Object.prototype.outputFunctionName = 'x;process.mainModule.require("child_process").execSync("id");x'

// When EJS renders any template:
ejs.render('<%= user %>', { user: 'test' })
// The polluted outputFunctionName gets injected into the template compilation
```

### Gadget 3: Pug Template Engine
```javascript
Object.prototype.block = {"type": "Text", "val": "x]));process.mainModule.require('child_process').execSync('id');//"}
// Pug template compilation includes the polluted block
```

### Gadget 4: Handlebars
```javascript
Object.prototype.main = 'process.mainModule.require("child_process").execSync("id")'
Object.prototype.layout = false
// Handlebars compilation executes polluted main
```

### Gadget 5: React2Shell Chain (CVE-2025-55182)
```
1. Attacker sends crafted Flight protocol payload
2. React deserializer doesn't validate types
3. Prototype pollution occurs during deserialization
4. Gadget: child_process.execSync available in Node.js
5. RCE on the Next.js server
```

## Detection in Code Review

### Automated Grep
```bash
# Object merge patterns
grep -rn 'Object\.assign\|\.merge\|\.extend\|\.defaults\|deepmerge\|deep-extend' --include='*.{js,ts,jsx,tsx}'

# Path-based assignment
grep -rn 'lodash\.set\|_.set\|setByPath\|setProperty' --include='*.{js,ts,jsx,tsx}'

# Dangerous property access without filtering
grep -rn '__proto__\|constructor\[' --include='*.{js,ts,jsx,tsx}'

# JSON.parse flowing into merge/assign
grep -rn 'JSON\.parse.*Object\.assign\|JSON\.parse.*merge\|JSON\.parse.*extend' --include='*.{js,ts,jsx,tsx}'
```

### Manual Review Checklist
- [ ] **Any recursive object merge** — does it filter `__proto__`, `constructor`, `prototype`?
- [ ] **Any `Object.assign(target, userInput)`** — is userInput validated?
- [ ] **Any path-based property set** (lodash.set, custom) — does it reject `__proto__` paths?
- [ ] **Any deserialization** (JSON.parse, devalue, flatted, Flight) — are results sanitized before merge?
- [ ] **Any GraphQL response handling** — are subgraph responses validated?
- [ ] **Query string parsing** — is `allowPrototypes: false` set (qs library)?
- [ ] **Template engine in use** — EJS, Pug, Handlebars are gadget-rich

### Safe Merge Pattern
```typescript
function safeMerge(target: Record<string, any>, source: Record<string, any>) {
  for (const key of Object.keys(source)) {
    // Block prototype pollution keys
    if (key === '__proto__' || key === 'constructor' || key === 'prototype') continue
    
    if (typeof source[key] === 'object' && source[key] !== null && !Array.isArray(source[key])) {
      target[key] = safeMerge(target[key] || {}, source[key])
    } else {
      target[key] = source[key]
    }
  }
  return target
}
```

### Safe Object Creation
```typescript
// Create objects without prototype — immune to pollution
const cleanObj = Object.create(null)
// cleanObj has no __proto__, no constructor, no toString
```

## Severity Escalation Matrix

| Pollution Source | Available Gadget | Resulting Impact |
|-----------------|-----------------|------------------|
| Any pollution | None found | DoS / type confusion (P2) |
| Any pollution | Template engine (EJS/Pug/HBS) | RCE (P0) |
| Any pollution | child_process options | RCE (P0) |
| Any pollution | Auth check bypass (`isAdmin`) | Privilege escalation (P0) |
| Any pollution | SQL query builder options | SQL injection (P1) |
| React Flight deser | child_process | Unauthenticated RCE (P0) |
| GraphQL federation | Depends on backend | Variable — up to RCE (P0) |

**Key insight**: Never dismiss prototype pollution as "low severity" without checking for available gadgets. The gadget search determines the real impact.

## Review Integration

When reviewing any PR:
1. **Check for merge/assign patterns** — does user data flow into object merges?
2. **Check deserialization boundaries** — JSON.parse, query params, form data
3. **Check dependency versions** — lodash, qs, devalue, flatted, apollo
4. **If pollution found, search for gadgets** — template engines, child_process usage, auth checks that read object properties

## References

For gadget catalog by framework, see `references/gadget-catalog.md`.
