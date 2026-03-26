# Skill: OpenClaw MCP Integration

## Changelog
- 2026-03-19: Initial creation

## Overview
MCP (Model Context Protocol) integration knowledge for OpenClaw. Our setup uses mcporter bridge exclusively — NOT native mcpServers.

## CRITICAL RULE
**NEVER add `mcpServers` to openclaw.json** — This key is not in the Zod schema and will crash the gateway on startup. All MCP configuration goes through the mcporter bridge.

## Architecture
```
OpenClaw Gateway
  └── mcporter bridge (MCP proxy)
        ├── Brave Search MCP
        ├── Filesystem MCP
        └── Other MCP servers
```

## mcporter Bridge
mcporter acts as a bridge between OpenClaw and MCP servers. It:
- Runs as a separate process/service
- Exposes MCP tools to OpenClaw agents
- Handles MCP protocol translation
- Manages MCP server lifecycle

### mcporter Configuration
mcporter has its own configuration file, separate from openclaw.json.

```bash
# Check mcporter status
docker exec openclaw-okny-openclaw-1 ps aux | grep mcporter

# mcporter logs
docker logs openclaw-okny-openclaw-1 2>&1 | grep -i mcporter
```

## Available MCP Tools

### Brave Search
- Provides web search capability
- Used by Scout agent for research
- Requires BRAVE_API_KEY environment variable

### Filesystem
- Provides file read/write/list capabilities
- Scoped to specific directories for security

## Adding New MCP Servers
1. Configure in mcporter (NOT openclaw.json)
2. Restart the mcporter bridge
3. Verify tools appear in agent capabilities
4. Test with a simple query

## Troubleshooting MCP
```bash
# Check if MCP tools are loaded
docker logs openclaw-okny-openclaw-1 2>&1 | grep -i -E "mcp|tool|mcporter"

# Check for MCP errors
docker logs openclaw-okny-openclaw-1 2>&1 | grep -i -E "mcp.*error|tool.*error"

# Verify Brave API connectivity
docker exec openclaw-okny-openclaw-1 curl -s -o /dev/null -w "%{http_code}" "https://api.search.brave.com/res/v1/web/search?q=test" -H "X-Subscription-Token: test"
```

## stitch-mcp
Package: `@_davideast/stitch-mcp`
Purpose: Stitches multiple MCP servers together into a unified interface. Used with mcporter for combining MCP server capabilities.

## Common MCP Issues
1. **Tools not appearing** → Check mcporter is running and configured correctly
2. **Search failing** → Verify BRAVE_API_KEY is set and valid
3. **Timeout errors** → MCP server may be overloaded or network issue
4. **"mcpServers not recognized"** → Someone added mcpServers to openclaw.json. Remove it immediately and use mcporter instead
