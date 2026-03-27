---
name: drizzle-orm
description: Drizzle ORM — type-safe SQL, schema definition, migrations, queries, relations, with Supabase/PostgreSQL.
---

# Drizzle ORM Reference

> Local repo: `repos/drizzle-orm`
> Source: `repos/drizzle-orm/drizzle-orm/src/`
> Docs: `repos/drizzle-orm/docs/`

---

## 1. Setup with Supabase PostgreSQL

```bash
npm install drizzle-orm postgres
npm install -D drizzle-kit
```

### Database Connection

```typescript
// db/index.ts
import { drizzle } from 'drizzle-orm/postgres-js'
import postgres from 'postgres'
import * as schema from './schema'

const connectionString = process.env.DATABASE_URL!

// For queries (connection pooling via Supabase)
const client = postgres(connectionString)
export const db = drizzle(client, { schema })
```

### Drizzle Config

```typescript
// drizzle.config.ts
import { defineConfig } from 'drizzle-kit'

export default defineConfig({
  schema: './db/schema.ts',
  out: './db/migrations',
  dialect: 'postgresql',
  dbCredentials: {
    url: process.env.DATABASE_URL!,
  },
})
```

---

## 2. Schema Definition

### Basic Table

```typescript
// db/schema.ts
import {
  pgTable,
  uuid,
  text,
  timestamp,
  boolean,
  integer,
  varchar,
  jsonb,
  pgEnum,
} from 'drizzle-orm/pg-core'

// Enum
export const roleEnum = pgEnum('role', ['user', 'admin', 'moderator'])

// Users table (mirrors auth.users)
export const profiles = pgTable('profiles', {
  id: uuid('id').primaryKey(), // references auth.users(id)
  email: text('email').notNull().unique(),
  fullName: text('full_name'),
  avatarUrl: text('avatar_url'),
  role: roleEnum('role').default('user').notNull(),
  stripeCustomerId: text('stripe_customer_id').unique(),
  subscriptionStatus: text('subscription_status').default('none'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
})
```

### Table with References

```typescript
export const posts = pgTable('posts', {
  id: uuid('id').primaryKey().defaultRandom(),
  title: text('title').notNull(),
  content: text('content'),
  slug: varchar('slug', { length: 255 }).notNull().unique(),
  isPublished: boolean('is_published').default(false).notNull(),
  authorId: uuid('author_id')
    .notNull()
    .references(() => profiles.id, { onDelete: 'cascade' }),
  metadata: jsonb('metadata').$type<{ tags: string[]; readTime: number }>(),
  viewCount: integer('view_count').default(0).notNull(),
  publishedAt: timestamp('published_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
})
```

### Indexes & Unique Constraints

```typescript
import { pgTable, uuid, text, index, uniqueIndex } from 'drizzle-orm/pg-core'

export const posts = pgTable(
  'posts',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    title: text('title').notNull(),
    slug: varchar('slug', { length: 255 }).notNull(),
    authorId: uuid('author_id').notNull().references(() => profiles.id),
    categoryId: uuid('category_id').references(() => categories.id),
  },
  (table) => [
    uniqueIndex('posts_slug_idx').on(table.slug),
    index('posts_author_idx').on(table.authorId),
    index('posts_category_idx').on(table.categoryId),
  ]
)
```

### Junction Table (Many-to-Many)

```typescript
export const categories = pgTable('categories', {
  id: uuid('id').primaryKey().defaultRandom(),
  name: text('name').notNull().unique(),
  slug: text('slug').notNull().unique(),
})

export const postCategories = pgTable(
  'post_categories',
  {
    postId: uuid('post_id')
      .notNull()
      .references(() => posts.id, { onDelete: 'cascade' }),
    categoryId: uuid('category_id')
      .notNull()
      .references(() => categories.id, { onDelete: 'cascade' }),
  },
  (table) => [
    // Composite primary key
    { primaryKey: { columns: [table.postId, table.categoryId] } },
  ]
)
```

---

## 3. Relations (Relational Query API)

```typescript
// db/schema.ts — define relations separately from tables
import { relations } from 'drizzle-orm'

export const profilesRelations = relations(profiles, ({ many }) => ({
  posts: many(posts),
}))

export const postsRelations = relations(posts, ({ one, many }) => ({
  author: one(profiles, {
    fields: [posts.authorId],
    references: [profiles.id],
  }),
  comments: many(comments),
  categories: many(postCategories),
}))

export const commentsRelations = relations(comments, ({ one }) => ({
  post: one(posts, {
    fields: [comments.postId],
    references: [posts.id],
  }),
  author: one(profiles, {
    fields: [comments.authorId],
    references: [profiles.id],
  }),
}))

export const postCategoriesRelations = relations(postCategories, ({ one }) => ({
  post: one(posts, {
    fields: [postCategories.postId],
    references: [posts.id],
  }),
  category: one(categories, {
    fields: [postCategories.categoryId],
    references: [categories.id],
  }),
}))
```

