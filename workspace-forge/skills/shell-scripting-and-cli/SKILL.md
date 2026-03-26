---
name: shell-scripting-and-cli
description: Bash scripting best practices, Node.js CLI tools, and shell script review checklist for OpenClaw deployment, Arena installer, and migration scripts.
---

# Shell Scripting & CLI

## Review Checklist

- [ ] `set -euo pipefail` at the top
- [ ] All variables double-quoted (`"$var"` not `$var`)
- [ ] Temp files cleaned up (`trap cleanup EXIT`)
- [ ] User input validated before use
- [ ] Meaningful error messages on failure
- [ ] Script is idempotent (safe to run twice)
- [ ] No hardcoded paths
- [ ] Secrets not echoed or logged

---

## Bash Fundamentals

```bash
#!/usr/bin/env bash
set -euo pipefail  # exit on error, undefined vars, pipe failures

# Logging
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2; }

# Safe temp directory
tmpdir=$(mktemp -d)
trap "rm -rf '$tmpdir'" EXIT

# Argument parsing
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)    NAME="$2"; shift 2 ;;
    --verbose) VERBOSE=1; shift ;;
    --help)    usage; exit 0 ;;
    *)         log "ERROR: Unknown option: $1"; exit 1 ;;
  esac
done

# Safe file write (atomic)
echo "$content" > "$file.tmp" && mv "$file.tmp" "$file"

# Check command exists
command -v docker &>/dev/null || { log "ERROR: docker not found"; exit 1; }
```

## Common Mistakes to Flag

```bash
# ❌ Unquoted variable — word splitting and glob expansion
rm -rf $dir/*    # if dir is empty, becomes rm -rf /*

# ✅ Always quote
rm -rf "$dir"/*

# ❌ [ ] for conditionals (POSIX, fewer features)
if [ "$a" = "$b" ]; then

# ✅ [[ ]] for bash (more features, safer)
if [[ "$a" == "$b" ]]; then

# ❌ Backticks (can't nest, hard to read)
result=`command`

# ✅ $() for command substitution
result=$(command)
```

## Node.js CLI Tools

```ts
// Use commander for arg parsing
import { Command } from 'commander'
const program = new Command()
  .name('arena')
  .option('-p, --port <number>', 'server port', '3000')
  .action((opts) => { startServer(opts.port) })
program.parse()

// Use @clack/prompts for interactive
import { intro, text, confirm, spinner } from '@clack/prompts'
intro('Arena Installer')
const name = await text({ message: 'Agent name?' })
const s = spinner()
s.start('Installing...')
await install()
s.stop('Done!')

// Handle Ctrl+C gracefully
process.on('SIGINT', () => {
  cleanup()
  process.exit(130)
})
```

## OpenClaw Docker Specifics

```bash
# Container name
CONTAINER="openclaw-okny-openclaw-1"

# Run command inside
docker exec "$CONTAINER" bash -c 'openclaw status'

# Config location inside container
# /data/.openclaw/openclaw.json

# Restart
docker compose up -d

# Ports: 18789 (gateway internal), 45133 (proxy external)
```

## Sources
- Google Shell Style Guide
- commander.js documentation
- @clack/prompts documentation

## Changelog
- 2026-03-21: Initial skill — shell scripting and CLI
