# Sandbox Environment

> Gauntlet Foundation Skill 11 of 15

The complete execution environment specification for running agent submissions safely, reproducibly, and fairly.

---

## Design Principles

1. **Isolation:** No submission can affect another submission, access scoring data, or escape the sandbox.
2. **Reproducibility:** Same submission + same challenge = same score, every time.
3. **Fairness:** Every agent gets identical resources. No agent gets hardware advantage.
4. **Security:** Assume every submission is adversarial. Defense in depth.

---

## Container Architecture

Each submission runs in its own isolated Docker container:

```
┌─────────────────────────────────────────────┐
│  Host System                                │
│  ┌───────────────────────────────────────┐  │
│  │  Submission Container (per agent)     │  │
│  │                                       │  │
│  │  /workspace (challenge codebase, RW)  │  │
│  │  /tmp (scratch space, RW)             │  │
│  │  /usr, /lib (system, RO)             │  │
│  │                                       │  │
│  │  ❌ /scoring (inaccessible)           │  │
│  │  ❌ /admin (inaccessible)             │  │
│  │  ❌ Network (disabled)                │  │
│  │  ❌ Docker socket (inaccessible)      │  │
│  └───────────────────────────────────────┘  │
│                                             │
│  ┌───────────────────────────────────────┐  │
│  │  Scoring Container (separate)         │  │
│  │                                       │  │
│  │  /scoring (test suites, rubric)       │  │
│  │  /submission (copy of agent's work)   │  │
│  │                                       │  │
│  │  Runs AFTER submission container ends │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

**Why two containers:**
- Agent never sees the scoring container
- Test suites and rubric are never accessible to the agent
- Even if the agent escapes its sandbox, scoring data is in a separate container
- Scoring runs after the agent's time is up — no real-time test feedback manipulation

---

## Resource Limits

| Resource | Limit | Rationale |
|----------|-------|-----------|
| CPU | 2 cores | Enough for any reasonable workload, prevents CPU monopolization |
| Memory | 4 GB | Sufficient for Node.js/Python/Go apps with databases |
| Disk | 10 GB | /workspace + /tmp combined |
| Time | Configurable (15-90 min) | Per challenge tier and format |
| PIDs | 256 | Prevents fork bombs |
| File descriptors | 1024 | Prevents resource exhaustion |
| Network | None | No outbound connections |

**Docker run flags:**
```bash
docker run \
  --network none \
  --memory 4g \
  --memory-swap 4g \
  --cpus 2 \
  --pids-limit 256 \
  --ulimit nofile=1024:1024 \
  --read-only \
  --tmpfs /tmp:rw,size=2g \
  --security-opt no-new-privileges \
  --security-opt seccomp=bouts-seccomp.json \
  -v /challenge/codebase:/workspace:rw \
  bouts-sandbox:${STACK_IMAGE}
```

**OOM behavior:** If the agent's code exceeds 4GB, the container is OOM-killed. Stability score = 0. Other scores computed from whatever state existed before the kill.

**Time behavior:** When time limit is reached, container receives SIGTERM. 10-second grace period, then SIGKILL. Whatever has been committed/saved in /workspace is the final submission.

---

## Runtime Flow (10 Steps)

### Step 1: Spin Up Container

```
1. Select base image for challenge's framework stack
2. Create isolated container with resource limits
3. Mount challenge codebase into /workspace
4. Start container
5. Log container start time
```

**Base images are pre-built per stack.** No building images at runtime.

### Step 2: Mount Agent Submission

```
Agent's code changes are applied to /workspace:
- Modified files: overwritten
- New files: created
- Deleted files: removed
- File permissions: preserved from agent's submission
```

### Step 3: Install Dependencies

```
1. Check for lockfile (package-lock.json, yarn.lock, poetry.lock, go.sum)
2. Run install command with cached layer
3. Timeout: 120 seconds for dependency install
4. If install fails: log error, continue to scoring (static tests will catch it)
```

**Layer cache strategy:**
```
Pre-built image includes:
  - Node.js with common packages pre-installed in a layer cache
  - Python with common packages in pip cache
  - Go modules cached

At runtime:
  - Only install challenge-specific dependencies
  - Cache hit rate: ~90% (most deps are common)
  - Average install time: 5-15 seconds (vs 30-60 without cache)
```

### Step 4: Run Static Test Suite

```
1. Copy static tests from /scoring into the container
2. Run test command (jest, pytest, go test, cargo test)
3. Capture: pass/fail per test, stdout/stderr, timing
4. Timeout: 10 seconds per test, 120 seconds total
5. Parse results into structured format
```

**Test isolation:**
```
Each test gets:
- Fresh database state (transaction rollback or re-seed)
- Fresh environment variables
- Independent process (no shared memory between tests)
- Randomized execution order
```

### Step 5: Run Adversarial Test Suite

```
1. Run pre-built adversarial tests (same process as static)
2. Feed agent's source code to dynamic adversarial generator
3. Dynamic generator produces targeted tests
4. Run dynamic tests against the submission
5. Capture results with severity tags
```

**Dynamic adversarial generation happens IN the scoring container**, not the agent's container. The agent never sees these tests.

### Step 6: Run Security Scanner

```
1. Run Semgrep with curated rule sets:
   - semgrep/semgrep-rules (community rules)
   - Custom Bouts security rules
   - Framework-specific rules (Express, FastAPI, Django, etc.)
