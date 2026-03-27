# Supabase Storage Patterns

Use storage policies when the app handles uploads.

## Design questions
- who can upload?
- who can read?
- is content public or private?
- how are files linked to app rows?

## Defaults
- keep bucket purpose explicit
- link files to owning app entity when possible
- make read/write/delete rules role-aware
- avoid public buckets unless the product truly needs public assets

## Common checks
- upload path ownership
- tenant isolation
- delete permissions
- orphaned file cleanup strategy
