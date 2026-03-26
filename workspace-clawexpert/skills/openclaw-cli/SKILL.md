# Skill: OpenClaw CLI

## Changelog
- 2026-03-19: Initial creation

## Overview
Command-line interface reference for OpenClaw operations.

## Container Management
```bash
# View container status
docker ps --filter name=openclaw

# Restart container
docker restart openclaw-okny-openclaw-1

# Stop container
docker stop openclaw-okny-openclaw-1

# Start container
docker start openclaw-okny-openclaw-1

# View logs (last 50 lines)
docker logs --tail 50 openclaw-okny-openclaw-1

# Follow logs in real-time
docker logs -f openclaw-okny-openclaw-1

# View logs since timestamp
docker logs --since 2h openclaw-okny-openclaw-1

# Execute command inside container
docker exec openclaw-okny-openclaw-1 <command>

# Interactive shell inside container
docker exec -it openclaw-okny-openclaw-1 /bin/sh
```

## Image Management
```bash
# Pull latest image
docker pull ghcr.io/hostinger/hvps-openclaw:latest

# Check current image
docker inspect openclaw-okny-openclaw-1 --format '{{.Config.Image}}'

# Check image digest
docker inspect openclaw-okny-openclaw-1 --format '{{.Image}}'
```

## Update Procedure
```bash
# 1. Backup config
cp /data/.openclaw/openclaw.json /data/.openclaw/openclaw.json.backup.$(date +%Y%m%d%H%M%S)

# 2. Pull new image
docker pull ghcr.io/hostinger/hvps-openclaw:latest

# 3. Stop current container
docker stop openclaw-okny-openclaw-1

# 4. Remove old container
docker rm openclaw-okny-openclaw-1

# 5. Start with new image (use original docker run or docker-compose)
# Check docker-compose.yml or original run command first!

# 6. Verify startup
docker logs --tail 30 openclaw-okny-openclaw-1
```

## Doctor Command
```bash
# Run diagnostics and report issues
openclaw doctor

# Auto-fix common issues
openclaw doctor --fix

# Verbose output for debugging
openclaw doctor --verbose

# Combined
openclaw doctor --fix --verbose
```

## Diagnostics
```bash
# Container resource usage
docker stats --no-stream openclaw-okny-openclaw-1

# Container processes
docker exec openclaw-okny-openclaw-1 ps aux

# Container environment variables
docker exec openclaw-okny-openclaw-1 env

# Container filesystem usage
docker exec openclaw-okny-openclaw-1 du -sh /app

# Network connectivity test
docker exec openclaw-okny-openclaw-1 curl -s -o /dev/null -w "%{http_code}" https://api.anthropic.com

# Check Node.js version
docker exec openclaw-okny-openclaw-1 node --version

# Check npm packages
docker exec openclaw-okny-openclaw-1 npm list --depth=0 2>/dev/null
```

## Log Filtering
```bash
# Errors only
docker logs openclaw-okny-openclaw-1 2>&1 | grep -i error

# Warnings (excluding known harmless)
docker logs openclaw-okny-openclaw-1 2>&1 | grep -i warn | grep -v -E "nostr|apply_patch|autoSelectFamily"

# Telegram activity
docker logs openclaw-okny-openclaw-1 2>&1 | grep -i telegram

# API calls
docker logs openclaw-okny-openclaw-1 2>&1 | grep -i -E "anthropic|api"

# Agent activity
docker logs openclaw-okny-openclaw-1 2>&1 | grep -i -E "agent|maks|scout|clawexpert"
```

## Backup Commands
```bash
# Full config backup
cp /data/.openclaw/openclaw.json /data/.openclaw/openclaw.json.backup.$(date +%Y%m%d%H%M%S)

# Full workspace backup
tar czf /data/.openclaw/backup-workspace-$(date +%Y%m%d).tar.gz /data/.openclaw/workspace*

# Backup specific agent workspace
tar czf /data/.openclaw/backup-clawexpert-$(date +%Y%m%d).tar.gz /data/.openclaw/workspace-clawexpert
```
