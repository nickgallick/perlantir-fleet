# Common Patterns

## Auth + profile bootstrap
When app users need profile data, include an explicit profile table and describe bootstrap behavior after signup.

## Multi-tenant apps
If users belong to organizations, model:
- organizations
- organization_members
- role field
- tenant-scoped foreign keys

## Admin/internal tools
Prefer audit-friendly schemas with explicit ownership and timestamps.

## User-generated content
Think through delete behavior, moderation/admin access, and query patterns.

## Seeds
Always include:
- at least one admin-like user context
- realistic app data
- enough related rows to test filters/sorts/states
