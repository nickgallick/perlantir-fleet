# Maks Development Standards

> **Owner:** Forge (Technical Architect)
> **Effective:** 2026-03-21
> **Status:** ACTIVE — Maks MUST follow these standards on every build.
> **Enforcement:** Forge reviews against this document. Violations block deploy.

---

## Table of Contents

1. [Project Structure](#1-project-structure)
2. [TypeScript Standards](#2-typescript-standards)
3. [Supabase Patterns](#3-supabase-patterns)
4. [API & Server Action Patterns](#4-api--server-action-patterns)
5. [Security Requirements (Non-Negotiable)](#5-security-requirements-non-negotiable)
6. [Error Handling](#6-error-handling)
7. [Performance Standards](#7-performance-standards)
8. [Testing Requirements](#8-testing-requirements)
9. [Git Standards](#9-git-standards)
10. [What Gets You BLOCKED](#10-what-gets-you-blocked)

---

## 1. Project Structure

### Feature-Based Organization (Bulletproof-React Pattern)

Every project uses feature-based organization. No dumping files into flat `components/` or `utils/` directories.

```
src/
├── app/                          # Next.js App Router routes
│   ├── (auth)/
│   │   ├── login/page.tsx
│   │   └── signup/page.tsx
│   ├── (dashboard)/
│   │   ├── projects/page.tsx
│   │   └── settings/page.tsx
│   ├── api/
│   │   ├── projects/route.ts
│   │   └── webhooks/stripe/route.ts
│   ├── layout.tsx
│   ├── page.tsx
│   └── error.tsx
├── features/
│   ├── auth/
│   │   ├── api/                  # Server-side logic, data fetching, mutations
│   │   │   ├── get-user.ts
│   │   │   ├── login.ts
│   │   │   └── signup.ts
│   │   ├── components/           # UI components scoped to this feature
│   │   │   ├── login-form.tsx
│   │   │   └── auth-provider.tsx
│   │   ├── hooks/                # React hooks scoped to this feature
│   │   │   └── use-auth.ts
│   │   ├── types/                # Types scoped to this feature
│   │   │   └── auth.ts
│   │   └── utils/                # Utility functions scoped to this feature
│   │       └── validate-password.ts
│   ├── projects/
│   │   ├── api/
│   │   │   ├── create-project.ts
│   │   │   ├── get-projects.ts
│   │   │   └── update-project.ts
│   │   ├── components/
│   │   │   ├── project-card.tsx
│   │   │   ├── project-list.tsx
│   │   │   └── create-project-dialog.tsx
│   │   ├── hooks/
│   │   │   └── use-projects.ts
│   │   ├── types/
│   │   │   └── project.ts
│   │   └── utils/
│   │       └── format-project-status.ts
│   └── billing/
│       ├── api/
│       ├── components/
│       ├── hooks/
│       ├── types/
│       └── utils/
├── lib/                          # Shared utilities (non-feature-specific)
│   ├── supabase/
│   │   ├── client.ts             # Browser Supabase client
│   │   ├── server.ts             # Server Supabase client
│   │   └── middleware.ts         # Supabase auth middleware
│   ├── errors.ts                 # Custom error classes
│   ├── logger.ts                 # Structured logger
│   ├── rate-limit.ts             # Rate limiting utilities
│   └── utils.ts                  # Generic helpers (cn, formatDate, etc.)
├── types/                        # Shared types (cross-feature)
│   ├── database.ts               # Generated Supabase types
│   ├── api.ts                    # Shared API response types
│   └── branded.ts                # Branded ID types
├── components/                   # Shared UI components (design system level)
│   ├── ui/                       # shadcn/ui primitives
│   │   ├── button.tsx
│   │   └── dialog.tsx
│   └── layouts/
│       ├── dashboard-layout.tsx
│       └── auth-layout.tsx
└── middleware.ts                  # Next.js middleware (auth redirect, etc.)
```

### File Naming Rules

| Thing | Convention | Example |
|---|---|---|
| Files (all) | kebab-case | `create-project.ts` |
| React components | PascalCase export, kebab-case file | `project-card.tsx` → `export function ProjectCard()` |
| Hooks | camelCase with `use` prefix | `use-projects.ts` → `export function useProjects()` |
| Types/Interfaces | PascalCase | `type ProjectStatus = 'active' \| 'archived'` |
| Constants | SCREAMING_SNAKE_CASE | `const MAX_PROJECTS_PER_USER = 50` |
| Zod schemas | PascalCase with `Schema` suffix | `const CreateProjectSchema = z.object({...})` |

### Import Ordering

Imports are grouped in this exact order, separated by blank lines:

```typescript
// 1. Node built-ins
import { readFile } from 'node:fs/promises'
import path from 'node:path'

// 2. External packages
import { NextResponse } from 'next/server'
import { z } from 'zod'
import { createClient } from '@supabase/supabase-js'

// 3. Internal aliases (path aliases from tsconfig)
import { AppError } from '@/lib/errors'
import { logger } from '@/lib/logger'
import { createServerClient } from '@/lib/supabase/server'

// 4. Relative imports (parent first, then siblings, then children)
import { ProjectCard } from '../components/project-card'
import { useProjects } from './use-projects'
import type { Project } from '../types/project'
```

### Critical Rules

- **Business logic lives in `features/*/api/`** — never in components. Components render. API modules think.
- **Shared utilities go in `src/lib/`** — if two features need it, it's not feature-scoped anymore.
- **Types are collocated with features** unless genuinely shared across 3+ features, then `src/types/`.
- **No barrel exports** (`index.ts` re-exporting everything). They break tree-shaking and make circular deps invisible.
- **One component per file.** No multi-component files except for small, tightly-coupled internal components.

---

## 2. TypeScript Standards

### tsconfig Requirements

Every project MUST have these compiler options enabled:

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true,
    "exactOptionalPropertyTypes": false,
    "moduleResolution": "bundler",
    "target": "ES2022",
    "lib": ["DOM", "DOM.Iterable", "ES2022"],
    "jsx": "preserve",
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

`strict: true` enables: `strictNullChecks`, `strictFunctionTypes`, `strictBindCallApply`, `strictPropertyInitialization`, `noImplicitAny`, `noImplicitThis`, `alwaysStrict`.

### No `any` — Period

Every use of `any` requires a written justification comment on the line above or inline:

```typescript
// ❌ BLOCKED — no justification
function processData(data: any) { ... }

// ✅ Acceptable — justified
// REASON: Third-party library @legacy/charts has no type definitions and DefinitelyTyped has none
function initChart(config: any) { ... }

// ✅ Better — use unknown and narrow
function processWebhookPayload(payload: unknown) {
  const parsed = WebhookPayloadSchema.safeParse(payload)
  if (!parsed.success) throw new ValidationError('Invalid webhook payload')
  // Now parsed.data is fully typed
}
```

### No `as` Assertions Without Justification

Type assertions bypass the compiler. Every use needs a reason:

```typescript
// ❌ BLOCKED
const user = data as User

// ✅ Acceptable — justified
// REASON: Supabase .single() returns data typed as array, but we know it's one row
const user = data as User

// ✅ Better — use Zod runtime validation instead of assertion
const user = UserSchema.parse(data)
```

### Branded Types for All IDs

Never pass raw strings where an ID is expected. Use branded types:

```typescript
// src/types/branded.ts

export type UserId = string & { readonly __brand: 'UserId' }
export type AgentId = string & { readonly __brand: 'AgentId' }
export type ProjectId = string & { readonly __brand: 'ProjectId' }
export type OrganizationId = string & { readonly __brand: 'OrganizationId' }
export type InvoiceId = string & { readonly __brand: 'InvoiceId' }

// Factory functions — the ONLY way to create branded IDs
export function userId(id: string): UserId {
  return id as UserId
}

export function agentId(id: string): AgentId {
  return id as AgentId // REASON: branded type factory — sole approved cast point
}

export function projectId(id: string): ProjectId {
  return id as ProjectId // REASON: branded type factory — sole approved cast point
}

// Usage:
function getProject(id: ProjectId): Promise<Project> { ... }

// ❌ Compile error — string is not ProjectId
getProject('some-uuid')

// ✅ Correct — explicit branding at trust boundary
getProject(projectId(parsed.data.projectId))
```

### Zod Validation at Every Trust Boundary

Trust boundaries are where external data enters your system:

```typescript
import { z } from 'zod'

// Schema definition
export const CreateProjectSchema = z.object({
  name: z.string().min(1).max(100),
  description: z.string().max(500).optional(),
  teamId: z.string().uuid(),
  visibility: z.enum(['private', 'team', 'public']),
})

// Type inferred from schema — NEVER duplicate manually
export type CreateProjectInput = z.infer<typeof CreateProjectSchema>

// ❌ BLOCKED — duplicate type definition
// type CreateProjectInput = { name: string; description?: string; teamId: string; visibility: 'private' | 'team' | 'public' }

// Usage at API route (trust boundary)
export async function POST(req: Request) {
  const body = await req.json()
  const parsed = CreateProjectSchema.safeParse(body)
  if (!parsed.success) {
    return NextResponse.json(
      { error: { code: 'VALIDATION_ERROR', message: parsed.error.message } },
      { status: 400 }
    )
  }
  // parsed.data is fully typed as CreateProjectInput
}

// Usage at Server Action (trust boundary)
export async function createProject(formData: FormData) {
  const parsed = CreateProjectSchema.safeParse({
    name: formData.get('name'),
    description: formData.get('description'),
    teamId: formData.get('teamId'),
    visibility: formData.get('visibility'),
  })
  if (!parsed.success) return { success: false, error: parsed.error.flatten() }
  // ...
}

// Usage at webhook handler (trust boundary)
export async function POST(req: Request) {
  const payload = await req.json()
  const parsed = StripeWebhookSchema.safeParse(payload)
  if (!parsed.success) {
    logger.warn({ error: parsed.error }, 'Invalid webhook payload')
    return NextResponse.json({ error: { code: 'INVALID_PAYLOAD' } }, { status: 400 })
  }
}
```

### Exhaustive Switch with `never` Default

Every switch on a union type must handle all cases, with a `never` default to catch future additions at compile time:

```typescript
type ProjectStatus = 'draft' | 'active' | 'archived' | 'deleted'

function getStatusLabel(status: ProjectStatus): string {
  switch (status) {
    case 'draft':
      return 'Draft'
    case 'active':
      return 'Active'
    case 'archived':
      return 'Archived'
    case 'deleted':
      return 'Deleted'
    default: {
      const _exhaustive: never = status
      throw new Error(`Unhandled status: ${_exhaustive}`)
    }
  }
}
```

### Error Catch Blocks Use `unknown`

```typescript
// ❌ BLOCKED
try { ... } catch (e: any) { console.log(e.message) }

// ❌ BLOCKED
try { ... } catch (e) { console.log(e.message) } // implicit any

// ✅ Correct
try {
  await createProject(input)
} catch (error: unknown) {
  if (error instanceof AppError) {
    logger.error({ code: error.code, statusCode: error.statusCode }, error.message)
    return { success: false, error: { code: error.code, message: error.message } }
  }
  logger.error({ error }, 'Unexpected error in createProject')
  return { success: false, error: { code: 'INTERNAL_ERROR', message: 'Something went wrong' } }
}
```

---

## 3. Supabase Patterns

### ALWAYS Destructure AND Check Error

This is the single most common source of silent bugs. **Every** Supabase call must destructure `{ data, error }` and check `error` before using `data`.

```typescript
// ❌ BLOCKED — no error check
const { data } = await supabase.from('projects').select('id, name')

// ❌ BLOCKED — error destructured but not checked
const { data, error } = await supabase.from('projects').select('id, name')
return data // error might be non-null, data might be null

// ✅ REQUIRED pattern
const { data, error } = await supabase.from('projects').select('id, name').eq('team_id', teamId)
if (error) {
  throw new DatabaseError(error.message, { table: 'projects', operation: 'select', teamId })
}
// Now data is safely non-null
return data

// ✅ For mutations
const { data, error } = await supabase
  .from('projects')
  .insert({ name: input.name, team_id: input.teamId, created_by: userId })
  .select('id, name, created_at')
  .single()

if (error) {
  if (error.code === '23505') {
    throw new ValidationError('A project with this name already exists')
  }
  throw new DatabaseError(error.message, { table: 'projects', operation: 'insert' })
}
return data
```

### Server Auth: ALWAYS `getUser()` — NEVER `getSession()`

`getSession()` reads from the JWT without server-side verification. It can be spoofed. `getUser()` makes a round-trip to the Supabase Auth server and returns the verified user.

```typescript
// ❌ BLOCKED — session can be spoofed on server
const { data: { session } } = await supabase.auth.getSession()
const userId = session?.user?.id // INSECURE

// ✅ REQUIRED on server-side
const { data: { user }, error } = await supabase.auth.getUser()
if (error || !user) {
  throw new UnauthorizedError()
}
const userId = user.id // Verified by Supabase Auth server
```

**Exception:** `getSession()` is acceptable ONLY in client-side code for reading cached session state (e.g., showing user avatar). Never use it for authorization decisions.

### RLS Policies: Use `(select auth.uid())`

Always wrap `auth.uid()` in a subselect for performance. The Postgres query planner optimizes `(select auth.uid())` as a constant, but evaluates bare `auth.uid()` per-row.

```sql
-- ❌ Slow — evaluated per row
CREATE POLICY "Users can read own data"
  ON projects FOR SELECT
  USING (created_by = auth.uid());

-- ✅ Fast — evaluated once as constant
CREATE POLICY "Users can read own data"
  ON projects FOR SELECT
  USING (created_by = (select auth.uid()));

-- ✅ Team-based access
CREATE POLICY "Team members can read projects"
  ON projects FOR SELECT
  USING (
    team_id IN (
      SELECT team_id FROM team_members
      WHERE user_id = (select auth.uid())
    )
  );

-- ✅ Insert policy — users can only create for themselves
CREATE POLICY "Users can create own projects"
  ON projects FOR INSERT
  WITH CHECK (created_by = (select auth.uid()));
```

### Generated Types

Always regenerate types after schema changes. Never hand-write database types.

```bash
# Generate types from your Supabase project
npx supabase gen types typescript --project-id <project-id> > src/types/database.ts

# Or from a local Supabase instance
npx supabase gen types typescript --local > src/types/database.ts
```

Use the generated types in your Supabase client:

```typescript
import type { Database } from '@/types/database'

// Server client
export function createServerSupabaseClient() {
  const cookieStore = cookies()
  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    { cookies: { /* cookie adapter */ } }
  )
}
```

### SELECT Only What You Need

```typescript
// ❌ BLOCKED — fetches every column including blobs, metadata, etc.
const { data, error } = await supabase.from('projects').select('*')

// ✅ Correct — explicit columns
const { data, error } = await supabase
  .from('projects')
  .select('id, name, status, created_at, team_id')
  .eq('team_id', teamId)
  .order('created_at', { ascending: false })
  .limit(20)
```

### RLS on Every Table with User Data

Every table that contains user-generated or user-associated data MUST have:
1. RLS enabled: `ALTER TABLE <table> ENABLE ROW LEVEL SECURITY;`
2. At least one explicit policy per operation (SELECT, INSERT, UPDATE, DELETE)
3. No permissive wildcard policies in production

```sql
-- Template for user-owned data
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "select_own" ON projects FOR SELECT
  USING (created_by = (select auth.uid()));

CREATE POLICY "insert_own" ON projects FOR INSERT
  WITH CHECK (created_by = (select auth.uid()));

CREATE POLICY "update_own" ON projects FOR UPDATE
  USING (created_by = (select auth.uid()))
  WITH CHECK (created_by = (select auth.uid()));

CREATE POLICY "delete_own" ON projects FOR DELETE
  USING (created_by = (select auth.uid()));
```

### Complex Mutations: Database Functions with SECURITY DEFINER

When a mutation needs to touch multiple tables or bypass RLS for system-level operations:

```sql
CREATE OR REPLACE FUNCTION public.create_project_with_membership(
  p_name TEXT,
  p_team_id UUID,
  p_visibility TEXT DEFAULT 'private'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_project_id UUID;
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Verify team membership
  IF NOT EXISTS (
    SELECT 1 FROM team_members WHERE team_id = p_team_id AND user_id = v_user_id
  ) THEN
    RAISE EXCEPTION 'Not a member of this team';
  END IF;

  -- Create project
  INSERT INTO projects (name, team_id, visibility, created_by)
  VALUES (p_name, p_team_id, p_visibility, v_user_id)
  RETURNING id INTO v_project_id;

  -- Auto-add creator as project admin
  INSERT INTO project_members (project_id, user_id, role)
  VALUES (v_project_id, v_user_id, 'admin');

  RETURN v_project_id;
END;
$$;
```

### Realtime: Always Unsubscribe on Unmount

```typescript
'use client'

import { useEffect } from 'react'
import { createBrowserClient } from '@/lib/supabase/client'

export function useRealtimeProjects(teamId: string) {
  const supabase = createBrowserClient()

  useEffect(() => {
    const channel = supabase
      .channel(`projects:${teamId}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'projects',
          filter: `team_id=eq.${teamId}`,
        },
        (payload) => {
          // Handle change
        }
      )
      .subscribe()

    // ✅ ALWAYS unsubscribe on unmount
    return () => {
      supabase.removeChannel(channel)
    }
  }, [teamId, supabase])
}
```

---

## 4. API & Server Action Patterns

### Route Handler Pattern: Validate → Authenticate → Authorize → Logic → Response

Every API route follows this exact order. No exceptions.

```typescript
// src/app/api/projects/route.ts
import { NextResponse } from 'next/server'
import { z } from 'zod'
import { createServerSupabaseClient } from '@/lib/supabase/server'
import { logger } from '@/lib/logger'
import { rateLimit } from '@/lib/rate-limit'
import { AppError, UnauthorizedError, ValidationError } from '@/lib/errors'

const CreateProjectSchema = z.object({
  name: z.string().min(1, 'Name is required').max(100),
  description: z.string().max(500).optional(),
  teamId: z.string().uuid('Invalid team ID'),
  visibility: z.enum(['private', 'team', 'public']),
})

export async function POST(req: Request) {
  try {
    // 1. RATE LIMIT
    const rateLimitResult = await rateLimit(req, { limit: 10, window: '1m' })
    if (!rateLimitResult.success) {
      return NextResponse.json(
        { error: { code: 'RATE_LIMITED', message: 'Too many requests' } },
        { status: 429 }
      )
    }

    // 2. VALIDATE
    const body = await req.json()
    const parsed = CreateProjectSchema.safeParse(body)
    if (!parsed.success) {
      return NextResponse.json(
        {
          error: {
            code: 'VALIDATION_ERROR',
            message: 'Invalid input',
            details: parsed.error.flatten(),
          },
        },
        { status: 400 }
      )
    }

    // 3. AUTHENTICATE
    const supabase = await createServerSupabaseClient()
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) {
      return NextResponse.json(
        { error: { code: 'UNAUTHORIZED', message: 'Authentication required' } },
        { status: 401 }
      )
    }

    // 4. AUTHORIZE
    const { data: membership, error: memberError } = await supabase
      .from('team_members')
      .select('role')
      .eq('team_id', parsed.data.teamId)
      .eq('user_id', user.id)
      .single()

    if (memberError || !membership) {
      return NextResponse.json(
        { error: { code: 'FORBIDDEN', message: 'Not a member of this team' } },
        { status: 403 }
      )
    }

    // 5. BUSINESS LOGIC
    const { data: project, error: insertError } = await supabase
      .from('projects')
      .insert({
        name: parsed.data.name,
        description: parsed.data.description,
        team_id: parsed.data.teamId,
        visibility: parsed.data.visibility,
        created_by: user.id,
      })
      .select('id, name, created_at')
      .single()

    if (insertError) {
      logger.error({ error: insertError, userId: user.id }, 'Failed to create project')
      return NextResponse.json(
        { error: { code: 'DATABASE_ERROR', message: 'Failed to create project' } },
        { status: 500 }
      )
    }

    // 6. RESPONSE
    return NextResponse.json({ data: project }, { status: 201 })

  } catch (error: unknown) {
    logger.error({ error }, 'Unhandled error in POST /api/projects')
    return NextResponse.json(
      { error: { code: 'INTERNAL_ERROR', message: 'Internal server error' } },
      { status: 500 }
    )
  }
}
```

### GET Route with Pagination

```typescript
export async function GET(req: Request) {
  const { searchParams } = new URL(req.url)
  const cursor = searchParams.get('cursor')
  const limit = Math.min(Number(searchParams.get('limit') || 20), 100)

  const supabase = await createServerSupabaseClient()
  const { data: { user }, error: authError } = await supabase.auth.getUser()
  if (authError || !user) {
    return NextResponse.json(
      { error: { code: 'UNAUTHORIZED' } },
      { status: 401 }
    )
  }

  let query = supabase
    .from('projects')
    .select('id, name, status, created_at')
    .eq('created_by', user.id)
    .order('created_at', { ascending: false })
    .limit(limit + 1) // Fetch one extra to detect next page

  if (cursor) {
    query = query.lt('created_at', cursor)
  }

  const { data, error } = await query
  if (error) {
    logger.error({ error, userId: user.id }, 'Failed to fetch projects')
    return NextResponse.json(
      { error: { code: 'DATABASE_ERROR', message: 'Failed to fetch projects' } },
      { status: 500 }
    )
  }

  const hasMore = data.length > limit
  const items = hasMore ? data.slice(0, limit) : data
  const nextCursor = hasMore ? items[items.length - 1]?.created_at : null

  return NextResponse.json({
    data: items,
    pagination: { nextCursor, hasMore },
  })
}
```

### Consistent Error Response Shape

Every error response from every endpoint MUST match this shape:

```typescript
// src/types/api.ts
export type ApiErrorResponse = {
  error: {
    code: string       // Machine-readable: 'VALIDATION_ERROR', 'UNAUTHORIZED', etc.
    message: string    // Human-readable description
    details?: unknown  // Optional: Zod errors, field-level details, etc.
  }
}

export type ApiSuccessResponse<T> = {
  data: T
}

export type PaginatedResponse<T> = {
  data: T[]
  pagination: {
    nextCursor: string | null
    hasMore: boolean
  }
}
```

### Server Actions: Return `{ success, data?, error? }` — NEVER Throw

```typescript
'use server'

import { revalidatePath } from 'next/cache'
import { z } from 'zod'
import { createServerSupabaseClient } from '@/lib/supabase/server'

const UpdateProjectSchema = z.object({
  projectId: z.string().uuid(),
  name: z.string().min(1).max(100),
})

type ActionResult<T = void> =
  | { success: true; data: T }
  | { success: false; error: { code: string; message: string; details?: unknown } }

export async function updateProject(formData: FormData): Promise<ActionResult<{ id: string }>> {
  // Validate
  const parsed = UpdateProjectSchema.safeParse({
    projectId: formData.get('projectId'),
    name: formData.get('name'),
  })

  if (!parsed.success) {
    return {
      success: false,
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid input',
        details: parsed.error.flatten(),
      },
    }
  }

  // Authenticate
  const supabase = await createServerSupabaseClient()
  const { data: { user }, error: authError } = await supabase.auth.getUser()
  if (authError || !user) {
    return { success: false, error: { code: 'UNAUTHORIZED', message: 'Not authenticated' } }
  }

  // Execute
  const { data, error } = await supabase
    .from('projects')
    .update({ name: parsed.data.name })
    .eq('id', parsed.data.projectId)
    .eq('created_by', user.id) // RLS backup: ensure ownership
    .select('id')
    .single()

  if (error) {
    return { success: false, error: { code: 'DATABASE_ERROR', message: 'Failed to update project' } }
  }

  revalidatePath('/dashboard/projects')
  return { success: true, data: { id: data.id } }
}
```

### Idempotency for Mutations

Critical mutations (payments, scoring, state transitions) must be idempotent:

```typescript
export async function POST(req: Request) {
  const idempotencyKey = req.headers.get('Idempotency-Key')
  if (!idempotencyKey) {
    return NextResponse.json(
      { error: { code: 'MISSING_IDEMPOTENCY_KEY', message: 'Idempotency-Key header required' } },
      { status: 400 }
    )
  }

  // Check if this request was already processed
  const { data: existing, error: lookupError } = await supabase
    .from('idempotency_keys')
    .select('response_body, response_status')
    .eq('key', idempotencyKey)
    .single()

  if (existing) {
    // Return cached response
    return NextResponse.json(JSON.parse(existing.response_body), { status: existing.response_status })
  }

  // Process the request...
  // Store the response with the idempotency key
}
```

---

## 5. Security Requirements (Non-Negotiable)

These are not suggestions. Every item in this section is a hard requirement. Violations block deploy.

### Auth Check on EVERY Protected Route

```typescript
// ❌ BLOCKED — no auth check
export async function GET(req: Request) {
  const { data } = await supabase.from('projects').select('*')
  return NextResponse.json(data)
}

// ✅ REQUIRED
export async function GET(req: Request) {
  const supabase = await createServerSupabaseClient()
  const { data: { user }, error } = await supabase.auth.getUser()
  if (error || !user) {
    return NextResponse.json({ error: { code: 'UNAUTHORIZED' } }, { status: 401 })
  }
  // Now fetch data scoped to this user...
}
```

### Input Validation BEFORE Any Processing

Never touch the database, call external APIs, or perform any business logic before validating input:

```typescript
// ❌ BLOCKED — processes before validation
export async function POST(req: Request) {
  const body = await req.json()
  const result = await supabase.from('projects').insert(body) // RAW USER INPUT
  return NextResponse.json(result)
}

// ✅ REQUIRED — validate first
export async function POST(req: Request) {
  const body = await req.json()
  const parsed = CreateProjectSchema.safeParse(body)
  if (!parsed.success) {
    return NextResponse.json({ error: { code: 'VALIDATION_ERROR', ... } }, { status: 400 })
  }
  // Only now use parsed.data (validated and typed)
}
```

### No Secrets in Client Code

```typescript
// ❌ BLOCKED — server secret exposed to client
// .env
NEXT_PUBLIC_STRIPE_SECRET_KEY=sk_live_xxx        // NEVER
NEXT_PUBLIC_SUPABASE_SERVICE_ROLE_KEY=eyJ...      // NEVER
NEXT_PUBLIC_DATABASE_URL=postgresql://...          // NEVER

// ✅ Correct — only public keys use NEXT_PUBLIC_
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co  // OK — public
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...              // OK — public (RLS enforced)
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_live_xxx    // OK — public
STRIPE_SECRET_KEY=sk_live_xxx                     // Server-only — correct
SUPABASE_SERVICE_ROLE_KEY=eyJ...                  // Server-only — correct
```

### Webhook Signature Verification

Every webhook endpoint MUST verify the signature before processing:

```typescript
// src/app/api/webhooks/stripe/route.ts
import Stripe from 'stripe'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!)
const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET!

export async function POST(req: Request) {
  const body = await req.text() // Raw body for signature verification
  const signature = req.headers.get('stripe-signature')

  if (!signature) {
    return NextResponse.json({ error: { code: 'MISSING_SIGNATURE' } }, { status: 400 })
  }

  let event: Stripe.Event
  try {
    event = stripe.webhooks.constructEvent(body, signature, webhookSecret)
  } catch (err: unknown) {
    logger.warn({ error: err }, 'Webhook signature verification failed')
    return NextResponse.json({ error: { code: 'INVALID_SIGNATURE' } }, { status: 400 })
  }

  // Now safe to process event
  switch (event.type) {
    case 'checkout.session.completed':
      await handleCheckoutComplete(event.data.object)
      break
    // ...
  }

  return NextResponse.json({ received: true })
}
```

### XSS Prevention

```typescript
// ❌ BLOCKED — raw HTML injection
<div dangerouslySetInnerHTML={{ __html: userContent }} />

// ✅ If you absolutely must render HTML (e.g., rich text from CMS)
import DOMPurify from 'isomorphic-dompurify'

<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userContent) }} />

