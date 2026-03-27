# OpenClaw Hardening Configuration Guide

## Network Hardening

### Firewall Rules (Linux/iptables)
```bash
# Block public access to OpenClaw gateway port
iptables -A INPUT -p tcp --dport 18789 -s 127.0.0.1 -j ACCEPT
iptables -A INPUT -p tcp --dport 18789 -j DROP

# If running on VPS, verify no cloud firewall allows 18789
# AWS Security Groups: Remove any 0.0.0.0/0 rule for port 18789
# GCP Firewall: Remove any allow rule for tcp:18789
# DO/Hetzner: Check their firewall panel
```

### Verify the port is blocked
```bash
# From external machine or different network:
nc -z -w3 <your-server-ip> 18789
# Should timeout (connection refused) — if it connects, port is exposed
```

## Gateway Configuration

### Secure gateway password
```bash
# If using openclaw CLI
openclaw config set gateway.password "$(openssl rand -base64 32)"

# Verify no default password
openclaw gateway status
```

### Device audit
```bash
# List all registered/trusted devices
openclaw gateway devices list

# Revoke any unrecognized device
openclaw gateway devices revoke <device-id>
```

## Container Isolation

### Docker run (minimal permissions)
```dockerfile
FROM openclaw/openclaw:latest

# Run as non-root
RUN adduser --disabled-password --gecos '' openclaw
USER openclaw

# No new privileges
SECURITY_OPT: no-new-privileges:true
```

```bash
docker run \
  --name openclaw \
  --user 1000:1000 \
  --read-only \
  --tmpfs /tmp \
  --no-new-privileges \
  --cap-drop=ALL \
  --network=bridge \
  -p 127.0.0.1:18789:18789 \  # Localhost only
  openclaw/openclaw:latest
```

### Filesystem restrictions
- Mount workspace as read-only where possible
- Use bind mounts only for specific directories the agent needs
- Never mount ~/.ssh, ~/.aws, ~/.npmrc into container

## Credential Management

### What NOT to do
```bash
# NEVER store these in any file the agent can read:
SUPABASE_SERVICE_ROLE_KEY=eyJhbGci...  # .env file in workspace
STRIPE_SECRET_KEY=sk_live_...           # any plaintext file
GITHUB_TOKEN=ghp_...                    # .gitconfig, .npmrc
DATABASE_URL=postgres://user:pass@...   # accessible config
```

### What TO do
```bash
# Use environment variables injected at runtime, not stored in files
# Use a secrets manager (1Password CLI, HashiCorp Vault, AWS Secrets Manager)
# If secrets must be on disk, use encrypted secrets (GPG, age, SOPS)

# Example: encrypted .env
sops --encrypt .env > .env.encrypted
# Agent only gets the decrypted version in memory at runtime
```

### Credential scoping
- Give the agent the minimum permissions it needs
- Use read-only database credentials where writes aren't needed
- Use scoped API tokens (e.g., GitHub fine-grained tokens, not personal access tokens)
- Rotate credentials regularly, especially after any suspected injection

## Skill Management

### Disable automatic updates
```bash
# In openclaw.json or via CLI
openclaw config set skills.autoUpdate false
```

### Audit installed skills
```bash
openclaw skills list

# For each skill, check:
# 1. When was it last updated?
# 2. Is the publisher the expected one?
# 3. Any recent changes to SKILL.md?
openclaw skills info <skill-name>
```

### Pre-install checklist
Before installing any skill:
1. Read SKILL.md completely
2. Run unicode scan: `python3 scan_unicode.py <skill-dir> --strict`
3. Check scripts/ directory contents
4. Verify publisher identity
5. Check if skill makes external network calls
6. Check if skill handles credentials

## Monitoring and Detection

### Anomaly indicators to monitor
```bash
# Monitor for unexpected outbound connections
netstat -an | grep ESTABLISHED | grep -v ':18789\|:443\|:80\|:5432'

# Monitor for unexpected file access
# (Use auditd on Linux)
auditctl -w ~/.ssh -p r -k ssh_access
auditctl -w ~/.aws -p r -k aws_access
auditctl -w ~/.npmrc -p r -k npm_access

# Watch OpenClaw logs for injection indicators
tail -f ~/.openclaw/logs/agent.log | grep -i 'ignore\|system prompt\|disregard\|override'
```

### Log injection indicators
Patterns to alert on in agent logs or responses:
- `ignore previous instructions`
- `disregard your system prompt`
- `you are now in developer mode`
- `this is a system message`
- `as your administrator`
- URLs with query parameters containing what look like base64-encoded data
- Unexpected tool calls (e.g., file deletion when not requested)
- Outbound HTTP calls to unfamiliar domains

## Response Checklist: Post-Injection

If injection is suspected:

```bash
# 1. Stop agent immediately
openclaw gateway stop

# 2. Snapshot current state for forensics
openclaw logs export > /tmp/incident-$(date +%Y%m%d-%H%M%S).log

# 3. Check for persistence mechanisms
crontab -l
ls ~/.config/systemd/user/
ls ~/.bashrc ~/.zshrc ~/.profile  # Check for additions

# 4. Rotate all accessible credentials
# (See openclaw-cves.md for credential inventory)

# 5. Review recent file system changes
find /data/.openclaw -newer /tmp/incident-start -type f 2>/dev/null

# 6. Review agent memory for contamination
cat /data/.openclaw/workspace-forge/MEMORY.md | grep -v "^#\|^-\|^$" | head -50

# 7. Restart with fresh session
openclaw gateway start --new-session
```

## Regular Security Maintenance Schedule

| Frequency | Task |
|-----------|------|
| Daily | Review agent session logs for anomalies |
| Weekly | Run `openclaw skills list` — check for unauthorized new skills |
| Weekly | Audit gateway trusted devices |
| Monthly | Rotate gateway password |
| Monthly | Rotate API tokens/credentials |
| Every update | Read release notes for new CVEs |
| On CVE alert | Update immediately, audit for exploitation |