### Relational Queries (using `db.query`)

```typescript
// Fetch post with author and comments
const post = await db.query.posts.findFirst({
  where: eq(posts.id, postId),
  with: {
    author: true,
    comments: {
      with: {
        author: true,
      },
      orderBy: [desc(comments.createdAt)],
      limit: 20,
    },
  },
})

// Fetch all posts by a user with categories
const userPosts = await db.query.posts.findMany({
  where: eq(posts.authorId, userId),
  with: {
    categories: {
      with: {
        category: true,
      },
    },
  },
  orderBy: [desc(posts.createdAt)],
})
```

---

## 4. Queries (SQL-like API)

### SELECT

```typescript
import { eq, and, or, gt, like, desc, asc, sql, inArray, isNull, count } from 'drizzle-orm'

// Basic select
const allPosts = await db.select().from(posts)

// With conditions
const publishedPosts = await db
  .select()
  .from(posts)
  .where(eq(posts.isPublished, true))
  .orderBy(desc(posts.createdAt))
  .limit(20)
  .offset(0)

// Select specific columns
const postTitles = await db
  .select({
    id: posts.id,
    title: posts.title,
    authorName: profiles.fullName,
  })
  .from(posts)
  .innerJoin(profiles, eq(posts.authorId, profiles.id))

// Complex where
const filteredPosts = await db
  .select()
  .from(posts)
  .where(
    and(
      eq(posts.isPublished, true),
      gt(posts.viewCount, 100),
      or(
        like(posts.title, '%typescript%'),
        like(posts.title, '%react%')
      )
    )
  )

// Count
const [{ total }] = await db
  .select({ total: count() })
  .from(posts)
  .where(eq(posts.authorId, userId))

// IN clause
const specificPosts = await db
  .select()
  .from(posts)
  .where(inArray(posts.id, [id1, id2, id3]))
```

### INSERT

```typescript
// Single insert
const [newPost] = await db
  .insert(posts)
  .values({
    title: 'My Post',
    content: 'Hello world',
    slug: 'my-post',
    authorId: userId,
  })
  .returning()

// Bulk insert
const newPosts = await db
  .insert(posts)
  .values([
    { title: 'Post 1', slug: 'post-1', authorId: userId },
    { title: 'Post 2', slug: 'post-2', authorId: userId },
  ])
  .returning()

// Upsert (insert or update on conflict)
await db
  .insert(profiles)
  .values({ id: userId, email: 'user@example.com', fullName: 'Jane' })
  .onConflictDoUpdate({
    target: profiles.id,
    set: { fullName: 'Jane', updatedAt: new Date() },
  })

// Insert with conflict ignore
await db
  .insert(profiles)
  .values({ id: userId, email: 'user@example.com' })
  .onConflictDoNothing()
```

### UPDATE

```typescript
// Update by ID
const [updated] = await db
  .update(posts)
  .set({
    title: 'Updated Title',
    updatedAt: new Date(),
  })
  .where(eq(posts.id, postId))
  .returning()

// Increment
await db
  .update(posts)
  .set({
    viewCount: sql`${posts.viewCount} + 1`,
  })
  .where(eq(posts.id, postId))
```

### DELETE

```typescript
// Delete by ID
const [deleted] = await db
  .delete(posts)
  .where(eq(posts.id, postId))
  .returning()

// Delete with condition
await db
  .delete(posts)
  .where(
    and(
      eq(posts.authorId, userId),
      eq(posts.isPublished, false)
    )
  )
```

---

## 5. Joins

```typescript
// Inner join
const postsWithAuthors = await db
  .select({
    postId: posts.id,
    title: posts.title,
    authorName: profiles.fullName,
    authorEmail: profiles.email,
  })
  .from(posts)
  .innerJoin(profiles, eq(posts.authorId, profiles.id))

// Left join (posts may not have comments)
const postsWithCommentCount = await db
  .select({
    postId: posts.id,
    title: posts.title,
    commentCount: count(comments.id),
  })
  .from(posts)
  .leftJoin(comments, eq(posts.id, comments.postId))
  .groupBy(posts.id, posts.title)

// Subquery
const sq = db
  .select({
    authorId: posts.authorId,
    postCount: count().as('post_count'),
  })
  .from(posts)
  .groupBy(posts.authorId)
  .as('sq')

const authorsWithPostCount = await db
  .select({
    name: profiles.fullName,
    postCount: sq.postCount,
  })
  .from(profiles)
  .leftJoin(sq, eq(profiles.id, sq.authorId))
```