// ✅ Better — use a markdown renderer with sanitization
import ReactMarkdown from 'react-markdown'

<ReactMarkdown>{userContent}</ReactMarkdown>
```

### Content Security Policy Headers

Add CSP headers in `next.config.js` or middleware:

```typescript
// middleware.ts
export function middleware(request: NextRequest) {
  const response = NextResponse.next()

  response.headers.set(
    'Content-Security-Policy',
    [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline' 'unsafe-eval'", // Tighten in production
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data: https:",
      "font-src 'self'",
      "connect-src 'self' https://*.supabase.co wss://*.supabase.co",
      "frame-ancestors 'none'",
    ].join('; ')
  )
  response.headers.set('X-Frame-Options', 'DENY')
  response.headers.set('X-Content-Type-Options', 'nosniff')
  response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin')

  return response
}
```

### Rate Limiting Budgets

| Endpoint Type | Limit | Window |
|---|---|---|
| Auth (login/signup/reset) | 5 requests | 1 minute |
| Form submissions | 10 requests | 1 minute |
| Search/filter | 30 requests | 1 minute |
| Public API | 100 requests | 1 minute |
| Webhooks | No limit | — (verified by signature) |

Implementation using Upstash or in-memory rate limiter:

```typescript
// src/lib/rate-limit.ts
import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL!,
  token: process.env.UPSTASH_REDIS_REST_TOKEN!,
})

