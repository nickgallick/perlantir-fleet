# Python Obfuscation Catalog — Complete Reference

## Execution Primitives

Every Python backdoor eventually calls one of these. Everything else is disguise.

| Primitive | What It Does | Risk |
|-----------|-------------|------|
| `exec(code)` | Execute arbitrary Python code | RCE |
| `eval(expr)` | Evaluate expression, return result | RCE (limited to expressions) |
| `compile(source, file, mode)` | Compile string to code object | Enables exec-free execution via FunctionType |
| `types.FunctionType(code, globals)` | Create function from code object | RCE without calling exec |
| `os.system(cmd)` | Execute shell command | RCE |
| `os.popen(cmd)` | Execute shell, return pipe | RCE |
| `subprocess.Popen(cmd)` | Execute subprocess | RCE |
| `subprocess.run(cmd)` | Execute subprocess | RCE |
| `importlib.import_module(name)` | Dynamic import | Code loading |
| `__import__(name)` | Dynamic import | Code loading |
| `marshal.loads(bytes)` | Deserialize bytecode | Execute pre-compiled code |
| `pickle.loads(bytes)` | Deserialize objects | RCE via __reduce__ |
| `ctypes.CDLL(path)` | Load shared library | Native RCE |

## Obfuscation Technique Matrix

### String Hiding
| Technique | Example | Detection |
|-----------|---------|-----------|
| Concatenation | `"ex" + "ec"` | Evaluate string expressions |
| Reversal | `"cexe"[::-1]` | Detect slice reversal patterns |
| Join/reversed | `"".join(reversed(["ec","ex"]))` | Track join() with reversed() |
| ROT13 | `codecs.decode("rkrp","rot_13")` | Flag rot_13 codec usage |
| Base64 | `b64decode("ZXhlYw==")` | Decode and check result |
| Hex | `bytes.fromhex("65786563")` | Decode and check result |
| Chr assembly | `chr(101)+chr(120)+chr(101)+chr(99)` | Detect chr() chains |
| F-string | `f"{'ex'}{'ec'}"` | Evaluate f-string concatenation |
| Format | `"{}{}".format("ex","ec")` | Track format calls |

### Import Hiding
| Technique | Example | Detection |
|-----------|---------|-----------|
| `__import__` | `__import__("builtins")` | Flag all `__import__` calls |
| importlib | `importlib.import_module("builtins")` | Flag importlib usage |
| sys.modules | `sys.modules["builtins"]` | Flag sys.modules access |
| globals() | `globals()["__builtins__"]` | Flag globals() indexing |
| locals() | `locals()["builtins"]` | Flag locals() indexing |
| vars() | `vars()["builtins"]` | Flag vars() with string index |

### Attribute Access Hiding
| Technique | Example | Detection |
|-----------|---------|-----------|
| getattr | `getattr(obj, "exec")` | Track getattr with string resolution |
| `__getattribute__` | `obj.__getattribute__("exec")` | Flag dunder attribute access |
| dict access | `obj.__dict__["exec"]` | Flag __dict__ string indexing |

### Encoding/Compression
| Technique | Module | Detection |
|-----------|--------|-----------|
| Base64 | `base64` | Flag b64decode near exec |
| Hex | `bytes.fromhex` | Flag fromhex near exec |
| ROT13 | `codecs` | Flag rot_13 codec |
| Zlib | `zlib.decompress` | Flag decompress near exec |
| Bz2 | `bz2.decompress` | Flag decompress near exec |
| LZMA | `lzma.decompress` | Flag decompress near exec |
| Marshal | `marshal.loads` | ALWAYS flag — bytecode deser |
| Pickle | `pickle.loads` | ALWAYS flag — object deser RCE |

## Homoglyph Substitution Table (Python-specific)

Python allows Unicode identifiers (PEP 3131). These are the most dangerous confusables:

| Latin | Confusable | Script | Codepoint |
|-------|-----------|--------|-----------|
| a | а | Cyrillic | U+0430 |
| c | с | Cyrillic | U+0441 |
| e | е | Cyrillic | U+0435 |
| o | о | Cyrillic | U+043E |
| p | р | Cyrillic | U+0440 |
| x | х | Cyrillic | U+0445 |
| y | у | Cyrillic | U+0443 |
| A | А | Cyrillic | U+0410 |
| B | В | Cyrillic | U+0412 |
| C | С | Cyrillic | U+0421 |
| E | Е | Cyrillic | U+0415 |
| H | Н | Cyrillic | U+041D |
| K | К | Cyrillic | U+041A |
| M | М | Cyrillic | U+041C |
| O | О | Cyrillic | U+041E |
| P | Р | Cyrillic | U+0420 |
| T | Т | Cyrillic | U+0422 |
| X | Х | Cyrillic | U+0425 |
| e | ℯ | Math Script | U+212F |
| x | 𝓍 | Math Script | U+1D4CD |

**Rule**: In security-critical code, ALL identifiers must be pure ASCII. Any non-ASCII character in a Python identifier is a flag.

## Dangerous Module Combinations

These import combinations are almost never legitimate in application code:

| Combination | Why Suspicious |
|-------------|---------------|
| `types` + `compile` | FunctionType from compiled code = exec bypass |
| `importlib.util` + `exec` | Module creation + code injection |
| `marshal` + any execution | Bytecode deserialization + execution |
| `pickle` + network/file I/O | Deserialization RCE from untrusted source |
| `ctypes` + string operations | Native code loading from constructed paths |
| `base64` + `exec`/`eval` | Encoded payload execution |
| `subprocess` + string formatting | Command injection via constructed strings |
| `os` + `getenv` + `exec` | Environment-gated code execution |

## Known Tool Obfuscators

If you see artifacts from these tools, the code was intentionally obfuscated:

| Tool | Artifacts |
|------|-----------|
| **Pyarmor** | `from pytransform import pyarmor_runtime` / `.pyd` files |
| **PyInstaller** | Not obfuscation per se, but hides source code in executables |
| **Cython-compiled** | `.so`/`.pyd` binary modules replacing `.py` |
| **Custom XOR** | Byte-level XOR loops with hardcoded or derived keys |
| **Marshal dumps** | `.pyc`-like embedded bytecode loaded via marshal |

Any obfuscation in a package that claims to be open source is a red flag.
