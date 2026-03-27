# Edge Functions Reference

## Use when
- server-side logic should live close to Supabase
- secure integrations/webhooks are needed
- privileged operations should not run in the client

## Rules
- keep secrets server-side only
- validate request intent and auth context
- define happy path and failure path clearly
- log enough for debugging without leaking secrets
