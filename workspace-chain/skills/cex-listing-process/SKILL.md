# CEX Listing Process

## Tier 1 Exchanges — Requirements & Timeline

### Binance
- **Apply**: binance.com/en/my/coin-apply
- **Requirements**: Working product + users, reputable audit (Certik/Trail of Bits), $1M+ daily DEX volume, active community, legal opinion letter, $50M+ market cap
- **Timeline**: 3-12 months, highly selective
- **Insider path**: Binance Labs investment, BNB Chain project, or partner referral
- **Listing fee**: Officially $0 but projects typically commit $1-5M in market-making liquidity
- **Innovation Zone**: Lower bar, path to main listing. Apply via same form.

### Coinbase
- **Apply**: coinbase.com/assethub → "List an Asset"
- **Timeline**: 3-6 months minimum; legal review is the bottleneck
- **Key differentiator**: US regulatory compliance is paramount. They evaluate securities risk first.
- **Coinbase Ventures**: investment dramatically speeds listing
- **Technical requirements**: ERC-20 or documented standard, verified contract, explorer link
- **Coinbase Wallet vs Exchange**: Wallet listing is automatic for verified ERC-20. Exchange listing requires full review.

### OKX / Bybit / HTX (Tier 1.5)
- **Apply**: OKX via okx.com/token-listing, Bybit via partner portal
- **Requirements**: Looser than Binance — $10M+ market cap, 3-6 months history, working product
- **Timeline**: 1-3 months
- **Fee**: OKX typically $100-500K listing fee depending on tier

## Tier 2 Exchanges — Faster Path

### KuCoin
- **Apply**: kumex.com/docs/en-us/apply_listing
- **Requirements**: $5M+ market cap, functioning product, audit preferred
- **Timeline**: 4-8 weeks
- **Fee**: $50-150K typical

### MEXC / Gate.io
- **Community voting**: Submit to community vote. High vote count = fast listing.
- **Timeline**: 2-4 weeks if community vote succeeds
- **Fee**: $10-50K for fast track; free if community vote wins organically

## Market Maker Requirements

Most exchanges require a designated market maker (DMM):

```
What they provide:
  - Tight bid-ask spreads (e.g., <0.5% for Tier 1)
  - Minimum depth on both sides ($50K-$500K per side)
  - 24/7 uptime (>99% for Tier 1 requirements)

Cost structure:
  - Token loan: borrow 1-5% of circulating supply to provide liquidity
  - Monthly fee: $10-50K/month
  - Setup fee: $50-100K one-time

Top market makers (contact them early):
  - Wintermute: wintermute.com/market-making
  - GSR: gsr.io
  - Amber Group: ambergroup.io
  - DWF Labs: dfwlabs.com (also invests — can accelerate listings)
  - Kairon Labs: kairon.io (smaller projects)
```

## CoinGecko / CoinMarketCap Listing

**Do this in Week 1** — free, gives project credibility:

```
CoinGecko:
  - Apply: coingecko.com/en/coins/add_new_coin
  - Requirements: contract address, exchange listing, working website, social links
  - Timeline: 1-7 days

CoinMarketCap:
  - Apply: coinmarketcap.com/request_new_data
  - Requirements: same as CoinGecko
  - Timeline: 3-14 days
  - CMC is more selective — may require exchange listing first

DEXScreener / DEXTools:
  - Automatic after first trade on a supported DEX
  - "Trending" on DEXScreener = major visibility boost
  - Boost (paid): $500-5000 for trending placement
```

## Technical Exchange Integration Checklist

```
Before submitting to any exchange:

□ Contract verified on block explorer
□ Contract is not upgradeable (or clearly documented upgrade path)
□ No mint function (or clearly documented with hard cap)
□ Token transfers work correctly (test ERC-20 transfer, approve, transferFrom)
□ Decimals: 18 for standard tokens, 6 for stablecoins
□ Symbol: short, unique, no conflicts with existing tokens
□ Token name: matches marketing everywhere
□ Total supply: fixed and documented
□ Explorer URL: etherscan.io, basescan.org, etc.
□ Deposit/withdrawal test: exchange ops will test before going live

Provide to exchange:
□ Contract address (verified)
□ Token standard (ERC-20)
□ Decimal places
□ Total supply
□ Circulating supply
□ Block explorer link
□ GitHub repo (if open source)
□ Audit report PDF
□ Whitepaper / one-pager
□ Website, Twitter, Telegram, Discord
□ Team information (or KYC status)
□ Tokenomics document
```
