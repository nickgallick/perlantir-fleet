# Skill: OpenClaw Plugins

## Changelog
- 2026-03-19: Initial creation

## Overview
Knowledge about OpenClaw plugin system, available plugins, and integration patterns.

## Plugin Architecture
OpenClaw supports plugins through its configuration system. Plugins extend agent capabilities without modifying the core system.

## Current Plugin Ecosystem
Plugins in OpenClaw can provide:
- Additional tools for agents
- Custom channel integrations
- Middleware for message processing
- Custom authentication providers

## Plugin Configuration
Plugins are configured in the `plugins` section of openclaw.json (if supported by the schema).

**CAUTION**: Always verify that any plugin configuration key is supported by the current Zod schema before adding it. Unknown keys crash the gateway.

## MCP as Plugin Alternative
Most "plugin" functionality is better achieved through MCP servers via the mcporter bridge:
- Search capabilities → Brave Search MCP
- File operations → Filesystem MCP
- Custom tools → Custom MCP server

## Adding New Capabilities
Preferred approach:
1. Check if an MCP server exists for the capability
2. Configure it in mcporter (NOT openclaw.json)
3. Test with a simple query
4. Document in skills/openclaw-mcp/SKILL.md

## Our Agents
| Agent | Role | Model | Telegram Bot |
|-------|------|-------|-------------|
| Maks | Main/coding | anthropic/claude-sonnet-4-6 | @OpenClawVPS2BOT |
| MaksPM | PM | anthropic/claude-haiku-4-5 | @VPSPMClawBot |
| Scout | Research | anthropic/claude-opus-4-6 | @ClawScout2Bot |
| ClawExpert | Ops | anthropic/claude-sonnet-4-6 | @TheOpenClawExpertBot |

## Policy Values

### dmPolicy
- `allowlist` — Only users in allowedUsers can DM the bot
- `pairing` — Users must pair/register before interacting
- `open` — Anyone can DM the bot

### groupPolicy
- `open` — Bot responds in any group it's added to
- `disabled` — Bot does not respond in groups
- `allowlist` — Bot only responds in allowed groups
- **NEVER use `deny`** — crashes the instance

## Multi-Bot Setup
1. Add account in `channels.telegram.accounts`
2. Add agent in `agents.list`
3. Add binding in `bindings`
4. Restart: `docker restart openclaw-okny-openclaw-1`

## Safety Rules
1. Never install plugins from untrusted sources
2. Always review plugin code before installing
3. Test in isolation before production deployment
4. Monitor logs after enabling any new plugin
5. Keep plugins updated for security patches
