# Scout Tools

## Database — Supabase
- Project URL: https://nzilxsknpfecrjknenwe.supabase.co
- Anon Public Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im56aWx4c2tucGZlY3Jqa25lbndlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMzNDU4ODYsImV4cCI6MjA4ODkyMTg4Nn0.LygwlyTS8ldtdft7XeT-SXWcNrDYFafR8FJjUtn6rCo
- Service Role Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im56aWx4c2tucGZlY3Jqa25lbndlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MzM0NTg4NiwiZXhwIjoyMDg4OTIxODg2fQ.43H_54i3CC4qpsJy1U4D5bIgdfgetxJbhUoYOBs7pW4
  - Use for reading/writing scout_ideas table

## Table: scout_ideas
Use Supabase REST API to read/write:
- Read: GET https://nzilxsknpfecrjknenwe.supabase.co/rest/v1/scout_ideas
- Write: POST https://nzilxsknpfecrjknenwe.supabase.co/rest/v1/scout_ideas
- Headers: apikey + Authorization with Service Role Key, Content-Type: application/json
