---
name: unicode-steganography-detection
description: Detect hidden payloads concealed in source code via Unicode steganography — invisible characters from Tags block (U+E0000–E007F), Supplementary Private Use Areas (U+F0000–FFFFF, U+100000–10FFFF), zero-width characters (U+200B–200F, U+2060–2064, U+FEFF), variation selectors (U+FE00–FE0F, U+E0100–E01EF), and other non-printing ranges. Use when reviewing code, auditing dependencies, scanning repos before merge, installing third-party skills/packages, or conducting security reviews. Catches the GlassWorm, PhantomRaven, and CanisterWorm family of supply-chain attacks that hide exec/eval backdoors inside what appears to be legitimate sanitization or utility code.
---

# Unicode Steganography Detection

## Why This Matters

Unicode steganography is an active, in-the-wild attack technique used in:
- **GlassWorm** (72+ VS Code extensions, 151+ GitHub repos, npm packages — March 2026)
- **PhantomRaven** (88 npm packages — Nov 2025–Feb 2026)
- **CanisterWorm** (47+ npm packages — March 2026)
- **Malicious Next.js repositories** targeting developers (Microsoft report, Feb 2026)

Attackers embed invisible Unicode characters in source code that encode hidden instructions (shell commands, `exec()` calls, C2 URLs). The code looks clean in editors and GitHub diffs but contains a second hidden program.

## Dangerous Unicode Ranges

### Tier 1 — NEVER legitimate in source code
| Range | Name | Why Dangerous |
|-------|------|---------------|
| `U+E0000–U+E007F` | Tags block | Encodes ASCII 1:1 (subtract 0xE0000 to decode). Primary vector for GlassWorm. |
| `U+F0000–U+FFFFF` | Supplementary Private Use Area-A | No standard meaning. Used for expanded payload space. |
| `U+100000–U+10FFFF` | Supplementary Private Use Area-B | Same as above. |

### Tier 2 — Suspicious in code (rarely legitimate)
| Range | Name | Why Dangerous |
|-------|------|---------------|
| `U+200B` | Zero-Width Space | Invisible separator — hides payload boundaries |
| `U+200C–U+200D` | Zero-Width Non-Joiner/Joiner | Legitimate in some scripts (Arabic, Indic) but not in code |
| `U+200E–U+200F` | LTR/RTL marks | Can reorder displayed code vs actual execution order |
| `U+2060–U+2064` | Word joiner, invisible operators | Hide operations between visible tokens |
| `U+FEFF` | BOM / Zero-Width No-Break Space | Legitimate as BOM at byte 0 only; elsewhere suspicious |
| `U+FE00–U+FE0F` | Variation Selectors | Alter glyph rendering; no reason to exist in code |
| `U+E0100–U+E01EF` | Variation Selectors Supplement | Extended variation selectors |
| `U+00AD` | Soft Hyphen | Invisible in most renders, can break string matching |
| `U+034F` | Combining Grapheme Joiner | Invisible combiner |
| `U+061C` | Arabic Letter Mark | Bidi control — dangerous near security-sensitive strings |
| `U+2028–U+2029` | Line/Paragraph Separator | Can break JavaScript string parsing |
| `U+202A–U+202E` | Bidi overrides | **Trojan Source** attack — reorder displayed code |
| `U+2066–U+2069` | Bidi isolates | Same as above |

## Detection Procedure

### Step 1: Automated scan with script
Run `scripts/scan_unicode.py` against any file or directory:
```bash
python3 scripts/scan_unicode.py <path> [--strict] [--json]
```

Options:
- `--strict` — Flag Tier 2 characters in addition to Tier 1
- `--json` — Output as JSON for pipeline integration
- Default (no flags) — Tier 1 only (zero false positives in source code)

### Step 2: Manual review of flagged files
For each flagged file, check:

1. **Context** — Is the file a sanitizer, normalizer, encoder, or utility that "processes" Unicode? This is the most common disguise.
2. **Decode attempt** — For Tags block characters: `chr(ord(ch) - 0xE0000)` reveals the hidden ASCII
3. **Execution proximity** — Look within 20 lines for: `exec()`, `eval()`, `compile()`, `types.FunctionType()`, `new Function()`, `subprocess`, `os.system()`, `child_process`, `import()` dynamic imports
4. **Error suppression** — `except: pass`, `catch(e) {}`, empty error handlers near the Unicode processing = almost certainly malicious
5. **Trigger conditions** — Backdoors often gate on rare conditions (e.g., specific string in input, environment variable, time of day) so they don't fire in tests

