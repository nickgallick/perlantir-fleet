---
name: data-structures-in-practice
description: Practical data structures for production code — Map for O(1) lookups, Set for membership, trees for hierarchies, queues for job scheduling. Not LeetCode — real patterns.
---

# Data Structures in Practice

## Review Flags

- [ ] Nested `array.find()` inside `array.map()` → convert to Map (P1)
- [ ] `array.includes()` in a loop → convert to Set (P2)
- [ ] Building tree from flat data without memoization (P2)
- [ ] Sorting on every access instead of maintaining sorted structure (P2)
- [ ] Storing lookup data as array when Map is appropriate (P2)

---

## Map for O(1) Lookups (The #1 Pattern)

```ts
// ❌ O(n²) — .find() inside .map()
const enriched = orders.map(order => ({
  ...order,
  customer: customers.find(c => c.id === order.customerId) // O(n) × n times
}))

// ✅ O(n) — build Map first, then lookup
const customerMap = new Map(customers.map(c => [c.id, c]))
const enriched = orders.map(order => ({
  ...order,
  customer: customerMap.get(order.customerId) // O(1) × n times
}))
```

**When:** Any time you look up items from one array while iterating another. This is the single most impactful data structure fix in production code.

### Map vs Object
| Feature | Map | Object |
|---------|-----|--------|
| Key types | Any (string, number, object) | String/Symbol only |
| Key order | Insertion order guaranteed | Not guaranteed |
| Size | `.size` property | `Object.keys().length` |
| Performance | Optimized for frequent add/remove | Optimized for static shape |
| **Use when** | Dynamic keys, lookups | Static configuration |

## Set for Membership Testing

```ts
// ❌ O(n) per check
const processedIds = [] // array
if (processedIds.includes(id)) { ... } // O(n) scan

// ✅ O(1) per check
const processedIds = new Set<string>()
if (processedIds.has(id)) { ... } // O(1) hash lookup
```

## Trees for Hierarchical Data

### Comment Threads (Adjacency List)
```ts
// Flat data from database
type Comment = { id: string; parentId: string | null; text: string }

// Build tree structure
function buildTree(comments: Comment[]): TreeNode[] {
  const map = new Map(comments.map(c => [c.id, { ...c, children: [] as TreeNode[] }]))
  const roots: TreeNode[] = []
  
  for (const comment of map.values()) {
    if (comment.parentId) {
      map.get(comment.parentId)?.children.push(comment)
    } else {
      roots.push(comment)
    }
  }
  return roots
}
```

### Tournament Brackets (Binary Tree)
```ts
// Each match has two participants, winner advances
type Match = {
  id: string
  round: number
  position: number
  participant1?: AgentId
  participant2?: AgentId
  winner?: AgentId
}
// Total matches = N-1 for N participants
// Rounds = Math.ceil(Math.log2(N))
```

## Priority Queue for Job Scheduling

```ts
// Simple implementation for <1000 items
class PriorityQueue<T> {
  private items: { priority: number; value: T }[] = []
  
  enqueue(value: T, priority: number) {
    this.items.push({ priority, value })
    this.items.sort((a, b) => b.priority - a.priority) // highest first
  }
  
  dequeue(): T | undefined {
    return this.items.shift()?.value
  }
  
  get size() { return this.items.length }
}

// In Postgres: ORDER BY priority DESC, created_at ASC
// achieves the same for database-backed queues
```

## Ring Buffer for Sliding Windows

```ts
// Arena: last 10 challenge results for performance trend
class RingBuffer<T> {
  private buffer: (T | undefined)[]
  private head = 0
  private count = 0
  
  constructor(private capacity: number) {
    this.buffer = new Array(capacity)
  }
  
  push(item: T) {
    this.buffer[this.head] = item
    this.head = (this.head + 1) % this.capacity
    this.count = Math.min(this.count + 1, this.capacity)
  }
  
  toArray(): T[] {
    const result: T[] = []
    for (let i = 0; i < this.count; i++) {
      const idx = (this.head - this.count + i + this.capacity) % this.capacity
      result.push(this.buffer[idx]!)
    }
    return result
  }
}
```

## Sources
- system-design-primer — data structure selection
- lichess — tournament bracket implementation
- PostgreSQL documentation (B-tree, hash, GIN indexes)

## Changelog
- 2026-03-21: Initial skill — data structures in practice