export const authLimiter = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(5, '1 m'),
  prefix: 'ratelimit:auth',
})

export const formLimiter = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(10, '1 m'),
  prefix: 'ratelimit:form',
})

export const searchLimiter = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(30, '1 m'),
  prefix: 'ratelimit:search',
})

export const apiLimiter = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(100, '1 m'),
  prefix: 'ratelimit:api',
})

// Usage helper
export async function checkRateLimit(
  limiter: Ratelimit,
  identifier: string
): Promise<{ success: boolean; remaining: number }> {
  const result = await limiter.limit(identifier)
  return { success: result.success, remaining: result.remaining }
}
```

---

## 6. Error Handling

### Custom Error Classes

Every project starts with these error classes in `src/lib/errors.ts`:

```typescript
// src/lib/errors.ts

export class AppError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly statusCode: number = 500,
    public readonly details?: unknown
  ) {
    super(message)
    this.name = 'AppError'
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string, id?: string) {
    super(
      id ? `${resource} with id '${id}' not found` : `${resource} not found`,
      'NOT_FOUND',
      404
    )
    this.name = 'NotFoundError'
  }
}

export class ValidationError extends AppError {
  constructor(details: string | unknown) {
    super(
      typeof details === 'string' ? details : 'Validation failed',
      'VALIDATION_ERROR',
      400,
      typeof details === 'string' ? undefined : details
    )
    this.name = 'ValidationError'
  }
}

