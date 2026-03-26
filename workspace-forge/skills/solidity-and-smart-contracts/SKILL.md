---
name: solidity-and-smart-contracts
description: Solidity development — language fundamentals, security vulnerabilities (reentrancy, overflow, access control, front-running, DoS), gas optimization, testing, upgradability.
---

# Solidity & Smart Contracts

## Review Checklist

- [ ] Reentrancy: state updated BEFORE external calls (Checks-Effects-Interactions) (P0)
- [ ] Access control on every state-modifying function (P0)
- [ ] `tx.origin` not used for auth (P0)
- [ ] No unbounded loops (P0 — can brick the contract)
- [ ] OpenZeppelin used for standards (ERC-20, ERC-721, Ownable) (P1)
- [ ] Storage reads cached in local variables (P2 — gas optimization)
- [ ] Events emitted for all significant state changes (P2)

---

## Arena Coins Contract (ERC-20)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ArenaCoins is ERC20, Ownable {
    constructor() ERC20("Arena Coins", "ARENA") Ownable(msg.sender) {
        _mint(msg.sender, 1_000_000 * 10**decimals());
    }
    
    function reward(address winner, uint256 amount) external onlyOwner {
        _mint(winner, amount);
    }
}
```

## Security Vulnerabilities

### Reentrancy (#1 Vulnerability — The DAO: $60M stolen)

```solidity
// ❌ VULNERABLE: state updated AFTER external call
function withdraw() external {
    uint256 bal = balances[msg.sender];
    (bool ok, ) = msg.sender.call{value: bal}(""); // attacker re-enters here
    require(ok);
    balances[msg.sender] = 0; // too late — already re-entered
}

// ✅ SAFE: Checks-Effects-Interactions + ReentrancyGuard
function withdraw() external nonReentrant {
    uint256 bal = balances[msg.sender];
    require(bal > 0, "No balance");          // CHECK
    balances[msg.sender] = 0;                // EFFECT (before call)
    (bool ok, ) = msg.sender.call{value: bal}(""); // INTERACTION
    require(ok, "Transfer failed");
}
```

### Access Control
```solidity
// ❌ No access control — anyone can mint
function mint(address to, uint256 amount) external {
    _mint(to, amount);
}

// ❌ tx.origin for auth — phishing attack vector
function withdraw() external {
    require(tx.origin == owner); // attacker tricks owner into calling their contract
}

// ✅ msg.sender + OpenZeppelin Ownable
function mint(address to, uint256 amount) external onlyOwner {
    _mint(to, amount);
}
```

### Front-Running
Attackers see pending transactions in mempool, submit their own with higher gas.
- **Mitigations:** commit-reveal schemes, batch auctions, Flashbots (private tx submission)
- **Relevant for:** auctions, DEX trades, any ordering-dependent operation

### Denial of Service
```solidity
// ❌ Unbounded loop — if winners array grows large, exceeds gas limit → contract bricked
function distributeRewards() external {
    for (uint i = 0; i < winners.length; i++) { // could be 10,000+ entries
        payable(winners[i]).transfer(rewardAmount);
    }
}

// ✅ Pull-over-push: users claim their own rewards
mapping(address => uint256) public pendingRewards;

function claimReward() external {
    uint256 amount = pendingRewards[msg.sender];
    require(amount > 0);
    pendingRewards[msg.sender] = 0;
    payable(msg.sender).transfer(amount);
}
```

## Gas Optimization

| Optimization | Savings | Why |
|-------------|---------|-----|
| `uint256` over `uint8` | ~3% | EVM operates on 256-bit words |
| Pack struct fields | ~50% storage | Two `uint128` fit in one 32-byte slot |
| `calldata` over `memory` | ~10% | Read-only, no copy needed |
| Events over storage | ~95% | Logs are 375 gas vs SSTORE 20,000 gas |
| Cache storage reads | ~2,100 gas/read | Each SLOAD costs 2,100 gas |
| Mappings over arrays | O(1) vs O(n) | For lookups |

## Testing

```bash
# Foundry (recommended — fast, Solidity-native)
forge test                    # run all tests
forge test --match-test testReward -vvv  # verbose specific test
forge fuzz                    # randomized input testing

# Hardhat (JS/TS ecosystem)
npx hardhat test
```

## Upgradability (Proxy Patterns)

| Pattern | How | Use When |
|---------|-----|----------|
| UUPS | Upgrade logic in implementation | Default choice |
| Transparent | Upgrade logic in proxy | When admin != user separation matters |
| Beacon | Multiple proxies share one impl | Many instances of same contract |
| Diamond (EIP-2535) | Modular facets | Contract exceeds 24KB limit |

**Rule:** Use UUPS for most cases. Always use OpenZeppelin's upgradeable contracts.

## Sources
- ethereum/solidity documentation
- OpenZeppelin/openzeppelin-contracts
- foundry-rs/foundry
- Trail of Bits smart contract security guidelines
- The DAO hack analysis

## Changelog
- 2026-03-21: Initial skill — Solidity and smart contracts
