---
name: v0-source-knowledge
description: Deep knowledge from V0 SDK source, V0 docs, and V0 MCP source. The authoritative V0 reference for all SDK methods, REST endpoints, MCP tools, models, and advanced patterns. Read when crafting V0 prompts or debugging V0 API calls.
---

# V0 Source Knowledge

## Repos
- `repos/v0-sdk` — V0 Platform SDK (packages/v0-sdk/src/sdk/v0.ts)
- `repos/v0-mcp-source` — V0 MCP server implementation
- `repos/v0-docs/` — saved documentation

## SDK Namespaces & Methods (from v0-sdk source)

### chats
| Method | Params | Returns |
|---|---|---|
| create | message, system?, modelConfiguration?, chatPrivacy?, projectId?, responseMode?, designSystemId?, attachments? | ChatDetail with files, webUrl, demo |
| init | files[], initialContext? | ChatDetail (fast, no generation tokens) |
| find | limit?, offset?, projectId?, favorite? | ChatSummary[] |
| getById | chatId | ChatDetail with messages, files |
| update | chatId, name?, privacy? | ChatDetail |
| delete | chatId | void |
| favorite | chatId, favorite | ChatDetail |
| fork | chatId, versionId? | ChatDetail (new chat from existing) |
| sendMessage | chatId, message, attachments?, modelConfiguration?, responseMode? | ChatDetail with updated files |
| getMessage | chatId, messageId | MessageDetail |
| findMessages | chatId, limit?, cursor? | MessageSummary[] |
| findVersions | chatId, limit?, cursor? | VersionSummary[] |
| getVersion | chatId, versionId, includeFiles? | VersionDetail |
| updateVersion | chatId, versionId, body | VersionDetail |
| downloadVersion | chatId, versionId, format? | binary |
| deleteVersionFiles | chatId, versionId, filePaths[] | void |
| resume | chatId, versionId | ChatDetail |
| stop | chatId, messageId | void |

### projects
| Method | Params | Returns |
|---|---|---|
| find | — | ProjectSummary[] |
| create | name, description? | ProjectDetail |
| getById | projectId | ProjectDetail |
| update | projectId, name?, description? | ProjectDetail |
| delete | projectId | void |
| assign | projectId, chatId | void |
| getByChatId | chatId | ProjectDetail |
| findEnvVars | projectId | EnvVar[] |
| createEnvVars | projectId, envVars[] | EnvVar[] |
| updateEnvVars | projectId, envVars[] | EnvVar[] |
| deleteEnvVars | projectId, keys[] | void |
| getEnvVar | projectId, key | EnvVar |

### deployments
| Method | Params | Returns |
|---|---|---|
| find | chatId?, limit?, offset? | DeploymentSummary[] |
| create | chatId, versionId, projectId? | DeploymentDetail with url |
| getById | deploymentId | DeploymentDetail |
| delete | deploymentId | void |
| findLogs | deploymentId, limit? | LogEntry[] |
| findErrors | deploymentId, limit? | ErrorEntry[] |

### hooks (webhooks)
| Method | Params | Returns |
|---|---|---|
| find | — | HookSummary[] |
| create | url, events[], secret? | HookDetail |
| getById | hookId | HookDetail |
| update | hookId, url?, events?, active? | HookDetail |
| delete | hookId | void |

### integrations
| Method | Params | Returns |
|---|---|---|
| vercel.projects.find | — | VercelProjectSummary[] |
| vercel.projects.create | name, framework? | VercelProjectDetail |

### mcpServers
| Method | Params | Returns |
|---|---|---|
| find | — | McpServer[] |
| create | name, url, headers? | McpServer |
| getById | serverId | McpServer |
| update | serverId, name?, url?, headers? | McpServer |
| delete | serverId | void |

### rateLimits
| Method | Params | Returns |
|---|---|---|
| find | scope? | RateLimit with limit, remaining, resetAt |

