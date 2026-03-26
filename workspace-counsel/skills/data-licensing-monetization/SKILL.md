# SKILL 67: Data Licensing & Monetization

## Purpose
Legally sell the data your prediction market generates. Know what data is yours to sell, what requires user consent, and how to structure licensing deals.

## What Data You CAN Sell (Low/No Risk)

| Data Type | Privacy Risk | Sellable? | Notes |
|-----------|-------------|-----------|-------|
| Aggregate market prices (OHLCV) | None — no PII | ✅ Freely | Anonymized, no individual data |
| Historical accuracy of AI models | None | ✅ Freely | Your core product's value-add |
| Aggregated crowd sentiment | None (if aggregated) | ✅ Freely | "60% of positions are on YES" |
| Resolution outcomes database | None | ✅ Freely | Public event outcomes |
| Volatility/trading volume metrics | None | ✅ Freely | Market-level stats |
| Proprietary indices/scores you create | None | ✅ Freely | Your IP |

## What Data You CANNOT Sell or Must Be Careful With

| Data Type | Restriction | Notes |
|-----------|------------|-------|
| Individual user trading history (PII-linked) | CCPA opt-out required; GDPR consent required | Can sell if user opts in; cannot sell without consent |
| Individual user identities / KYC data | NEVER | Not sellable under any circumstances |
| Individual wallet-to-position mapping | Privacy violation + potential market manipulation | Front-running risk: reveals positions |
| Real-time individual positions | Market manipulation risk | Could enable front-running by data buyers |

## Data Licensing Tiers

### API Access Structure
- **Free tier**: 15-minute delayed data, 100 API calls/day, limited history. Builds developer ecosystem.
- **Basic ($X/month)**: real-time data, 10K calls/day, 1-year history. Media, researchers, retail.
- **Pro ($X/month)**: full real-time + historical data, 100K calls/day, webhooks. Hedge funds, data aggregators.
- **Enterprise (custom pricing)**: raw data feeds, custom queries, dedicated engineering support, SLA. Institutional clients.

### Pricing Reference Points
- Bloomberg Terminal: ~$2,000/month/user for financial data
- Quandl/Nasdaq Data Link: $50–500/month for alternative data
- AI benchmark data (novel): price is what the market will bear. Start at $500/month Pro.

## API Terms of Service — Required Provisions
- **Permitted use**: display, analysis, building applications that consume but don't redistribute raw data
- **Prohibited uses**: redistribution (licensee cannot resell your data), scraping for a competing platform, using to build a competing data product, manipulation (using your data to execute market manipulation)
- **Attribution**: "Source: [Platform Name]" required on all published uses of your data
- **Rate limits**: enforce technically AND in the terms
- **Data accuracy**: "provided as-is, no warranty of accuracy or completeness or timeliness"
- **Liability cap**: licensee's remedy for data errors limited to fees paid in the prior month
- **Indemnification**: licensee indemnifies you for their use of the data
- **Termination**: you can revoke access at any time; licensee has 30 days to destroy data

## Intellectual Property in Market Data

### What Is Copyrightable
- Raw prices/volumes: generally NOT copyrightable (*Feist Publications v. Rural Telephone Service*, 1991 — facts are not copyrightable)
- **Curated/compiled datasets**: potentially copyrightable as a compilation if there's creative selection and arrangement
- **Proprietary indices and metrics you create** (e.g., "AI Prediction Accuracy Score"): copyrightable expression, potentially patentable method
- **Your AI accuracy database**: protectable as a trade secret (reasonable measures to keep it secret + economic value from secrecy)

### EU Database Rights
- Sui generis database right under EU Database Directive (96/9/EC)
- Protects substantial investment in obtaining, verifying, or presenting database contents
- 15-year protection from completion
- Relevant if you serve EU users — another reason to have EU users eventually

## Revenue Potential
| Customer Type | Monthly Value | Data Product |
|-------------|--------------|-------------|
| AI lab (Anthropic, OpenAI, Google) | $5K–$50K/month | AI prediction accuracy benchmarks, calibration data |
| Hedge fund | $2K–$20K/month | Aggregated crowd sentiment, accuracy metrics |
| Media organization | $500–$5K/month | Real-time market prices, resolution data |
| Academic researcher | Free–$500/month | Historical data access |
| Retail developer (API) | $50–$500/month | Free/Basic tier |

This revenue stream has minimal regulatory risk — you're selling data, not operating a market.

---
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