---

## 6. Migrations

### Commands

```bash
# Generate migration from schema changes
npx drizzle-kit generate

# Push schema directly to database (dev only — no migration file)
npx drizzle-kit push

# Run pending migrations
npx drizzle-kit migrate

# Introspect existing database and generate schema
npx drizzle-kit introspect

# Open Drizzle Studio (visual DB browser)
npx drizzle-kit studio
```

### Run Migrations Programmatically

```typescript
import { migrate } from 'drizzle-orm/postgres-js/migrator'
import { drizzle } from 'drizzle-orm/postgres-js'
import postgres from 'postgres'

const migrationClient = postgres(process.env.DATABASE_URL!, { max: 1 })
const db = drizzle(migrationClient)

await migrate(db, { migrationsFolder: './db/migrations' })
await migrationClient.end()
```

### Migration Workflow

```bash
# 1. Edit schema.ts
# 2. Generate migration
npx drizzle-kit generate

# 3. Review the generated SQL in db/migrations/
# 4. Apply to dev
npx drizzle-kit migrate

# 5. Apply to production (via CI or manually)
DATABASE_URL=production_url npx drizzle-kit migrate
```

---

## 7. Supabase Integration — When to Use What

### Use Drizzle When:
- Complex queries with joins, aggregations, subqueries
- Type-safe database operations in Server Components / Route Handlers
- Migrations and schema management
- Operations that bypass RLS (using service role connection)

### Use Supabase JS Client When:
- Simple CRUD operations with RLS enforcement
- Client-side data fetching (RLS handles authorization)
- Realtime subscriptions
- Storage operations
- Auth operations

### Side-by-Side Example

```typescript
// Supabase JS — simple, RLS-enforced
const { data } = await supabase
  .from('posts')
  .select('*, author:profiles(full_name)')
  .eq('is_published', true)
  .order('created_at', { ascending: false })

// Drizzle — type-safe, complex queries, no RLS
const data = await db
  .select({
    id: posts.id,
    title: posts.title,
    authorName: profiles.fullName,
    commentCount: count(comments.id),
  })
  .from(posts)
  .innerJoin(profiles, eq(posts.authorId, profiles.id))
  .leftJoin(comments, eq(posts.id, comments.postId))
  .where(eq(posts.isPublished, true))
  .groupBy(posts.id, posts.title, profiles.fullName)
  .orderBy(desc(posts.createdAt))
```

### Connect Drizzle to Supabase

Use the **direct connection** string (not the pooler) for migrations.
Use the **connection pooler** (port 6543, transaction mode) for application queries.

```
# .env
# Direct connection (migrations)
DATABASE_URL=postgresql://postgres.[ref]:[password]@aws-0-[region].pooler.supabase.com:5432/postgres

# Pooled connection (application queries)
DATABASE_POOLER_URL=postgresql://postgres.[ref]:[password]@aws-0-[region].pooler.supabase.com:6543/postgres?pgbouncer=true
```

---

## 8. Type Inference

```typescript
import { InferSelectModel, InferInsertModel } from 'drizzle-orm'

// Infer types from schema
export type Post = InferSelectModel<typeof posts>
export type NewPost = InferInsertModel<typeof posts>
export type Profile = InferSelectModel<typeof profiles>

// Usage
async function createPost(data: NewPost): Promise<Post> {
  const [post] = await db.insert(posts).values(data).returning()
  return post
}
```

---

## 9. Transactions

```typescript
const result = await db.transaction(async (tx) => {
  const [post] = await tx
    .insert(posts)
    .values({ title: 'New Post', slug: 'new-post', authorId: userId })
    .returning()

  await tx.insert(postCategories).values({
    postId: post.id,
    categoryId: categoryId,
  })

  return post
})
```

---

## 10. Raw SQL

```typescript
import { sql } from 'drizzle-orm'

// Raw query
const result = await db.execute(
  sql`SELECT * FROM posts WHERE title ILIKE ${'%search%'}`
)

// Raw in select
const postsWithRank = await db
  .select({
    id: posts.id,
    title: posts.title,
    rank: sql<number>`ts_rank(to_tsvector('english', ${posts.content}), plainto_tsquery('english', ${searchTerm}))`,
  })
  .from(posts)
  .where(
    sql`to_tsvector('english', ${posts.content}) @@ plainto_tsquery('english', ${searchTerm})`
  )
  .orderBy(sql`rank DESC`)
```
