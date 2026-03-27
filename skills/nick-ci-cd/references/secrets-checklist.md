# CI Secrets Checklist

Common secrets/vars to consider:
- Vercel token
- Vercel org/project ids
- Supabase project URL
- Supabase anon key if needed for tests
- environment-specific app URLs

## Rules
- never hardcode secrets in YAML
- keep production credentials protected
- document required secrets next to the workflow