export class UnauthorizedError extends AppError {
  constructor(message: string = 'Unauthorized') {
    super(message, 'UNAUTHORIZED', 401)
    this.name = 'UnauthorizedError'
  }
}

export class ForbiddenError extends AppError {
  constructor(message: string = 'Forbidden') {
    super(message, 'FORBIDDEN', 403)
    this.name = 'ForbiddenError'
  }
}

export class ConflictError extends AppError {
  constructor(message: string) {
    super(message, 'CONFLICT', 409)
    this.name = 'ConflictError'
  }
}

export class RateLimitError extends AppError {
  constructor() {
    super('Too many requests', 'RATE_LIMITED', 429)
    this.name = 'RateLimitError'
  }
}

export class DatabaseError extends AppError {
  constructor(message: string, details?: { table?: string; operation?: string; [key: string]: unknown }) {
    super(message, 'DATABASE_ERROR', 500, details)
    this.name = 'DatabaseError'
  }
}

export class ExternalServiceError extends AppError {
  constructor(service: string, message: string) {
    super(`${service}: ${message}`, 'EXTERNAL_SERVICE_ERROR', 502)
    this.name = 'ExternalServiceError'
  }
}
```

### Supabase Error: ALWAYS Check

```typescript
// ❌ BLOCKED — assumes success
const { data } = await supabase.from('users').select('id, name').eq('id', userId).single()
return data.name // data might be null if error occurred