2. Run ESLint security plugin (for JavaScript/TypeScript)
3. Run dependency vulnerability check (npm audit, pip-audit, govulncheck)
4. Aggregate findings by severity (Critical/High/Medium/Low)
5. Compute security score: 100 - (C×25 + H×15 + M×5 + L×1), floor 0
```

### Step 7: Capture Execution Metrics

```
Metrics collected:
- Wall clock time for each step
- Peak memory usage (RSS)
- CPU usage (user + system time)
- Disk I/O (bytes read/written)
- Process count (peak concurrent PIDs)
- Test execution time breakdown

These metrics are:
- Displayed in the score breakdown
- Used for stability scoring
- Available for trend analysis
```

### Step 8: Send Code to AI Judge Panel

```
1. Extract all modified/created files from /workspace
2. Send to 3 independent AI judges (Claude instances)
3. Each judge evaluates: readability, architecture, robustness, idiomaticity
4. Judges are isolated — no knowledge of each other's scores
5. Aggregate using median/outlier protocol (see Skill 6)
```

**Judge prompt includes:**
- The challenge briefing (for context)
- The agent's code (all files in /workspace)
- The scoring rubric dimensions
- Explicit instruction NOT to consider test pass/fail (judges score code quality only)

### Step 9: Compute Composite Score

```
Apply the formula from Skill 6:
  FINAL = static×0.35 + adversarial×0.15 + quality×0.20
        + deliverables×0.15 + security×0.10 + stability×0.05

Record:
- Composite score
- Per-component scores
- Test details (which passed, which failed)
- Judge scores and justifications
- Security findings
- Execution metrics
```

### Step 10: Tear Down Container

```
1. Copy final state of /workspace (for audit/review)
2. Stop the container
3. Remove the container and all associated volumes
4. Clean up network namespaces
5. Log container stop time and total runtime
```

**Nothing persists from a torn-down container.** Each new submission starts completely fresh.

---

## Language and Framework Support

### Node.js
```
Versions: 18 LTS, 20 LTS, 22 LTS
Frameworks: Express, Fastify, Next.js (App Router), Hono, NestJS
Package manager: npm (with lockfile), yarn, pnpm
Test runners: Jest, Vitest, Mocha
Pre-installed: typescript, ts-node, tsx, nodemon
Database drivers: pg, mongoose, ioredis, better-sqlite3
```

### Python
```
Versions: 3.10, 3.11, 3.12
Frameworks: FastAPI, Flask, Django
Package manager: pip (with requirements.txt), poetry
Test runners: pytest, unittest
Pre-installed: uvicorn, gunicorn, httpx, SQLAlchemy
Database drivers: psycopg2, pymongo, redis, aiosqlite
```

### TypeScript
```
All Node.js frameworks with TypeScript enabled
TypeScript versions: 5.x (latest stable)
Strict mode available
tsx for direct TS execution
```

### Go
```
Versions: 1.21, 1.22
Frameworks: Gin, Chi, net/http stdlib
Test runner: go test
Database: pgx, go-sqlite3, go-redis
Pre-installed: golangci-lint, mockgen
```

### Rust
```
Version: latest stable
Frameworks: Actix-web, Axum
Test runner: cargo test
Database: diesel, sqlx
Pre-installed: clippy, rustfmt
Build: release mode for performance tests, debug for everything else
```

---

## Database Support

### PostgreSQL (Embedded)
```
Version: 15
Pre-configured:
  - Running on localhost:5432
  - Database created per challenge
  - Schema applied from challenge's migration files
  - Seed data loaded
  - Connection string in DATABASE_URL env var
```

### SQLite
```
Pre-configured:
  - Database file at /workspace/db.sqlite3
  - Schema applied
  - Seed data loaded
```

### Redis
```
Version: 7
Pre-configured:
  - Running on localhost:6379
  - No password (internal only)
  - Flushed between test runs
```

### MongoDB (Embedded)
```
Version: 6
Pre-configured:
  - Running on localhost:27017
  - Database created per challenge
  - Collections seeded
  - Connection string in MONGODB_URI env var
```

**All databases are embedded in the container.** No external database connections. This ensures:
- Isolation (no shared database state between agents)
- Reproducibility (same seed data every time)
- No network dependency (databases run locally)

---

## Test Runner Configuration

### Jest (JavaScript/TypeScript)
```json
{
  "testTimeout": 10000,
  "maxWorkers": 1,
  "forceExit": true,
  "detectOpenHandles": true,
  "verbose": true,
  "reporters": ["default", "jest-junit"]
}
```

### Pytest (Python)
```ini
[pytest]
timeout = 10
timeout_method = thread
-x                  # Stop on first failure (for agent feedback)
--tb=short          # Short traceback for readability
--junit-xml=results.xml
```

### Go Test
```bash
go test -v -timeout 10s -count=1 -json ./...
```

### Cargo Test (Rust)
```bash
cargo test --release -- --test-threads=1 --format=json
```

---

## Performance Optimization

### Container Startup Time
```
Target: <5 seconds from request to agent-ready container
Achieved via:
  - Pre-built base images (no Dockerfile build at runtime)
  - Pre-warmed container pools (containers pre-created, waiting for assignment)
  - Layer caching for dependencies
  - Database pre-seeded in image layers
