# SKILL 45: AI Provider Acceptable Use Policies

## Purpose
Understand the TOS/AUP of every AI provider Perlantir depends on. Know what triggers account termination, what requires enterprise approval, and how to architect for provider redundancy.

## Anthropic (Claude) — Primary Provider

### Current AUP Restrictions (verify at anthropic.com/legal/aup before building)
- **Gambling and betting**: historically restricted/requires approval for gambling-related applications
- **Financial advice**: Claude should not provide personalized financial advice
- **High-stakes automated decisions**: using Claude as SOLE decision-maker for financial outcomes may require Anthropic approval
- **Illegal activity facilitation**: cannot enable prohibited activities in target jurisdiction
- **Deceptive content**: cannot generate misleading claims about real people/events

### Pre-Launch Required Actions
1. Contact Anthropic sales/partnerships BEFORE building gambling-adjacent or financial-decision features
2. Explain the specific use case in writing
3. Get WRITTEN approval — verbal "that should be fine" from a sales rep is not binding
4. Enterprise agreement can include custom terms that override standard AUP
5. Document the approval and keep it in your legal files

### Risk of Termination
- Platform dependency on a single provider = existential business risk
- Termination scenario: entire platform goes dark, every agent stops working
- Anthropic has terminated accounts with limited notice for AUP violations

### Mitigation: Provider Redundancy Architecture
- Design ALL AI calls behind an abstraction layer (single interface, swappable backends)
- Primary: Anthropic Claude (enterprise agreement, custom terms)
- Fallback: OpenAI GPT-4o (separate enterprise agreement)
- Emergency: self-hosted Mistral (Apache 2.0, no use restrictions)
- Target: swap to fallback provider within 24 hours without product rewrite

## OpenAI (GPT) — Backup Provider
- Similar AUP restrictions on gambling, financial advice, high-stakes decisions
- Has been MORE aggressive about enforcement and account termination with less warning
- Key restriction: "activities requiring professional licenses (legal, medical, financial)"
- Prediction market scoring could trigger this
- Enterprise agreement available; negotiate custom terms explicitly authorizing use case

## Google (Gemini) — Alternative
- Restricted uses: gambling, financial services without compliance
- Generally less restrictive than OpenAI, more than open-source
- Enterprise terms available via Google Cloud
- Vertex AI provides enterprise-grade terms with explicit compliance representations

## Open-Source Models — Last Resort / Emergency Fallback
| Model | License | Commercial Use | Use Restrictions |
|-------|---------|----------------|-----------------|
| Mistral 7B/8x7B | Apache 2.0 | ✅ Unlimited | None |
| Llama 3 | Meta Community License | ✅ (< 700M MAU) | Some restrictions |
| Phi-3 (Microsoft) | MIT | ✅ Unlimited | None |
| Falcon | Apache 2.0 | ✅ Unlimited | None |

- Self-hosting eliminates provider termination risk entirely
- Trade-off: lower capability than frontier models (narrowing gap as of 2025-2026)
- Best for: fallback/emergency use, deterministic scoring tasks, high-volume/low-complexity operations

## Strategic Architecture Principle
Never build a business that dies if one API provider terminates you.
This is as important as database redundancy and uptime SLAs.

---
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
