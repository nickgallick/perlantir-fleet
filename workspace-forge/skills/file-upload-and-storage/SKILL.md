---
name: file-upload-and-storage
description: File upload security, Supabase Storage patterns, presigned URLs, file validation, CDN caching, and storage architecture for Arena/MathMind/OUTBOUND.
---

# File Upload & Storage

## Review Checklist

1. [ ] File type validated by magic bytes (not extension)
2. [ ] File size limit enforced server-side
3. [ ] Large uploads use presigned URLs (not through API)
4. [ ] Private files use signed download URLs with expiration
5. [ ] Filenames sanitized (no special chars, no path traversal)
6. [ ] RLS policies on storage bucket match business rules
7. [ ] Retention policy exists for old files

---

## File Validation (CRITICAL)

```ts
// NEVER trust file extensions — validate magic bytes
const MAGIC_BYTES: Record<string, number[]> = {
  'image/jpeg': [0xFF, 0xD8, 0xFF],
  'image/png': [0x89, 0x50, 0x4E, 0x47],
  'image/webp': [0x52, 0x49, 0x46, 0x46], // RIFF header
  'application/pdf': [0x25, 0x50, 0x44, 0x46], // %PDF
  'application/gzip': [0x1F, 0x8B],
}

function validateFileType(buffer: ArrayBuffer, allowedTypes: string[]): string | null {
  const bytes = new Uint8Array(buffer.slice(0, 8))
  
  for (const type of allowedTypes) {
    const magic = MAGIC_BYTES[type]
    if (magic && magic.every((b, i) => bytes[i] === b)) {
      return type
    }
  }
  return null // Invalid file type
}

// Filename sanitization
function sanitizeFilename(name: string): string {
  return name
    .replace(/[^a-zA-Z0-9._-]/g, '_') // strip special chars
    .replace(/\.{2,}/g, '.') // no double dots (path traversal)
    .slice(0, 100) // max length
}
```

## Presigned Upload URLs

```ts
// Server: generate presigned upload URL
'use server'
export async function getUploadUrl(filename: string, contentType: string) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return { error: 'Unauthorized' }
  
  const safeName = sanitizeFilename(filename)
  const path = `${user.id}/${crypto.randomUUID()}-${safeName}`
  
  const { data, error } = await supabase.storage
    .from('uploads')
    .createSignedUploadUrl(path)
  
  if (error) return { error: 'Upload failed' }
  return { signedUrl: data.signedUrl, path }
}

// Client: upload directly to storage (bypasses your server)
const { signedUrl, path } = await getUploadUrl(file.name, file.type)
await fetch(signedUrl, {
  method: 'PUT',
  body: file,
  headers: { 'Content-Type': file.type },
})
```

## Supabase Storage Architecture (Arena)

```
Buckets:
├── avatars/          (public)  — agent profile images
│   └── {agent_id}.webp
├── transcripts/      (private) — challenge session transcripts
│   └── {challenge_id}/{entry_id}.json.gz
├── submissions/      (private) — challenge submission files
│   └── {challenge_id}/{entry_id}/
└── exports/          (private) — generated reports, replays
    └── {user_id}/{export_id}.json
```

```sql
-- RLS: users can upload to their own avatar path
CREATE POLICY "avatar_upload" ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = (select auth.uid())::text
);

-- RLS: users can read own transcripts + transcripts for challenges they entered
CREATE POLICY "transcript_read" ON storage.objects FOR SELECT
USING (
  bucket_id = 'transcripts'
  AND EXISTS (
    SELECT 1 FROM entries
    WHERE entries.agent_id IN (
      SELECT id FROM agents WHERE user_id = (select auth.uid())
    )
    AND (storage.foldername(name))[1] = entries.challenge_id::text
  )
);
```

## Signed Download URLs (Private Files)

```ts
// Generate temporary access URL (expires in 1 hour)
const { data } = await supabase.storage
  .from('transcripts')
  .createSignedUrl(`${challengeId}/${entryId}.json.gz`, 3600)

// Return signed URL to client — works for 1 hour, then expires
```

## Cache-Control Headers

| Bucket | Cache-Control | Why |
|--------|--------------|-----|
| avatars | `max-age=86400` (24h) | Changes rarely |
| transcripts | `no-cache` during judging, `immutable` after | Changes during challenge, permanent after |
| submissions | `immutable` | Never changes after submission |

## Sources
- Supabase Storage documentation
- OWASP File Upload Cheat Sheet
- Supabase storage RLS patterns

## Changelog
- 2026-03-21: Initial skill — file upload and storage
