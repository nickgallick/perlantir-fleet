---
name: search-implementation
description: Search implementation — Postgres FTS, fuzzy search with pg_trgm, vector search with pgvector, search UX patterns, and when to use external search.
---

# Search Implementation

## Review Checklist

1. [ ] GIN index on tsvector columns
2. [ ] Search input debounced (300ms, not every keystroke)
3. [ ] SQL injection prevented (parameterized queries)
4. [ ] Empty and no-results states handled
5. [ ] Search queries logged for analytics

---

## Postgres Full-Text Search (Start Here)

```sql
-- Generated tsvector column (auto-updates)
ALTER TABLE challenges ADD COLUMN search_vector tsvector
  GENERATED ALWAYS AS (
    setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(description, '')), 'B')
  ) STORED;

-- GIN index (makes search fast)
CREATE INDEX idx_challenges_search ON challenges USING GIN (search_vector);

-- Search query with ranking
SELECT id, title, ts_rank(search_vector, query) as rank
FROM challenges, plainto_tsquery('english', 'speed coding challenge') query
WHERE search_vector @@ query
ORDER BY rank DESC
LIMIT 20;
```

**Supabase JS:**
```ts
const { data } = await supabase
  .from('challenges')
  .select('id, title, description')
  .textSearch('search_vector', searchTerm, { type: 'websearch' })
  .order('created_at', { ascending: false })
  .limit(20)
```

**When Postgres FTS is enough:** <100K documents, simple keyword matching, no typo tolerance needed. This covers Arena MVP and most B2B use cases.

## Fuzzy Search (pg_trgm)

```sql
-- Enable extension
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Trigram index for fuzzy matching
CREATE INDEX idx_agents_name_trgm ON agents USING GIN (agent_name gin_trgm_ops);

-- Fuzzy search: finds "devin" when user types "devn"
SELECT agent_name, similarity(agent_name, 'devn') as sim
FROM agents
WHERE similarity(agent_name, 'devn') > 0.3
ORDER BY sim DESC
LIMIT 10;

-- Autocomplete with typo tolerance
SELECT agent_name FROM agents
WHERE agent_name % 'scra'  -- % operator uses similarity threshold
ORDER BY similarity(agent_name, 'scra') DESC
LIMIT 5;
```

## Vector Search (pgvector — Semantic)

```sql
-- Enable extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Add embedding column
ALTER TABLE challenges ADD COLUMN embedding vector(1536);

-- Generate embedding on insert (via Edge Function)
-- Use Anthropic/OpenAI embedding API → store result

-- Similarity search
SELECT id, title, 1 - (embedding <=> query_embedding) as similarity
FROM challenges
ORDER BY embedding <=> query_embedding
LIMIT 10;

-- Hybrid: keyword + semantic
SELECT id, title,
  ts_rank(search_vector, fts_query) * 0.5 + 
  (1 - (embedding <=> query_embedding)) * 0.5 as combined_score
FROM challenges, plainto_tsquery('english', $1) fts_query
WHERE search_vector @@ fts_query
ORDER BY combined_score DESC
LIMIT 20;
```

## Search UX Patterns

```tsx
// Debounced search with loading state
function useSearch(table: string) {
  const [query, setQuery] = useState('')
  const [results, setResults] = useState([])
  const [loading, setLoading] = useState(false)
  
  const debouncedSearch = useMemo(
    () => debounce(async (term: string) => {
      if (term.length < 2) { setResults([]); return }
      setLoading(true)
      const { data } = await supabase
        .from(table)
        .select('*')
        .textSearch('search_vector', term, { type: 'websearch' })
        .limit(20)
      setResults(data ?? [])
      setLoading(false)
    }, 300),
    [table]
  )
  
  useEffect(() => { debouncedSearch(query) }, [query])
  
  return { query, setQuery, results, loading }
}
```

## When to Use External Search

| Feature | Postgres FTS | Meilisearch | Algolia |
|---------|:----------:|:-----------:|:-------:|
| Typo tolerance | ❌ (need pg_trgm) | ✅ Built-in | ✅ Built-in |
| Faceted search | Manual | ✅ Built-in | ✅ Built-in |
| Search analytics | Manual | ✅ | ✅ |
| Scale (10M+ docs) | ⚠️ Degrades | ✅ | ✅ |
| Cost | Free | Free (self-host) | $$$  |
| **Arena MVP** | **✅ Use this** | Evaluate at scale | Overkill |

## Sources
- PostgreSQL full-text search documentation
- pgvector documentation
- meilisearch documentation (external search reference)
- Supabase textSearch API

## Changelog
- 2026-03-21: Initial skill — search implementation
