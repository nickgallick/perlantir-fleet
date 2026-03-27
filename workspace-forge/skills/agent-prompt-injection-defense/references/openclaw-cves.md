# OpenClaw CVE and Security Advisory Log

## Critical / High Severity (Fixed)

### ClawJacked — WebSocket Hijacking
- **Source**: Oasis Security
- **Fixed in**: v2026.2.25 (February 26, 2026)
- **Attack**: Malicious website connects to localhost OpenClaw gateway via WebSocket, brute-forces password (no rate limit for localhost), auto-registers as trusted device (localhost bypass), gains full agent control
- **Impact**: Complete agent takeover from any website the developer visits
- **Check**: Run `openclaw --version` — must be ≥ 2026.2.25

### Log Poisoning → Prompt Injection
- **CVE**: GHSA-g27f-9qjv-22pm
- **Source**: Eye Security
- **Fixed in**: v2026.2.13 (February 14, 2026)
- **Attack**: Attacker writes malicious content to log files via public WebSocket (port 18789). Agent reads logs during troubleshooting and interprets injected content as instructions.
- **Impact**: Indirect agent manipulation, data disclosure, integration misuse
- **Check**: Block port 18789 from public internet

### CVE-2026-25593 — Remote Code Execution
- **Fixed in**: v2026.2.2
- **Severity**: High

### CVE-2026-24763 — Command Injection
- **Fixed in**: v2026.2.1
- **Severity**: High

### CVE-2026-25157 — SSRF (Server-Side Request Forgery)
- **Fixed in**: v2026.2.1
- **Severity**: High
- **Note**: SSRF could allow agent to make requests to internal services

### CVE-2026-25475 — Authentication Bypass
- **Fixed in**: v2026.1.29
- **Severity**: High

### CVE-2026-26319, CVE-2026-26322, CVE-2026-26329 — Multiple Vulnerabilities
- **Source**: Endor Labs (AI SAST analysis)
- **Fixed in**: v2026.2.14
- **Types**: Data flow vulnerabilities discovered via taint analysis
- **Severity**: Moderate to High

### CVE-2026-29057 — Path Traversal (various versions)
- **Fixed in**: v2026.1.20
- **Severity**: Moderate
- **Note**: Different from Supabase storage path traversal

## Medium Severity

### PromptArmor Link Preview Exfiltration
- **Not a CVE** — architectural vulnerability in agentic systems
- **Source**: PromptArmor Research
- **No direct patch**: Requires operational hardening
- **Attack**: Agent generates URL with sensitive data; Telegram/Discord link preview auto-fetches it
- **Mitigation**: Never include sensitive data in URLs; review what data is in context when fetching content

## Currently Unpatched / Architectural Risks

### 1. Indirect Prompt Injection via External Content
- **Status**: Inherent risk, requires operational discipline
- **Mitigation**: Layer 1-5 defenses in SKILL.md

### 2. Malicious ClawHub Skills
- **Scale**: 341+ malicious skills identified (Feb 2026)
- **Malware**: Atomic Stealer (macOS), GhostSocks proxy
- **Mitigation**: Manual review of every skill before install; no automatic installs

### 3. Malicious GitHub Repos Impersonating OpenClaw
- **Source**: Huntress
- **Attack**: Fake OpenClaw repos with RCE payloads; became top Bing AI search result
- **Mitigation**: Only install OpenClaw from official source (github.com/openclaw/openclaw)

## CNCERT Advisory Summary (March 2026)

China's National Computer Network Emergency Response Technical Team issued advisory on OpenClaw risks:

**Identified risks**:
1. Weak default security configurations + privileged system access = high blast radius
2. Prompt injection via web content summarization
3. Risk of irreversible data deletion via misinterpreted instructions
4. Malicious skills via ClawHub
5. Known exploitable vulnerabilities

**Recommended controls** (all applicable to our setup):
- [ ] Strengthen network controls — firewall OpenClaw ports
- [ ] Prevent exposure of management port to internet
- [ ] Isolate service in a container
- [ ] Avoid storing credentials in plaintext
- [ ] Download skills only from trusted channels
- [ ] Disable automatic skill updates
- [ ] Keep OpenClaw up-to-date (auto-update the runtime, manual-review skills)

## Version Check Command

```bash
# Check current version
openclaw --version
# or
openclaw gateway status | grep version

# Expected: 2026.2.25 or later for ClawJacked fix
# Expected: 2026.2.14 or later for all Endor Labs findings
```

## Hardening Verification Script

```bash
#!/bin/bash
echo "=== OpenClaw Security Check ==="

# Version check
VERSION=$(openclaw --version 2>/dev/null | grep -oP '[\d.]+')
echo "Version: $VERSION"
if [[ "$VERSION" < "2026.2.25" ]]; then
  echo "❌ CRITICAL: Upgrade required for ClawJacked fix"
else
  echo "✅ Version OK"
fi

# Port 18789 exposure check
if nc -z -w1 0.0.0.0 18789 2>/dev/null; then
  echo "⚠️  Port 18789 is accessible — check firewall rules"
else
  echo "✅ Port 18789 not publicly accessible"
fi

# Check for gateway password (non-default)
# (Manual verification required — check openclaw.json)
echo "⚠️  Manually verify: gateway password is not default"
echo "⚠️  Manually verify: skills only from trusted sources"
echo "⚠️  Manually verify: credentials not stored in plaintext"
```
