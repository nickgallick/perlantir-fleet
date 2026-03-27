# Unicode Steganography Attack Campaign Timeline

## 2025

### March 2025
- **os-info-checker-es6** npm package discovered using invisible Unicode to hide malicious code (Aikido)
- First documented use of Tags block encoding in npm ecosystem

### August 2025
- **PhantomRaven** campaign begins publishing malicious npm packages
- Uses "slopsquatting" — package names that look like LLM suggestions (mimic Babel, GraphQL Codegen)

### October 2025
- **GlassWorm** first flagged by Koi Security in VS Code Marketplace and Open VSX
- Self-spreading mechanism via VS Code extensions
- Identifies Russian locale avoidance + Solana dead drop resolver for C2

### November 2025–February 2026
- **PhantomRaven waves 2–4** — 88 additional packages across 50 disposable accounts
- Introduces **Remote Dynamic Dependencies (RDD)**: package.json specifies dependency at external URL
- Malware exfiltrates .gitconfig, .npmrc, env vars, CI/CD tokens (GitHub, GitLab, Jenkins, CircleCI)
- As of March 2026: 81 packages still in npm registry

## 2026

### January–February 2026
- **GlassWorm expansion** — 72+ additional malicious Open VSX extensions discovered (Socket)
- New technique: **transitive delivery** via extensionPack/extensionDependencies
- Benign extension updated post-trust to pull GlassWorm-linked extension as dependency
- Extensions mimic linters, formatters, AI coding assistants (fake Claude Code, fake Google Antigravity)

### February 2026
- **Malicious Next.js repositories** (Microsoft Defender report)
  - Three attack paths: VS Code workspace auto-exec, build-time trojaned jQuery, server startup env exfil
  - Staged C2 via Vercel-hosted endpoints
  - Job-themed lures disguised as technical assessments
- **CanisterWorm** emerges from compromised Trivy scanner
  - Uses ICP blockchain canister as dead drop resolver (first documented abuse of ICP for C2)
  - Self-propagating: steals npm tokens, auto-publishes infected patch versions
  - 47+ npm packages compromised across @EmilGroup, @opengov scopes
  - Persistence via systemd user service masquerading as "pgmon"
  - Kill switch: youtube.com URL = dormant, real URL = armed

### March 2026 (current)
- **GlassWorm + npm convergence** — same Unicode technique deployed in both VS Code extensions and npm packages simultaneously
- **CanisterWorm mutates** — @teale.io/eslint-config versions 1.8.11-1.8.12 gain self-propagation without manual intervention
- Total scope: 141+ malicious package artifacts across 66+ unique packages (Socket)
- OWASP 2026 Top 10 adds **Software Supply Chain Failures** as A03

## Key Technique Evolution

| Generation | Technique | Evasion |
|------------|-----------|---------|
| Gen 1 | Direct `exec()` of decoded Tags | Minimal — caught by static analysis |
| Gen 2 | `compile()` + `types.FunctionType()` | Avoids `exec()` pattern matching |
| Gen 3 | Hash-seeded polymorphic decode | Payload changes per-input, no static signature |
| Gen 4 | Conditional trigger gate | Only fires on rare input conditions, passes all tests |
| Gen 5 | Transitive dependency delivery | Benign initial publish, malicious update via dep chain |
| Gen 6 | Self-propagating worm | Token theft → auto-publish → exponential spread |

## Infrastructure Patterns

- **C2 Domains**: PhantomRaven uses domains containing "artifact" on AWS EC2, no TLS
- **Dead Drop**: CanisterWorm uses ICP blockchain canister (tamperproof, censorship-resistant)
- **Staging**: Malicious Next.js repos use Vercel-hosted endpoints
- **Persistence**: systemd user service with Restart=always, 5-second delay
- **Dormancy**: youtube.com URL as kill switch (rickroll = safe, real URL = armed)
