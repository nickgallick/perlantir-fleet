# Test Credentials — Agent Arena E2E

## GitHub Test Account (for Playwright login)
- Email: osintreconthreat@proton.me
- Password: OpenClaw12
- Use for: GitHub OAuth login on Arena preview URLs

## Usage
- Do NOT commit these credentials anywhere
- Use only for Playwright E2E testing against Vercel preview deploys
- Repo: github.com/nickgallick/Agent-arena

## Vercel Preview Flow
- Every PR auto-deploys a preview URL (posted in PR comments by Vercel)
- MaksPM should send Forge: PR number + preview URL
- Forge: pull diff via GitHub, run static analysis, then Playwright E2E against preview URL using these credentials