// ✅ REQUIRED
const { data, error } = await supabase.from('users').select('id, name').eq('id', userId).single()
if (error) {
  if (error.code === 'PGRST116') {
    throw new NotFoundError('User', userId)
  }
  throw new DatabaseError(error.message, { table: 'users', operation: 'select' })
}
return data.name // Safe — error was checked
```

### Try/Catch with Specific Error Types

```typescript
// ❌ BAD — generic catch, swallowed error
try {
  await doSomething()
} catch (e) {
  return { error: 'Something went wrong' }
}

// ✅ GOOD — specific error handling with proper logging
export async function handleProjectCreation(input: CreateProjectInput) {
  try {
    const project = await createProject(input)
    return { success: true as const, data: project }
  } catch (error: unknown) {
    if (error instanceof ValidationError) {
      return { success: false as const, error: { code: error.code, message: error.message, details: error.details } }
    }
    if (error instanceof UnauthorizedError) {
      return { success: false as const, error: { code: error.code, message: error.message } }
    }
    if (error instanceof DatabaseError) {
      logger.error({ error: error.details, input }, 'Database error during project creation')
      return { success: false as const, error: { code: 'DATABASE_ERROR', message: 'Failed to create project' } }
    }
    // Unknown error — log full context, return generic message
    logger.error({ error, input }, 'Unexpected error during project creation')
    return { success: false as const, error: { code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' } }
  }
}
```

### Error Boundaries in React

Every route segment that can fail should have an `error.tsx`:

```typescript
// src/app/(dashboard)/projects/error.tsx
'use client'

import { useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { logger } from '@/lib/logger'

export default function ProjectsError({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    logger.error({ error: error.message, digest: error.digest }, 'Projects page error')
  }, [error])

  return (
    <div className="flex flex-col items-center justify-center gap-4 py-16">
      <h2 className="text-lg font-semibold">Something went wrong</h2>
      <p className="text-muted-foreground text-sm">
        Failed to load projects. Please try again.
      </p>
      <Button onClick={reset} variant="outline">
        Try again
      </Button>
    </div>
  )
}
```

### Structured Logging

Never use `console.log` in production code. Use a structured logger:

```typescript
// src/lib/logger.ts
import pino from 'pino'

export const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  transport:
    process.env.NODE_ENV === 'development'
      ? { target: 'pino-pretty', options: { colorize: true } }
      : undefined,
})

