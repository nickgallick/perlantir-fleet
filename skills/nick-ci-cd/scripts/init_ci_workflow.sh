#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-.github/workflows}"
mkdir -p "$OUT_DIR"
OUT="$OUT_DIR/ci.yml"
cat > "$OUT" <<'YAML'
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  test-and-build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint --if-present

      - name: Test
        run: npm test --if-present

      - name: Install Playwright browsers
        run: npx playwright install --with-deps chromium

      - name: Playwright smoke
        run: npm run test:e2e --if-present

      - name: Build
        run: npm run build

  deploy:
    needs: test-and-build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Deploy to Vercel
        run: echo 'Configure Vercel deploy command here after secrets are set'
YAML

echo "$OUT"
