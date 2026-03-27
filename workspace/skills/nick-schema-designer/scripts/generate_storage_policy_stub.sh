#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/tmp/storage-policy-stub.sql}"
BUCKET="${2:-uploads}"
cat > "$OUT" <<SQL
-- Storage policy stub for bucket: $BUCKET
-- Adjust roles/paths for the actual product model

-- Example: authenticated users can upload into their own folder prefix
-- create policy "${BUCKET}_upload_own"
-- on storage.objects for insert to authenticated
-- with check (bucket_id = '$BUCKET' and (storage.foldername(name))[1] = auth.uid()::text);

-- Example: authenticated users can read their own files
-- create policy "${BUCKET}_read_own"
-- on storage.objects for select to authenticated
-- using (bucket_id = '$BUCKET' and (storage.foldername(name))[1] = auth.uid()::text);
SQL

echo "$OUT"
