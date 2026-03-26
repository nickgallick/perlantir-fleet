---
name: docker-containerization
description: Docker best practices — multi-stage builds, security, Docker Compose for dev, and OpenClaw container specifics.
---

# Docker Containerization

## Review Checklist

- [ ] Running as non-root user (`USER node`)
- [ ] No secrets baked into image
- [ ] Base image pinned to specific version (not `latest`)
- [ ] `.dockerignore` excludes `.env`, `.git`, `node_modules`
- [ ] Health check configured
- [ ] Unnecessary ports not exposed
- [ ] Multi-stage build (dev deps not in production image)

---

## Multi-Stage Build (Production Pattern)

```dockerfile
# Build stage — has dev dependencies, build tools
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage — minimal image
FROM node:22-alpine
WORKDIR /app
RUN addgroup -g 1001 -S appgroup && adduser -S appuser -u 1001 -G appgroup
COPY --from=builder --chown=appuser:appgroup /app/dist ./dist
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:appgroup /app/package*.json ./
USER appuser
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/health || exit 1
CMD ["node", "dist/index.js"]
```

**Layer caching:** `COPY package*.json` before `COPY .` so `npm ci` is cached when only source changes.

## .dockerignore

```
node_modules
.git
.env
.env.local
.next
dist
*.md
.DS_Store
```

## Docker Compose (Development)

```yaml
services:
  app:
    build: .
    ports: ["3000:3000"]
    volumes: ["./src:/app/src"]
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@db:5432/arena
    depends_on:
      db: { condition: service_healthy }

  db:
    image: supabase/postgres:15.6
    ports: ["5432:5432"]
    environment:
      POSTGRES_PASSWORD: postgres
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      retries: 5
    volumes: ["pgdata:/var/lib/postgresql/data"]

volumes:
  pgdata:
```

## Security Anti-Patterns

```dockerfile
# ❌ Running as root (default)
CMD ["node", "index.js"]

# ❌ Secrets in build
COPY .env /app/.env
ENV API_KEY=sk-secret-123

# ❌ Unpinned base image
FROM node:latest

# ❌ --privileged flag
docker run --privileged myapp
```

## Sources
- Docker documentation (multi-stage builds, security)
- Node.js Docker best practices
- OpenClaw container architecture

## Changelog
- 2026-03-21: Initial skill — Docker containerization
