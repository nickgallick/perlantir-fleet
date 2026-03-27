# Unicode Ranges Reference — Steganography Detection

## Complete Dangerous Range Catalog

### Category 1: Steganography Carriers (hide arbitrary data)

#### Tags Block (U+E0000–U+E007F)
- **Purpose**: Originally for language tagging (deprecated by Unicode Consortium)
- **Attack use**: Direct ASCII encoding — `chr(ord(ch) - 0xE0000)` decodes to printable ASCII
- **Example**: U+E0070 = 'p', U+E0072 = 'r', U+E0069 = 'i', U+E006E = 'n', U+E0074 = 't'
- **Rendering**: Completely invisible in all editors, terminals, and web renderers
- **Legitimate use cases in source code**: NONE
- **Verdict**: Any occurrence in code = malicious

#### Supplementary Private Use Area-A (U+F0000–U+FFFFF)
- **Purpose**: Application-defined (no standard meaning)
- **Attack use**: Extended payload space, custom encoding schemes
- **Rendering**: Usually invisible or rendered as placeholder box
- **Legitimate use cases in source code**: NONE (except font files)
- **Verdict**: Any occurrence in code = highly suspicious

#### Supplementary Private Use Area-B (U+100000–U+10FFFF)
- Same as SPUA-A but even less commonly seen

### Category 2: Bidi Control Characters (visual reordering attacks)

#### Bidi Overrides (U+202A–U+202E)
| Codepoint | Name | Effect |
|-----------|------|--------|
| U+202A | Left-to-Right Embedding | Push LTR direction |
| U+202B | Right-to-Left Embedding | Push RTL direction |
| U+202C | Pop Directional Formatting | Pop last push |
| U+202D | Left-to-Right Override | Force LTR |
| U+202E | Right-to-Left Override | Force RTL |

- **Attack**: "Trojan Source" — code displays as one thing but executes as another
- **Example**: Access check `if (isAdmin‮ ⁦// check‬⁩)` can be reordered to always pass
- **CVE**: CVE-2021-42574 (original Trojan Source)

#### Bidi Isolates (U+2066–U+2069)
| Codepoint | Name | Effect |
|-----------|------|--------|
| U+2066 | Left-to-Right Isolate | Isolate LTR text |
| U+2067 | Right-to-Left Isolate | Isolate RTL text |
| U+2068 | First Strong Isolate | Auto-detect direction |
| U+2069 | Pop Directional Isolate | End isolate |

- Used in combination with overrides for more complex Trojan Source attacks

### Category 3: Zero-Width Characters (boundary/payload hiding)

| Codepoint | Name | Size | Notes |
|-----------|------|------|-------|
| U+200B | Zero-Width Space | 0px | Invisible word break — can encode binary as present/absent |
| U+200C | Zero-Width Non-Joiner | 0px | Legitimate in Arabic/Indic scripts |
| U+200D | Zero-Width Joiner | 0px | Legitimate in emoji sequences (👨‍👩‍👧) |
| U+2060 | Word Joiner | 0px | Invisible non-breaking |
| U+FEFF | BOM/ZWNBSP | 0px | Only legitimate at byte position 0 |
| U+00AD | Soft Hyphen | 0px usually | Breaks string matching |
| U+034F | Combining Grapheme Joiner | 0px | Invisible combiner |

- **Attack**: Binary steganography — encode bits as presence/absence of zero-width chars between visible chars
- **Attack**: Break keyword matching — insert ZWSP inside "exec" to bypass grep/static analysis

### Category 4: Variation Selectors (glyph modification)

| Range | Name | Count |
|-------|------|-------|
| U+FE00–U+FE0F | Variation Selectors | 16 |
| U+E0100–U+E01EF | Variation Selectors Supplement | 240 |

- **Purpose**: Select glyph variants (e.g., emoji vs text presentation)
- **Attack**: 256 selectors = 8 bits per visible character = high-bandwidth steganographic channel
- **In source code**: Never legitimate (only meaningful in font rendering contexts)

### Category 5: Format Characters (parsing disruption)

| Codepoint | Name | Risk |
|-----------|------|------|
| U+2028 | Line Separator | Breaks JavaScript string parsing — injected newline |
| U+2029 | Paragraph Separator | Same as above |
| U+061C | Arabic Letter Mark | Bidi control for Arabic text |
| U+2061–U+2064 | Invisible mathematical operators | Can alter expression meaning |

## Encoding Schemes Observed in the Wild

### Scheme 1: Direct Tags Decode
```
encoded_char → chr(ord(ch) - 0xE0000) → ASCII
```
Bandwidth: 1 hidden char = 1 ASCII char

### Scheme 2: Binary Zero-Width
```
ZWSP present = 1, absent = 0 → binary → ASCII
```
Bandwidth: 8 zero-width chars = 1 ASCII char (low bandwidth, very stealthy)

### Scheme 3: Variation Selector Index
```
VS number (0-255) → byte value → payload
```
Bandwidth: 1 VS char = 1 byte (high bandwidth)

### Scheme 4: Polymorphic Tags
```
seed = hash(visible_text)
decoded = chr((ord(ch) - 0xE0000 + seed) % 128)
```
Bandwidth: Same as direct, but payload varies per context (defeats signatures)

### Scheme 5: Mixed Range
```
Tags block + SPUA-A interleaved
Different ranges carry different parts of payload
```
Bandwidth: Increases total capacity, harder to detect with single-range filters
