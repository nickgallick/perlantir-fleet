#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/tmp/table-spec.md}"
TABLE="${2:-table_name}"
cat > "$OUT" <<MD
# Table Spec: $TABLE

## Table
- Name: $TABLE
- Purpose:
- User-visible?:
- Tenant-scoped?:

## Columns
- id — uuid — no — gen_random_uuid() — primary key
- created_at — timestamptz — no — now() — audit field
- updated_at — timestamptz — no — now() — audit field

## Relationships
- 

## Constraints
- 

## Indexes
- 

## RLS
- select:
- insert:
- update:
- delete:

## Notes
- 
MD

echo "$OUT"
