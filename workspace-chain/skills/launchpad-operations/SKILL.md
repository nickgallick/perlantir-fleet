# Launchpad Operations

## Pump.fun (Solana)

```
Create a token (no coding):
1. Go to pump.fun → Connect wallet → Create coin
2. Fill: Name, Ticker, Description, Image
3. Optional: Twitter, Telegram, Website (adds legitimacy)
4. Deploy cost: ~0.02 SOL

Bonding curve mechanics:
- Price = reserve_sol / (total_supply - circulating_supply)
- Every buy increases price, every sell decreases it
- Graduation at ~$69K market cap → migrates to Raydium automatically
- Creator gets first buy at launch (visible on-chain)

What the community watches:
- Dev buy %: how many tokens did creator buy? >5% = suspicious
- Holder distribution: 10 wallets holding 80% = caution
- Social links: no Twitter/Telegram = higher rug risk
- Top holder list: if creator held = will they dump?
```

## PinkSale Presale (EVM)

```
Setup checklist:
□ Deploy token contract (verified on Etherscan)
□ Connect wallet at pinksale.finance
□ Create → Standard Launchpad

Configuration:
  Presale Rate:     tokens per 1 ETH/BNB (e.g., 500,000)
  Soft Cap:         minimum ETH to succeed (e.g., 5 ETH)
  Hard Cap:         maximum ETH (e.g., 20 ETH)
  Min contribution: minimum per wallet (e.g., 0.1 ETH)
  Max contribution: maximum per wallet (e.g., 2 ETH)
  Presale Start:    exact UTC timestamp
  Presale End:      exact UTC timestamp
  Liquidity %:      % of raised ETH added to DEX (minimum 51%)
  Lock Duration:    how long LP is locked (minimum 30 days, 365+ recommended)
  
□ Approve PinkSale contract to spend your tokens
□ Pay listing fee (~0.5-1 BNB on BSC, varies)
□ Finalize and share presale link

What happens on success (softcap met):
  1. PinkSale creates Uniswap/PancakeSwap liquidity pool
  2. LP tokens locked automatically for your specified duration
  3. Contributors can claim tokens immediately
  4. You receive the remaining ETH (raised - liquidity portion)
  
Refund on failure (softcap not met):
  - Contributors can claim refund via PinkSale interface
  - Unsold tokens returned to you
```

## DxSale (Alternative EVM Launchpad)

```
Similar to PinkSale but different fee structure:
- No platform fee for basic presale
- Charges 2% of raised funds on success
- Supports: Ethereum, BSC, Polygon, Arbitrum, Base
- FairLaunch option: no presale, everyone buys at same price at launch
```

## Base-Specific Platforms

```
Virtuals Protocol (AI agent tokens):
- For tokens tied to AI agents
- Deploy via virtuals.io → Create Agent → Attach Token
- Bonding curve similar to Pump.fun but for AI agent economy
- VIRTUAL token required for initial liquidity
- Graduated tokens list on Aerodrome DEX

Clanker (Farcaster-native):
- Deploy tokens directly from Farcaster posts
- @clanker mention in a Farcaster cast = token deployed automatically
- Token name/ticker from the cast content
- Integrated with Warpcast for social distribution
- Auto-listed on Uniswap V3 on Base

Aerodrome DEX (liquidity):
- Not a launchpad but where Base tokens list post-graduation
- ve(3,3) model: lock AERO tokens to vote on gauge emissions
- Gauge = liquidity incentive for a specific pool
- Bribes: protocols pay veAERO holders to direct emissions to their pool
- Strategy: acquire veAERO → bribe yourself → your pool gets emissions → cheaper liquidity
```

## Post-Launch DEX Visibility

```
DEXScreener (gets traffic automatically):
- Auto-indexes all DEX pairs
- "Trending" section = massive visibility (organic or paid boost)
- Paid boost: $500-5,000 for 6-48 hours on trending
- Profile update: add logo, social links via dexscreener.com/update-token-info

DEXTools:
- Similar to DEXScreener, more popular on Ethereum
- Update token info: dextools.io/app/ether/pair-explorer/PAIR_ADDRESS
- "Hot Pairs" section = high traffic

CoinGecko (apply week 1):
- URL: coingecko.com/en/coins/add_new_coin
- Requirements: active trading pair, website, social links
- Timeline: 1-7 days
- Creates "legitimacy signal" buyers look for

CoinMarketCap:
- More selective than CoinGecko
- Apply: coinmarketcap.com/request_new_data
- Timeline: 3-14 days
- Optional: pay for "Fast Track" ($500)
```