// Usage — always include context
logger.info({ userId, projectId }, 'Project created')
logger.warn({ userId, endpoint: '/api/projects', remaining: 2 }, 'Rate limit approaching')
logger.error({ error, userId, route: '/api/projects', input }, 'Failed to create project')
```

---

## 7. Performance Standards

### No N+1 Queries

```typescript
// ❌ N+1 — one query per project to get members
const projects = await getProjects(teamId)
for (const project of projects) {
  const members = await getProjectMembers(project.id) // N additional queries!
  project.members = members
}

// ✅ JOIN — single query
const { data, error } = await supabase
  .from('projects')
  .select(`
    id,
    name,
    status,
    project_members (
      user_id,
      role,
      users ( name, avatar_url )
    )
  `)
  .eq('team_id', teamId)

// ✅ Batch with .in() filter
const projectIds = projects.map(p => p.id)
const { data: allMembers, error } = await supabase
  .from('project_members')
  .select('project_id, user_id, role')
  .in('project_id', projectIds)
```

### No Unbounded Queries

```typescript
// ❌ BLOCKED — fetches entire table
const { data } = await supabase.from('audit_logs').select('*')

// ✅ Always limit
const { data } = await supabase
  .from('audit_logs')
  .select('id, action, created_at, user_id')
  .eq('project_id', projectId)
  .order('created_at', { ascending: false })
  .limit(50)
```

### Promise.all for Independent Operations

```typescript
// ❌ SLOW — sequential when operations are independent
const user = await getUser(userId)
const projects = await getProjects(teamId)
const notifications = await getNotifications(userId)

// ✅ FAST — parallel execution
const [user, projects, notifications] = await Promise.all([
  getUser(userId),
  getProjects(teamId),
  getNotifications(userId),
])
```

### React.memo: Only When Profiling Shows Need

```typescript
// ❌ Premature optimization — don't do this without evidence
const ProjectCard = React.memo(function ProjectCard({ project }: Props) {
  return <div>{project.name}</div>
})

// ✅ Use React.memo ONLY after React DevTools Profiler shows:
// 1. This component re-renders frequently (>5x per interaction)
// 2. The re-render is expensive (>16ms)
// 3. Props are stable or can be memoized
// Document WHY in a comment:
// PERF: Profiled 2026-03-15 — re-renders 12x on keystroke in search, 45ms each
const ProjectCard = React.memo(function ProjectCard({ project }: Props) {
  return <ExpensiveProjectVisualization project={project} />
})
```

### Images Through next/image

```typescript
// ❌ BLOCKED — no optimization, no dimensions, layout shift
<img src={user.avatarUrl} />

// ✅ REQUIRED
import Image from 'next/image'

<Image
  src={user.avatarUrl}
  alt={`${user.name}'s avatar`}
  width={40}
  height={40}
  className="rounded-full"
/>
```

### Cursor-Based Pagination (Default)

```typescript
// Standard cursor-based pagination implementation
export async function getProjects(params: {
  teamId: string
  cursor?: string
  limit?: number
}) {
  const limit = Math.min(params.limit || 20, 100)

  let query = supabase
    .from('projects')
    .select('id, name, status, created_at')
    .eq('team_id', params.teamId)
    .order('created_at', { ascending: false })
    .limit(limit + 1)

  if (params.cursor) {
    query = query.lt('created_at', params.cursor)
  }

  const { data, error } = await query
  if (error) throw new DatabaseError(error.message, { table: 'projects' })

  const hasMore = data.length > limit
  const items = hasMore ? data.slice(0, limit) : data
  const nextCursor = hasMore ? items[items.length - 1]?.created_at : null

  return { items, nextCursor, hasMore }
}
```

### Database Indexes

```sql
-- Every foreign key gets an index
CREATE INDEX idx_projects_team_id ON projects(team_id);
CREATE INDEX idx_projects_created_by ON projects(created_by);
CREATE INDEX idx_project_members_project_id ON project_members(project_id);
CREATE INDEX idx_project_members_user_id ON project_members(user_id);

-- Every WHERE clause column used in queries gets an index
CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_projects_visibility ON projects(visibility);

