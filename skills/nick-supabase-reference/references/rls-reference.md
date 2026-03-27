# RLS Reference

## Baseline
Every user-facing table should have explicit RLS reasoning.

## Ask for every table
- who can read?
- who can insert?
- who can update?
- who can delete?
- what bootstrap edge cases exist?
- what multi-tenant isolation is required?

## Common mistakes
- policies allow insert but block follow-up read
- membership/profile dependency missing
- cross-tenant leakage
- relying on client logic instead of database policy

## Good habit
Explain RLS in plain English alongside policy SQL.
