# Supply Chain Attack Campaigns — Detailed Analysis

## PhantomRaven (Aug 2025 – Present)

### Overview
Ongoing npm supply-chain campaign using disposable accounts and slopsquatting to distribute credential-stealing packages.

### Technical Details
- **Entry**: Developer runs `npm install` on a typosquatted or slopsquatted package
- **Persistence mechanism**: Remote Dynamic Dependencies (RDD) — package.json points to an external URL for a dependency
- **Payload delivery**: Dependency downloaded from attacker's server at install time, bypassing npm's code scanning
- **Data stolen**:
  - Emails from `.gitconfig`
  - npm tokens from `.npmrc`
  - Environment variables (process.env)
  - CI/CD tokens: GitHub, GitLab, Jenkins, CircleCI
  - System fingerprint: IP, hostname, OS, Node version
- **Exfiltration**: HTTP GET (primary), HTTP POST and WebSocket (fallback)
- **Infrastructure**: Domains containing "artifact" on AWS EC2, no TLS certificate
- **Payload consistency**: 257 of 259 lines identical across all waves

### Detection Indicators
- Dependencies with URLs instead of version numbers
- Package publisher account <30 days old
- Package name resembles common library but is slightly different
- HTTP traffic to EC2 instances without TLS

### Scale
- Wave 1 (Aug–Oct 2025): 126 packages
- Waves 2–4 (Nov 2025–Feb 2026): 88 packages, 50 disposable accounts
- Total: 214+ packages, 81 still live in npm registry as of March 2026

---

## CanisterWorm (Feb–Mar 2026)

### Overview
First self-propagating npm worm using ICP blockchain for C2 resilience. Originated from compromised Trivy scanner supply chain.

### Technical Details
- **Entry**: `postinstall` hook in compromised package executes loader
- **Loader**: Drops Python backdoor
- **C2 resolution**: Contacts ICP canister (tamperproof blockchain smart contract) to get current C2 URL
  - Canister ID: `tdtqy-oyaaa-aaaae-af2dq-cai`
  - Methods: `get_latest_link`, `http_request`, `update_link`
  - Dormancy: URL set to youtube.com = safe; real URL = armed
- **Persistence**: systemd user service masquerading as "pgmon" (PostgreSQL monitoring)
  - `Restart=always` with 5-second delay
  - Beacons every 50 minutes with browser User-Agent
- **Self-propagation** (Gen 2, @teale.io/eslint-config):
  1. postinstall installs backdoor
  2. `findNpmTokens()` harvests all npm tokens from developer's machine
  3. Launches `deploy.js` as detached background process
  4. deploy.js: enumerate publishable packages → bump patch version → inject payload → republish
  5. Every downstream install repeats the cycle

### Detection Indicators
- systemd user service named "pgmon" in `~/.config/systemd/user/`
- Python process beaconing to `*.raw.icp0.io`
- npm packages with sudden patch version bump you didn't make
- `deploy.js` file in package root
- References to ICP canister IDs in source

### Scale
- 141+ malicious package artifacts
- 66+ unique packages
- Scopes: @EmilGroup (28), @opengov (16), plus individual packages

---

## GlassWorm (Oct 2025 – Present)

### Overview
VS Code extension supply chain attack using invisible Unicode, Solana blockchain C2, and transitive extension dependencies.

### Technical Details
- **Entry**: Developer installs malicious VS Code extension from Open VSX
- **Disguise**: Extensions mimic linters, formatters, AI coding tools (fake Claude Code, Google Antigravity)
- **Unicode payload**: Tags block characters encoding hidden JavaScript
- **C2**: Solana transactions as dead drop resolver — reads C2 URL from blockchain
- **Evasion**:
  - Russian locale check (skips Russian systems)
  - Heavier obfuscation in newer variants
  - Rotates Solana wallets
- **Transitive delivery** (March 2026 evolution):
  1. Publish benign extension, establish trust
  2. Update extension to add `extensionPack` or `extensionDependencies` pointing to GlassWorm extension
  3. VS Code auto-installs the dependency — no user prompt
  4. Malicious extension activates via the dependency chain
- **Also in npm**: Same Unicode technique deployed in npm packages simultaneously (cross-platform)

### Detection Indicators
- Extension with `extensionPack`/`extensionDependencies` pointing to unknown extensions
- Invisible Unicode characters in extension source (Tags block)
- Solana RPC calls in extension code
- Extension publisher with generic profile, single extension
- Extension name very similar to popular tool but slightly off

### Scale
- 72+ Open VSX extensions (latest wave)
- 151+ GitHub repositories poisoned
- 2 npm packages using same technique
- Extensions removed but attack pattern continues

---

## Malicious Next.js Repositories (Feb 2026)

### Overview
Microsoft-documented campaign using job-themed lures to deliver RCE through legitimate-looking Next.js projects.

### Technical Details
- **Entry**: Developer clones repo (job interview assessment, technical test, demo project)
- **Three attack paths**:

**Path 1: VS Code auto-exec**
- `.vscode/tasks.json` with `runOn: "folderOpen"` — executes on folder open
- Runs `env-setup.js` which fetches loader from Vercel

**Path 2: Build-time execution**
- Trojanized `jquery.min.js` or other common library
- Base64-encoded URL decoded at build time
- `npm run dev` triggers the payload

**Path 3: Server startup env exfil**
- `.env` contains `AUTH_API=<base64 encoded URL>`
- Backend route decodes URL, POSTs `process.env` to attacker
- Receives JavaScript, executes via `new Function("require", response.data)(require)`

- **C2**: Vercel-hosted staging endpoints (price-oracle-v2.vercel.app)
- **Persistence**: Staged C2 with registration phase, then persistent tasking
- **Naming patterns**: Cryptan, JP-soccer, RoyalJapan, SettleMint + variants (v1, master, demo, platform)

### Detection Indicators
- `.vscode/tasks.json` with `runOn: "folderOpen"`
- Base64-encoded strings in `.env` files
- `jquery.min.js` containing `atob()`, `fetch()`, or `XMLHttpRequest`
- Outbound connections to Vercel apps you didn't deploy
- `new Function("require", ...)` pattern in backend routes

---

## ClawHub Skill Malware (Feb 2026)

### Overview
341+ malicious skills uploaded to ClawHub (OpenClaw marketplace), some delivering Atomic Stealer macOS malware.

### Technical Details
- **Entry**: User installs skill from ClawHub
- **Infection chain**: 
  1. SKILL.md contains instructions to install a "prerequisite"
  2. OpenClaw follows the instruction, fetches from attacker URL
  3. Downloaded payload is Atomic Stealer variant
- **Evasion**: Skill appears benign, labeled benign on VirusTotal
- **Malware**: Atomic Stealer (macOS info stealer by Cookie Spider)

### Detection Indicators
- SKILL.md with `web_fetch` to external URLs
- Instructions to `exec` downloaded scripts
- "Prerequisite" installation steps pointing to non-standard URLs
- Publisher with no other skills or generic profile

### Prevention
- Always read SKILL.md fully before installing
- Run Unicode scan on all skill files
- Check scripts/ directory contents
- Verify publisher identity
- Prefer skills from trusted publishers with track record