-- Composite indexes for common query patterns
CREATE INDEX idx_projects_team_status ON projects(team_id, status);
CREATE INDEX idx_audit_logs_project_created ON audit_logs(project_id, created_at DESC);
```

### Performance Budgets

| Metric | Target | Measurement |
|---|---|---|
| Largest Contentful Paint (LCP) | < 2.0s | Lighthouse / Web Vitals |
| First Input Delay (FID) | < 100ms | Web Vitals |
| Cumulative Layout Shift (CLS) | < 0.1 | Web Vitals |
| API Response p95 | < 500ms | Server logs |
| API Response p99 | < 1000ms | Server logs |
| Time to First Byte (TTFB) | < 800ms | Lighthouse |
| JavaScript bundle (initial) | < 200KB gzipped | Next.js build output |

---

## 8. Testing Requirements

### Minimum Coverage Requirements

| What | Minimum Tests |
|---|---|
| Every API route | 1 happy path + 1 error path |
| Every database function | Valid input + invalid input |
| Every auth flow | Authenticated + unauthenticated |
| Payment/financial logic | Comprehensive (P0 — no gaps) |
| Complex business logic | Edge cases + boundary conditions |

### Test File Naming and Location

Tests live next to the code they test:

```
src/features/projects/api/
├── create-project.ts
├── create-project.test.ts    # ← Test file right next to source
├── get-projects.ts
└── get-projects.test.ts
```

### API Route Test Pattern

```typescript
// src/app/api/projects/route.test.ts
import { POST, GET } from './route'
import { createMockRequest, createMockUser } from '@/test/helpers'

describe('POST /api/projects', () => {
  it('creates a project for authenticated user', async () => {
    const user = createMockUser()
    const req = createMockRequest({
      method: 'POST',
      body: {
        name: 'My Project',
        teamId: 'team-uuid-123',
        visibility: 'private',
      },
      user,
    })

    const response = await POST(req)
    const json = await response.json()

    expect(response.status).toBe(201)
    expect(json.data).toMatchObject({
      id: expect.any(String),
      name: 'My Project',
    })
  })

  it('returns 401 for unauthenticated request', async () => {
    const req = createMockRequest({
      method: 'POST',
      body: { name: 'My Project', teamId: 'team-uuid-123', visibility: 'private' },
      user: null, // No auth
    })

    const response = await POST(req)
    const json = await response.json()

    expect(response.status).toBe(401)
    expect(json.error.code).toBe('UNAUTHORIZED')
  })

  it('returns 400 for invalid input', async () => {
    const user = createMockUser()
    const req = createMockRequest({
      method: 'POST',
      body: { name: '', teamId: 'not-a-uuid', visibility: 'invalid' }, // All invalid
      user,
    })

    const response = await POST(req)
    const json = await response.json()

    expect(response.status).toBe(400)
    expect(json.error.code).toBe('VALIDATION_ERROR')
  })

  it('returns 403 when user is not a team member', async () => {
    const user = createMockUser()
    const req = createMockRequest({
      method: 'POST',
      body: { name: 'My Project', teamId: 'other-team-uuid', visibility: 'private' },
      user, // Authenticated but not a member of this team
    })

    const response = await POST(req)
    const json = await response.json()

    expect(response.status).toBe(403)
    expect(json.error.code).toBe('FORBIDDEN')
  })
})
```

### Database Function Test Pattern

```typescript
describe('create_project_with_membership', () => {
  it('creates project and adds creator as admin', async () => {
    const user = await createTestUser()
    const team = await createTestTeam(user.id)

    const { data, error } = await supabase.rpc('create_project_with_membership', {
      p_name: 'Test Project',
      p_team_id: team.id,
      p_visibility: 'private',
    })

    expect(error).toBeNull()
    expect(data).toBeDefined()

    // Verify project was created
    const { data: project } = await supabase
      .from('projects')
      .select('id, name, created_by')
      .eq('id', data)
      .single()

    expect(project?.name).toBe('Test Project')
    expect(project?.created_by).toBe(user.id)

    // Verify membership was created
    const { data: membership } = await supabase
      .from('project_members')
      .select('role')
      .eq('project_id', data)
      .eq('user_id', user.id)
      .single()

    expect(membership?.role).toBe('admin')
  })

  it('rejects non-team-member', async () => {
    const outsider = await createTestUser()
    const team = await createTestTeam() // Different user owns this team

    const { data, error } = await supabase.rpc('create_project_with_membership', {
      p_name: 'Test Project',
      p_team_id: team.id,
    })

    expect(error).toBeDefined()
    expect(error?.message).toContain('Not a member')
  })
})
```

### Auth Flow Test Pattern

```typescript
describe('Auth flows', () => {
  describe('Protected route: GET /api/projects', () => {
    it('returns data for authenticated user', async () => {
      const user = createMockUser()
      const req = createMockRequest({ method: 'GET', user })

      const response = await GET(req)
      expect(response.status).toBe(200)
    })

    it('returns 401 for unauthenticated request', async () => {
      const req = createMockRequest({ method: 'GET', user: null })

      const response = await GET(req)
      expect(response.status).toBe(401)
    })

    it('returns 401 for expired token', async () => {
      const req = createMockRequest({
        method: 'GET',
        user: null,
        headers: { Authorization: 'Bearer expired-token' },
      })

      const response = await GET(req)
      expect(response.status).toBe(401)
    })
  })
})
```

### Payment/Financial Logic: Comprehensive Tests (P0)

```typescript
describe('Billing: processSubscriptionChange', () => {
  it('upgrades from free to pro correctly', async () => { /* ... */ })
  it('downgrades from pro to free at period end', async () => { /* ... */ })
  it('handles duplicate webhook events idempotently', async () => { /* ... */ })
  it('does not charge if already on target plan', async () => { /* ... */ })
  it('prorates when upgrading mid-cycle', async () => { /* ... */ })
  it('handles Stripe webhook signature failure', async () => { /* ... */ })
  it('handles Stripe API timeout gracefully', async () => { /* ... */ })
  it('rolls back on partial failure', async () => { /* ... */ })
  it('uses database transaction for balance updates', async () => { /* ... */ })
  it('prevents race condition on concurrent plan changes', async () => { /* ... */ })
})
```

### Test Utilities

```typescript
// src/test/helpers.ts
export function createMockUser(overrides?: Partial<User>) {
  return {
    id: 'user-uuid-123',
    email: 'test@example.com',
    ...overrides,
  }
}

export function createMockRequest(options: {
  method: string
  body?: unknown
  user: User | null
  headers?: Record<string, string>
  searchParams?: Record<string, string>
}) {
  // Implementation that creates a Request object
  // with mocked Supabase auth returning the specified user
}
```

---

## 9. Git Standards

### Atomic Commits

One logical change per commit. If you can't describe the commit in one sentence, it's too big.

```bash
# ❌ BAD — multiple unrelated changes
git commit -m "Add project creation, fix auth bug, update styles"

