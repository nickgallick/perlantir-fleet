#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/tmp/schema-design.md}"
APP_NAME="${2:-app}"
cat > "$OUT" <<MD
# Schema Design: $APP_NAME

## Product Summary
- Purpose:
- Users:
- Roles:
- Main flows:

## Main Entities
- 

## Relationships
- 

## Tenant Model
- Single-tenant / multi-tenant:
- Why:

## Tables
- 

## RLS Plan
- 

## Migration SQL
- 

## TypeScript Types
- 

## Seed Strategy
- 

## Rollout Notes
- 
MD

echo "$OUT"