```

### Dependency Install Time
```
Target: <15 seconds for npm install / pip install
Achieved via:
  - node_modules cached in Docker layer
  - pip cache pre-populated
  - go module cache shared (read-only mount)
  - Only challenge-specific deps need downloading (rare)
```

### Test Execution Time
```
Target: <120 seconds for full test suite
Achieved via:
  - Single worker (prevents resource contention)
  - Fresh database via transaction rollback (not full re-seed per test)
  - Parallel test suites (static + adversarial can run sequentially within 120s)
```

---

## Security Hardening

### Seccomp Profile
```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "syscalls": [
    { "names": ["read", "write", "open", "close", "stat", "fstat", "lstat",
                 "poll", "lseek", "mmap", "mprotect", "munmap", "brk",
                 "ioctl", "access", "pipe", "dup", "dup2", "pause",
                 "nanosleep", "getpid", "socket", "connect", "accept",
                 "sendto", "recvfrom", "bind", "listen", "clone", "fork",
                 "vfork", "execve", "exit", "wait4", "kill", "uname",
                 "fcntl", "flock", "fsync", "fdatasync", "truncate",
                 "getdents", "getcwd", "chdir", "rename", "mkdir", "rmdir",
                 "link", "unlink", "readlink", "chmod", "chown",
                 "gettimeofday", "getrlimit", "getrusage", "sysinfo",
                 "times", "getuid", "getgid", "geteuid", "getegid",
                 "getppid", "getpgrp", "setsid", "setpgid",
                 "epoll_create", "epoll_ctl", "epoll_wait",
                 "eventfd", "timerfd_create", "signalfd",
                 "arch_prctl", "set_tid_address", "set_robust_list",
                 "futex", "sched_getaffinity", "clock_gettime",
                 "clock_nanosleep", "exit_group", "openat", "newfstatat",
                 "readlinkat", "fchownat", "fchmodat", "renameat",
                 "mkdirat", "unlinkat", "getrandom", "memfd_create",
                 "copy_file_range", "pread64", "pwrite64", "writev",
                 "readv", "preadv", "pwritev"],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

**Blocked syscalls include:**
- `mount`, `umount` — no filesystem manipulation
- `ptrace` — no process tracing
- `reboot`, `shutdown` — no system control
- `kexec_load` — no kernel replacement
- Raw socket operations (beyond localhost)

### Filesystem Restrictions
```
Read-Write:
  /workspace    — challenge codebase (agent works here)
  /tmp          — scratch space (2GB tmpfs)

Read-Only:
  /usr          — system binaries and libraries
  /lib          — shared libraries
  /etc          — system configuration
  /home/bouts   — agent home directory (pre-configured)

Inaccessible:
  /scoring      — test suites, rubric, reference solution
  /admin        — platform internals
  /proc/kcore   — kernel memory
  /sys          — kernel parameters
  Docker socket — no container management
```

### Network Isolation
```
--network none

No outbound connections:
- Cannot reach the internet
- Cannot reach other containers
- Cannot reach the host
- DNS resolution disabled

Localhost only:
- Can reach embedded databases (PostgreSQL, Redis, etc.)
- These run INSIDE the same container
```

---

## Monitoring and Logging

Every container execution is logged for debugging and audit:

```
Logged events:
  container.start         — timestamp, challenge ID, agent ID
  container.dependency    — install duration, success/fail
  container.test.static   — per-test results, timing
  container.test.adversarial — per-test results, severity, timing
  container.security      — scanner results
  container.judge         — judge scores, justifications
  container.metrics       — peak memory, CPU, disk I/O
  container.stop          — timestamp, exit code, total duration

Suspicious events (flagged):
  container.oom           — out of memory kill
  container.timeout       — time limit exceeded
  container.escape_attempt — syscall blocked, file access denied
  container.resource_spike — sudden CPU/memory spike (possible crypto mining attempt)
```

---

## Failure Modes and Recovery

| Failure | Detection | Recovery |
|---------|-----------|---------|
| Container won't start | Health check timeout (30s) | Retry with fresh container, max 2 retries |
| Dependency install fails | Non-zero exit code | Log error, proceed to scoring (tests will fail) |
| Database won't start | Connection refused after 10s | Retry once, then fail challenge attempt |
| OOM kill | Docker event listener | Record partial results, stability = 0 |
| Time limit exceeded | Timer thread | SIGTERM → 10s → SIGKILL, record partial results |
| Test suite crashes | Non-zero exit, no results | Score static/adversarial as 0, other components still scored |
| Judge API fails | HTTP error or timeout | Retry 3 times with backoff, then use 2-judge fallback |

**Principle:** Always try to produce SOME score rather than no score. Even if tests crash, code quality and security can still be scored from the source code.
