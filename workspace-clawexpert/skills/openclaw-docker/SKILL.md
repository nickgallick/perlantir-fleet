# Skill: OpenClaw Docker Operations

## Changelog
- 2026-03-19: Initial creation

## Overview
Docker deployment knowledge for OpenClaw on Hostinger VPS.

## Current Setup
- **Host**: Hostinger VPS at 72.61.127.59
- **Container**: openclaw-okny-openclaw-1
- **Image**: ghcr.io/hostinger/hvps-openclaw:latest
- **Platform**: Linux (Docker)

## Container Lifecycle

### Starting
```bash
docker start openclaw-okny-openclaw-1
```

### Stopping
```bash
docker stop openclaw-okny-openclaw-1
```

### Restarting
```bash
docker restart openclaw-okny-openclaw-1
```

### Checking Status
```bash
docker ps --filter name=openclaw --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"
```

### Viewing Logs
```bash
# Recent logs
docker logs --tail 100 openclaw-okny-openclaw-1

# Follow live
docker logs -f openclaw-okny-openclaw-1

# Time-bounded
docker logs --since 1h openclaw-okny-openclaw-1
docker logs --since "2026-03-19T00:00:00" openclaw-okny-openclaw-1
```

## Resource Monitoring
```bash
# Real-time stats
docker stats openclaw-okny-openclaw-1

# Snapshot stats
docker stats --no-stream openclaw-okny-openclaw-1

# Detailed inspection
docker inspect openclaw-okny-openclaw-1
```

## Volume Mounts
The container mounts `/data/.openclaw` from the host. This contains:
- `openclaw.json` — Main configuration
- `workspace/` — Main agent workspace
- `workspace-clawexpert/` — ClawExpert workspace
- Other agent workspaces

**Important**: Changes to files in `/data/.openclaw/` on the host are immediately visible inside the container.

## Update Procedure (Safe)
```bash
# Step 1: Backup
cp /data/.openclaw/openclaw.json /data/.openclaw/openclaw.json.backup.$(date +%Y%m%d%H%M%S)

# Step 2: Note current container config
docker inspect openclaw-okny-openclaw-1 > /tmp/openclaw-container-inspect.json

# Step 3: Pull new image
docker pull ghcr.io/hostinger/hvps-openclaw:latest

# Step 4: Check if docker-compose is used
ls /data/.openclaw/docker-compose.yml 2>/dev/null || ls /data/docker-compose.yml 2>/dev/null

# Step 5a: If docker-compose exists:
# cd <compose-directory> && docker-compose up -d

# Step 5b: If no docker-compose, recreate manually:
# Review inspect output for ports, volumes, env vars first!

# Step 6: Verify
docker logs --tail 30 openclaw-okny-openclaw-1
docker ps --filter name=openclaw
```

## Rollback Procedure
```bash
# If update fails, restore config backup
cp /data/.openclaw/openclaw.json.backup.<timestamp> /data/.openclaw/openclaw.json
docker restart openclaw-okny-openclaw-1
docker logs --tail 30 openclaw-okny-openclaw-1
```

## Ports
- **45133** — Proxy port
- **18789** — Gateway/loopback port

## Golden Config
Hostinger may restore golden config on restart. Use CLI for changes or edit+restart quickly. If your config changes disappear after a restart, Hostinger's golden config restore is the likely cause.

## Startup Sequence
1. Permissions
2. Proxy:45133
3. Home init
4. Plugins
5. Telegram
6. Gateway:18789
7. Heartbeat
8. Health
9. Bots connect

## Networking
```bash
# Check container network
docker network ls
docker inspect openclaw-okny-openclaw-1 --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'

# Test outbound connectivity
docker exec openclaw-okny-openclaw-1 curl -s -o /dev/null -w "%{http_code}" https://api.anthropic.com
docker exec openclaw-okny-openclaw-1 curl -s -o /dev/null -w "%{http_code}" https://api.telegram.org
```

## Common Docker Issues
1. **Container won't start** → Check logs: `docker logs openclaw-okny-openclaw-1`
2. **Container keeps restarting** → Check restart policy and error logs
3. **Out of memory** → Check `docker stats`, may need to increase container memory limit
4. **Disk full** → Check `df -h /data`, clean old logs and backups
5. **Image pull fails** → Check network, Docker Hub rate limits, or registry auth