### Step 3: Decode and analyze payload
For Tags block payloads:
```python
hidden = ''.join(ch for ch in text if 0xE0000 <= ord(ch) <= 0xE007F)
decoded = ''.join(chr(ord(ch) - 0xE0000) for ch in hidden)
print(decoded)  # The actual hidden payload
```

For polymorphic/XOR'd payloads: check if a hash, seed, or key is derived from visible text and used to transform the hidden bytes before execution. This is an escalation technique.

## Red Flags Checklist (Code Review)

When reviewing any code that handles Unicode or text processing, check for:

- [ ] **Extraction loop** — Code that separates characters by Unicode range (e.g., `if 0xE0000 <= ord(ch) <= 0xE007F`)
- [ ] **Decode loop** — Arithmetic on codepoints (subtract base, XOR with seed, modulo)
- [ ] **`exec()` / `eval()` / `compile()` / `new Function()`** anywhere near Unicode handling
- [ ] **`types.FunctionType()`** with `compile()` output — stealthier than direct `exec()`
- [ ] **Silent error handling** — `except: pass` or empty `catch` blocks after execution attempts
- [ ] **"Legacy compatibility"** or **"sanitizer"** framing — disguise layer for the extraction logic
- [ ] **Dead code that isn't dead** — Functions labeled as "deprecated" or "compat" that are still called
- [ ] **Hash-based transformation** — Using SHA256/MD5 of visible text as XOR key for hidden payload
- [ ] **Conditional triggers** — Payload only fires when specific strings present in input

## Real-World Attack Patterns

### Pattern 1: Fake Sanitizer (GlassWorm family)
```python
def sanitize(text):
    # "Remove" invisible chars (legitimate-looking)
    visible = ''.join(ch for ch in text if ch.isprintable())
    # But FIRST, extract and execute hidden payload
    hidden = ''.join(ch for ch in text if 0xE0000 <= ord(ch) <= 0xE007F)
    if hidden:
        exec(''.join(chr(ord(c) - 0xE0000) for c in hidden))
    return visible
```

### Pattern 2: Polymorphic Decode (evolved)
```python
import hashlib, types
seed = int(hashlib.sha256(visible.encode()).hexdigest()[:8], 16)
decoded = ''.join(chr((ord(ch) - 0xE0000 + seed) % 128) for ch in hidden)
code = compile(decoded, "<string>", "exec")
func = types.FunctionType(code.co_consts[0], globals())
func()
```

### Pattern 3: Trojan Source (Bidi override)
Uses `U+202A–U+202E` or `U+2066–U+2069` to make code DISPLAY differently than it EXECUTES. Example: an `if` check appears to validate access but actually always passes due to reordered characters.

### Pattern 4: JavaScript variant
```javascript
const clean = input.replace(/[\uE000-\uE07F]/g, '');
// But first...
const payload = [...input].filter(c => c.codePointAt(0) >= 0xE0000 && c.codePointAt(0) <= 0xE007F)
  .map(c => String.fromCodePoint(c.codePointAt(0) - 0xE0000)).join('');
if (payload) new Function(payload)();
```

### Pattern 5: VS Code Extension (GlassWorm March 2026)
Extensions use invisible Unicode in extension source + `extensionPack`/`extensionDependencies` to transitively load malicious extensions. The Unicode payload activates after trust is established through initial benign behavior.

## Integration with Forge Review Checklist

Add to existing review protocol as **Point 33: Unicode Steganography**:
- Scan all files in PR with `scan_unicode.py --strict`
- Any Tier 1 hit = automatic **BLOCKED** verdict
- Any Tier 2 hit in proximity to execution functions = **BLOCKED**
- Tier 2 hit in `.md`, `.txt`, or i18n files = **WARNINGS** (investigate context)

## When to Run This Skill

1. **Every code review** — run scan on changed files
2. **Every dependency install** — scan `node_modules` for new/updated packages
3. **Every skill install** — scan SKILL.md and all bundled resources
4. **Weekly security sweep** — full repo scan
5. **Ad-hoc** — when suspicious code is submitted for review

## References

For the scanning script, see `scripts/scan_unicode.py`.
For detailed Unicode range documentation, see `references/unicode-ranges.md`.
For attack campaign timelines, see `references/campaign-timeline.md`.
