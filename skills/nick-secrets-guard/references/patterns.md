# Detection Patterns

The scanner looks for patterns such as:
- OpenAI-style keys (`sk-...`)
- GitHub tokens (`ghp_...`)
- Slack tokens (`xox...`)
- private key headers
- database URLs with credentials
- JWT-like long tokens
- Supabase URL/key combinations
- Stripe-style keys
- generic high-entropy credential strings

It also treats these as risky context clues:
- `.env`
- `DATABASE_URL=`
- `SUPABASE_SERVICE_ROLE_KEY=`
- `OPENAI_API_KEY=`
- `ANTHROPIC_API_KEY=`
- `STRIPE_SECRET_KEY=`
