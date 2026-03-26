# Solana & Anchor Development

## Solana Fundamentals (for comparison)

### Why Solana vs EVM
- **Throughput**: 65K+ tx/sec native (vs Ethereum 12-15)
- **Cost**: $0.00025 per tx (vs Base $0.01+, Ethereum $5+)
- **Architecture**: Parallel processing (not sequential blocks)
- **Trade-off**: Less mature ecosystem, different programming model (Rust vs Solidity)

### Key Differences from EVM
| Aspect | EVM | Solana |
|--------|-----|--------|
| Language | Solidity | Rust |
| Storage | Contract owns state | Accounts are separate from programs |
| Execution | Sequential | Parallel (Sealevel) |
| Security model | Account code + nonce | Program + signer verification |
| Gas | Per instruction | Per transaction (deterministic) |
| Composability | Internal calls | Cross-program invocation (CPI) |

## Anchor Framework

### Program Structure
```rust
use anchor_lang::prelude::*;

declare_id!("11111111111111111111111111111111");  // Program ID (like contract address)

#[program]
pub mod prediction_market {
    use super::*;

    // Instruction handlers (like smart contract functions)
    pub fn create_market(
        ctx: Context<CreateMarket>,
        question: String,
        resolution_time: i64,
    ) -> Result<()> {
        let market = &mut ctx.accounts.market;
        market.creator = ctx.accounts.creator.key();
        market.question = question;
        market.resolution_time = resolution_time;
        market.yes_shares = 0;
        market.no_shares = 0;
        Ok(())
    }

    pub fn buy_shares(
        ctx: Context<BuyShares>,
        outcome: u8,  // 0 = NO, 1 = YES
        amount: u64,
    ) -> Result<()> {
        let market = &mut ctx.accounts.market;
        require!(market.resolution_time > Clock::get()?.unix_timestamp, UnresolvedMarket);

        if outcome == 0 {
            market.no_shares += amount;
        } else {
            market.yes_shares += amount;
        }

        // Transfer USDC from user to market vault
        transfer(
            CpiContext::new(
                ctx.accounts.token_program.to_account_info(),
                Transfer {
                    from: ctx.accounts.user_ata.to_account_info(),
                    to: ctx.accounts.market_vault.to_account_info(),
                    authority: ctx.accounts.payer.to_account_info(),
                },
            ),
            amount,
        )?;

        Ok(())
    }
}

// Account types (like contract state, but external to program)
#[derive(Accounts)]
pub struct CreateMarket<'info> {
    #[account(init, payer = creator, space = 8 + 32 + 200 + 8 + 8 + 8)]  // discriminator + fields
    pub market: Account<'info, Market>,

    #[account(mut)]
    pub creator: Signer<'info>,

    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct BuyShares<'info> {
    #[account(mut)]
    pub market: Account<'info, Market>,

    #[account(mut)]
    pub user_ata: Account<'info, TokenAccount>,

    #[account(mut)]
    pub market_vault: Account<'info, TokenAccount>,

    #[account(mut)]
    pub payer: Signer<'info>,

    pub token_program: Program<'info, Token>,
}

// Data structures
#[account]
pub struct Market {
    pub creator: Pubkey,
    pub question: String,  // Note: must size-cap strings in Solana
    pub resolution_time: i64,
    pub yes_shares: u64,
    pub no_shares: u64,
}

#[error_code]
pub enum ErrorCode {
    #[msg("Market already resolved")]
    UnresolvedMarket,
}
```

### PDAs (Program Derived Addresses)
Deterministic addresses derived from program ID + seeds. No keypair needed.

```rust
pub fn create_user_vault(ctx: Context<CreateVault>, user: Pubkey) -> Result<()> {
    // Derive PDA for this user's vault
    // Same (program, seeds) = same address every time
    let vault = &mut ctx.accounts.vault;
    vault.owner = user;
    vault.balance = 0;
    Ok(())
}

#[derive(Accounts)]
#[instruction(user: Pubkey)]
pub struct CreateVault<'info> {
    #[account(
        init,
        payer = payer,
        space = 8 + 32 + 8,
        seeds = [b"vault", user.as_ref()],  // PDA seeds
        bump  // Used to find PDA (saves computation)
    )]
    pub vault: Account<'info, UserVault>,

    #[account(mut)]
    pub payer: Signer<'info>,

    pub system_program: Program<'info, System>,
}

#[account]
pub struct UserVault {
    pub owner: Pubkey,
    pub balance: u64,
}
```

### CPI (Cross-Program Invocation)
Like DELEGATECALL but safer — explicit about which accounts are accessed.

```rust
// Call another program (e.g., SPL Token transfer)
pub fn withdraw_usdc(ctx: Context<Withdraw>, amount: u64) -> Result<()> {
    // CPI to SPL Token program's transfer instruction
    transfer(
        CpiContext::new(
            ctx.accounts.token_program.to_account_info(),
            Transfer {
                from: ctx.accounts.vault_ata.to_account_info(),
                to: ctx.accounts.user_ata.to_account_info(),
                authority: ctx.accounts.vault.to_account_info(),  // PDA signs
            },
        ),
        amount,
    )?;

    Ok(())
}
```

## SPL Token Standard
Similar to ERC-20 but simpler (no approve/transferFrom, uses Associated Token Accounts).

```rust
// Mint tokens
pub fn mint_tokens(ctx: Context<MintTokens>, amount: u64) -> Result<()> {
    mint_to(
        CpiContext::new_with_signer(
            ctx.accounts.token_program.to_account_info(),
            MintTo {
                mint: ctx.accounts.mint.to_account_info(),
                to: ctx.accounts.token_account.to_account_info(),
                authority: ctx.accounts.mint_authority.to_account_info(),
            },
            &[],  // Signer seeds (if using PDA authority)
        ),
        amount,
    )?;
    Ok(())
}
```

## Testing with Anchor
```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_create_market() {
        let program = anchor_lang::parse_program_entry_point(
            &include_bytes!("target/deploy/prediction_market.so")[..]
        ).unwrap();

        // ... test execution
    }
}
```

Or use Solana test validator:
```bash
solana-test-validator --bpf-program 11111111111111111111111111111111 target/deploy/prediction_market.so
solana program deploy target/deploy/prediction_market.so
```

## Solana for Prediction Markets

### Advantages
- Cheap ($0.00025 per entry fee transaction)
- High throughput (handle 1000s of concurrent trades)
- SPL token standard is simpler than ERC-20
- Native on Serum DEX (CLOB infrastructure)

### Disadvantages
- Smaller user base than EVM
- Account model is complex (more dev overhead)
- Less mature tooling (Anchor getting better)
- Parallel execution can cause issues if not careful about account locks

**Use Solana for Agent Sparta if you want sub-cent transaction costs. Otherwise, Base is fine.**