# ✅ GOOD — one logical change each
git commit -m "feat: add project creation API route"
git commit -m "fix: return 401 when auth token is expired"
git commit -m "style: update project card border radius"
```

### Conventional Commit Messages

Every commit message follows Conventional Commits format:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

| Type | When |
|---|---|
| `feat:` | New feature or capability |
| `fix:` | Bug fix |
| `refactor:` | Code change that neither fixes a bug nor adds a feature |
| `docs:` | Documentation only |
| `test:` | Adding or updating tests |
| `chore:` | Build process, tooling, dependencies |
| `style:` | Formatting, semicolons, etc. (no code logic change) |
| `perf:` | Performance improvement |
| `ci:` | CI/CD changes |

Examples:

```bash
feat(projects): add cursor-based pagination to project list
fix(auth): handle expired refresh token in middleware
refactor(billing): extract payment processing to dedicated module
docs(api): add OpenAPI spec for project endpoints
test(projects): add tests for project creation edge cases
chore(deps): update supabase-js to 2.45.0
perf(dashboard): lazy-load analytics charts
```

### PR Size Limit

Pull requests MUST be under 400 lines changed. If a feature needs more:

1. Split into sequential PRs: `feat/project-schema` → `feat/project-api` → `feat/project-ui`
2. Use feature flags for incomplete features
3. Each PR must be independently deployable and not break existing functionality

### No console.log in Committed Code

```typescript
// ❌ BLOCKED — will fail lint
console.log('user data:', userData)
console.log('debug:', result)

// ✅ Use structured logger
logger.debug({ userData }, 'Fetched user data')
logger.info({ projectId: result.id }, 'Project created')
```

ESLint rule to enforce:

```json
{
  "rules": {
    "no-console": ["error", { "allow": ["warn", "error"] }]
  }
}
```

### No Commented-Out Code

```typescript
// ❌ BLOCKED — dead code, use git history instead
// function oldImplementation() {
//   const result = await fetch('/api/v1/projects')
//   return result.json()
// }

function currentImplementation() {
  // Active code only
}
```

### .env.example Always Current

Every time an environment variable is added, updated, or removed, `.env.example` must be updated in the same commit:

```bash
# .env.example — keep in sync with actual env vars
# Last updated: 2026-03-21

# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...

# Rate Limiting (Upstash)
UPSTASH_REDIS_REST_URL=https://...
UPSTASH_REDIS_REST_TOKEN=...

# Logging
LOG_LEVEL=info
```

---

## 10. What Gets You BLOCKED

These are **P0 violations**. Forge will **BLOCK the deploy** if any are found during review. No exceptions. No "I'll fix it later." Fix it before it ships.

### 🚫 Missing Auth on a Protected Endpoint

```typescript
// BLOCKED: No auth check — anyone can call this
export async function GET(req: Request) {
  const { data } = await supabase.from('projects').select('id, name')
  return NextResponse.json(data)
}
```

**Fix:** Add `getUser()` check. Every protected route. Every time.

### 🚫 Missing Supabase Error Checking

```typescript
// BLOCKED: Destructures data but never checks error
const { data } = await supabase.from('projects').select('id, name')
return data // Could be null, error could have context
```

**Fix:** Always destructure `{ data, error }` and check `error` before using `data`.

### 🚫 Missing Input Validation on User-Facing Endpoint

```typescript
// BLOCKED: Raw user input hits the database
export async function POST(req: Request) {
  const body = await req.json()
  await supabase.from('projects').insert(body)
}
```

**Fix:** Zod `safeParse` before any processing. Always.

### 🚫 Hardcoded Secrets in Source Code

```typescript
// BLOCKED: Secret in source
const stripe = new Stripe('sk_live_abc123...')
const supabase = createClient(url, 'eyJhbGciOiJIUzI1NiI...')
```

**Fix:** Use environment variables. Never commit secrets.

### 🚫 Direct Database UPDATE on Financial/Scoring Fields

```typescript
// BLOCKED: Direct update — no locking, no atomicity
await supabase
  .from('wallets')
  .update({ balance: newBalance })
  .eq('user_id', userId)

// BLOCKED: Read-then-write race condition
const { data: wallet } = await supabase.from('wallets').select('balance').eq('user_id', userId).single()
const newBalance = wallet.balance + amount
await supabase.from('wallets').update({ balance: newBalance }).eq('user_id', userId)
```

**Fix:** Use a database function with `SELECT ... FOR UPDATE` locking:

```sql
CREATE OR REPLACE FUNCTION public.update_wallet_balance(
  p_user_id UUID,
  p_amount NUMERIC,
  p_reason TEXT
)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_new_balance NUMERIC;
BEGIN
  -- Lock the row to prevent concurrent updates
  SELECT balance INTO v_new_balance
  FROM wallets
  WHERE user_id = p_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Wallet not found for user %', p_user_id;
  END IF;

  v_new_balance := v_new_balance + p_amount;

  IF v_new_balance < 0 THEN
    RAISE EXCEPTION 'Insufficient balance';
  END IF;

  UPDATE wallets SET balance = v_new_balance, updated_at = now()
  WHERE user_id = p_user_id;

  -- Audit trail
  INSERT INTO wallet_transactions (user_id, amount, reason, balance_after)
  VALUES (p_user_id, p_amount, p_reason, v_new_balance);

  RETURN v_new_balance;
END;
$$;
```

### 🚫 Missing RLS on Any Table with User Data

```sql
-- BLOCKED: Table created without RLS
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_by UUID REFERENCES auth.users(id)
);
-- No ALTER TABLE ... ENABLE ROW LEVEL SECURITY
-- No policies defined
```

**Fix:** Every table with user data must have RLS enabled and explicit policies.

### 🚫 Race Conditions on Financial or Scoring Operations

```typescript
// BLOCKED: Classic read-modify-write race
const current = await getScore(userId)
const newScore = current + points
await updateScore(userId, newScore)
// Two concurrent requests read same value, both write — one update is lost
```

**Fix:** Database functions with `FOR UPDATE` row locks (see financial example above).

### 🚫 Using `getSession()` Instead of `getUser()` on Server-Side

```typescript
// BLOCKED: Session can be spoofed
const { data: { session } } = await supabase.auth.getSession()
if (session?.user) { /* trusting unverified data */ }
```

**Fix:** Always `getUser()` on server. See Section 3.

### 🚫 Any Use of `any` Without Written Justification

```typescript
// BLOCKED: No justification
function process(data: any) { ... }
const result = response as any
```

**Fix:** Add `// REASON: <specific reason>` or refactor to use `unknown` with narrowing.

---

## How This Document Is Maintained

- **Forge (Technical Architect) owns this document.** No other agent modifies it.
- After every review, Forge may update this document with new patterns, rules, or examples.
- Maks is expected to **re-read this document at the start of every new project**.
- ClawExpert verifies this document hasn't been overwritten during workspace audits.
- If Maks disagrees with a rule, escalate to Nick — don't silently ignore it.

---

**Written by:** Forge (Technical Architect)
**Effective:** 2026-03-21
**Version:** 1.0
