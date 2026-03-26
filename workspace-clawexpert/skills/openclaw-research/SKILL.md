# Skill: OpenClaw Research

## Changelog
- 2026-03-19: Initial creation

## Overview
Procedures and sources for researching OpenClaw updates, ecosystem changes, and relevant intelligence.

## Primary Sources

### Official
- **Releases**: https://github.com/openclaw/openclaw/releases
- **Changelog**: https://github.com/openclaw/openclaw/blob/main/CHANGELOG.md
- **Issues**: https://github.com/openclaw/openclaw/issues
- **Documentation**: https://docs.openclaw.ai

### Package Registries
- **OpenClaw npm**: https://www.npmjs.com/package/openclaw
- **mcporter npm**: https://www.npmjs.com/package/mcporter
- **stitch-mcp npm**: https://www.npmjs.com/package/@_davideast/stitch-mcp

### Security
- **CVE databases**: For dependency vulnerability checks
- **GitHub Security Advisories**: For OpenClaw-specific advisories
- **npm audit**: For JavaScript dependency vulnerabilities

## Research Procedures

### Version Check
1. Check current version: 2026.3.13 (stable)
2. Check latest release on GitHub
3. Read CHANGELOG for changes between versions
4. Assess breaking changes and migration requirements
5. Report findings using Intelligence Briefing format

### Dependency Audit
1. Check npm for updates to core packages
2. Review changelogs for security fixes
3. Check for deprecated dependencies
4. Assess upgrade risk vs benefit

### Community Monitoring
1. Review recent GitHub issues for our version
2. Check for common patterns in bug reports
3. Look for workarounds shared by other users
4. Monitor discussions for best practices

### Security Research
1. Run `npm audit` equivalent checks
2. Check CVE databases for dependency vulnerabilities
3. Review Docker image for known vulnerabilities
4. Check for exposed secrets or misconfigurations

## Research Output Format
All research findings should use the Intelligence Briefing format from SOUL.md:

🔍 **ClawExpert Intel**
**Category**: [Update / Security / Optimization / Bug / New Capability]
**Source**: [URL or reference]
**Severity**: [Critical / Warning / Info]
**Finding**: [Concise description]
**Impact on us**: [Specific to our setup]
**Recommended action**: [Exact steps]
**Risk if ignored**: [Consequences]
**Risk of action**: [What could go wrong]

## Research Frequency
- **Version checks**: Each heartbeat with research phase
- **Security scans**: Weekly minimum, or when triggered by alerts
- **Community monitoring**: Each research phase
- **Ecosystem scan**: Weekly or when looking for new capabilities
