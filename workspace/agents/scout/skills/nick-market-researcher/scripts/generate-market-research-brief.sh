#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/market-research-brief.md}"
IDEA="${2:-idea}"
cat > "$OUT" <<MD
# Market Research Brief: $IDEA

- Niche:
- Buyer:
- Pain evidence:
- Alternatives:
- Gap:
- Monetization:
- Recommendation:
MD

echo "$OUT"