### user
| Method | Params | Returns |
|---|---|---|
| get | — | UserDetail |
| getBilling | startDate?, endDate? | BillingDetail |
| getPlan | — | PlanDetail |
| getScopes | — | ScopeDetail[] |
| getUsage | startDate?, endDate? | UsageDetail |
| getUserActivity | startDate?, endDate? | ActivityDetail |

## MCP Tools (via official mcp-remote → mcp.v0.dev)

| Tool | Params | Returns |
|---|---|---|
| createChat | message (required), modelConfiguration?, system?, chatPrivacy?, projectId?, responseMode?, designSystemId?, attachments? | Full chat with files[], demo URL |
| findChats | — | All chats with id, name, webUrl |
| getChat | chatId | Chat detail with files |
| sendChatMessage | chatId, message, attachments?, modelConfiguration? | Updated chat with new files |
| getUser | scope? | User info |

## V0 Models
| Model | Quality | Speed | Use When |
|---|---|---|---|
| v0-1.5-lg | Highest | Slowest | Complex multi-component designs, production screens |
| v0-1.5-md | Balanced | Medium | Most design work, iteration |
| v0-1.5-sm | Lower | Fastest | Quick prototypes, simple components |
| v0-gpt-5 | Premium | Varies | When specified by user |

Default via MCP: v0-pro (maps to best available).

## ChatDetail Response Shape
```typescript
{
  id: string
  webUrl: string           // V0 editor URL
  latestVersion: {
    id: string
    demoUrl?: string       // Live preview URL
    screenshotUrl?: string
    files: { name: string, content: string, locked: boolean }[]
  }
  demo?: string            // Shortcut to latest demo URL
  files?: { lang: string, meta: { file: string }, source: string }[]
  text: string             // V0's description of what it built
  modelConfiguration: { modelId: string, imageGenerations: boolean, thinking: boolean }
}
```

## Advanced Patterns

### chats.init (fast context loading)
Load existing files into a V0 chat without generating tokens. Then sendMessage to modify:
```
v0.chats.init({ files: [{ path: "app/page.tsx", content: "..." }] })
→ returns chatId
v0.chats.sendMessage({ chatId, message: "Add dark mode" })
```

### Vision input
Attach screenshots/images as design references:
```
v0.chats.create({
  message: "Recreate this design exactly",
  attachments: [{ url: "https://example.com/screenshot.png" }]
})
```

### System prompts for brand enforcement
```
v0.chats.create({
  message: "Create a dashboard",
  system: "Use ONLY these colors: background #0A1628, surface #111D30, accent #00D4FF. Font: Space Grotesk headings, DM Sans body. All components must use Shadcn UI. Use Lucide icons only."
})
```

### Iterating on same chatId
Send follow-up messages to refine without starting over:
```
v0.chats.sendMessage({ chatId: "abc", message: "Change the primary color to #39FF14 and make buttons pill-shaped" })
```

### Fork for variants
Create a branch from an existing design:
```
v0.chats.fork({ chatId: "abc", versionId: "v1" })
```

## V0 Prompt Engineering Tips
1. **Always specify the tech stack**: "React, Next.js App Router, TypeScript, Tailwind CSS, Shadcn UI, Lucide icons"
2. **Use system prompt for brand tokens** — keeps the main prompt focused on layout
3. **Reference Shadcn components by name**: "Use Card, Badge, Avatar, Button from shadcn/ui"
4. **Reference Magic UI by name**: "Use NumberTicker from Magic UI for the stat counters"
5. **Include realistic content** — real names, real numbers, not lorem ipsum
6. **Specify responsive behavior**: "Stack to single column below 640px"
7. **Ask for TypeScript** — V0 generates typed components
8. **For mobile designs**: "Render at 390px width as a mobile-first layout"
9. **For animations**: "Use Framer Motion for page transitions" or "Use Magic UI AnimatedList"
10. **For dark themes**: Specify every color explicitly — don't say "dark theme", say exact hex values

## Changelog
- 2026-03-20: Initial extraction from v0-sdk source + MCP server analysis
