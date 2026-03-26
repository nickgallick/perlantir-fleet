# CosmWasm Deep Dive

## CosmWasm Contract Structure

```rust
// Three mandatory entry points
use cosmwasm_std::{entry_point, DepsMut, Env, MessageInfo, Response, StdResult, Deps, Binary, to_json_binary};
use cw_storage_plus::{Item, Map};
use serde::{Deserialize, Serialize};

// State
const OWNER: Item<String> = Item::new("owner");
const BALANCES: Map<&str, u128> = Map::new("balances");

// Messages
#[derive(Serialize, Deserialize)]
pub enum ExecuteMsg {
    Transfer { to: String, amount: u128 },
    Burn { amount: u128 },
}

#[derive(Serialize, Deserialize)]
pub enum QueryMsg {
    Balance { address: String },
}

// 1. Constructor
#[entry_point]
pub fn instantiate(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    _msg: InstantiateMsg,
) -> StdResult<Response> {
    OWNER.save(deps.storage, &info.sender.to_string())?;
    Ok(Response::new().add_attribute("owner", info.sender))
}

// 2. State-changing
#[entry_point]
pub fn execute(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    msg: ExecuteMsg,
) -> StdResult<Response> {
    match msg {
        ExecuteMsg::Transfer { to, amount } => {
            let sender = info.sender.to_string();
            let bal = BALANCES.load(deps.storage, &sender)?;
            if bal < amount { return Err(StdError::generic_err("Insufficient balance")); }

            BALANCES.save(deps.storage, &sender, &(bal - amount))?;
            let to_bal = BALANCES.may_load(deps.storage, &to)?.unwrap_or(0);
            BALANCES.save(deps.storage, &to, &(to_bal + amount))?;

            Ok(Response::new()
                .add_attribute("action", "transfer")
                .add_attribute("from", sender)
                .add_attribute("to", to)
                .add_attribute("amount", amount.to_string()))
        },
        ExecuteMsg::Burn { amount } => {
            // Burn tokens — reduce supply
            let sender = info.sender.to_string();
            let bal = BALANCES.load(deps.storage, &sender)?;
            BALANCES.save(deps.storage, &sender, &(bal - amount))?;
            Ok(Response::new().add_attribute("action", "burn"))
        }
    }
}

// 3. Read-only
#[entry_point]
pub fn query(deps: Deps, _env: Env, msg: QueryMsg) -> StdResult<Binary> {
    match msg {
        QueryMsg::Balance { address } => {
            let bal = BALANCES.may_load(deps.storage, &address)?.unwrap_or(0);
            to_json_binary(&BalanceResponse { balance: bal })
        }
    }
}
```

## IBC Integration from CosmWasm

```rust
// Send tokens across chains via IBC
use cosmwasm_std::{CosmosMsg, IbcMsg, IbcTimeout, IbcTimeoutBlock};

fn transfer_via_ibc(
    recipient: String,
    channel: String,
    denom: String,
    amount: u128,
    env: &Env,
) -> CosmosMsg {
    CosmosMsg::Ibc(IbcMsg::Transfer {
        channel_id: channel,           // e.g., "channel-0" (Osmosis ↔ Neutron)
        to_address: recipient,
        amount: cosmwasm_std::Coin { denom, amount: amount.to_string() },
        timeout: IbcTimeout::with_block(IbcTimeoutBlock {
            revision: 1,
            height: env.block.height + 500,  // ~50 minutes on most Cosmos chains
        }),
        memo: None,
    })
}
```

## Key Safety Guarantees vs Solidity

| Risk | Solidity | CosmWasm |
|------|----------|----------|
| Reentrancy | Possible (guard required) | Impossible (actor model) |
| Integer overflow | Solidity ≥0.8 safe | Rust panics on overflow |
| Uninitialized variables | Dangerous, possible | Rust requires explicit init |
| Delegatecall footgun | Present | Not available |
| Gas griefing | Possible | Less common |

**Trade-off**: Rust's learning curve is steeper. Compilation is slower. Ecosystem smaller.

## When to Use CosmWasm vs EVM

| Choose CosmWasm | Choose EVM |
|----------------|-----------|
| Deploying on Cosmos chains | Deploying on Ethereum/Base/Arbitrum |
| Need IBC cross-chain messaging | Need EVM ecosystem liquidity |
| Want Rust type safety | Need largest developer community |
| Building on Osmosis/Injective/Neutron | Want most auditing resources |

## Osmosis / Injective / Neutron

**Osmosis**: DEX chain. Concentrated liquidity. Superfluid staking (LP tokens as validator collateral). CosmWasm for custom vaults and hooks.

**Injective**: Finance chain. Built-in order book module (no AMM needed — real limit orders). MEV-resistant (frequent batch auctions). CosmWasm for custom trading strategies.

**Neutron**: Security consumer chain. Inherits Cosmos Hub validator set. Designed for DeFi. ICA (Interchain Accounts) for cross-chain contract calls.
