# Vyper Mastery

## Why Vyper Exists
Solidity optimizes for expressiveness. Vyper optimizes for auditability. Every design decision in Vyper is "make it impossible to hide bugs."

Deliberate restrictions:
- **No inheritance** — every contract is self-contained. No hunting through 6 base contracts to find where `transfer()` is defined.
- **No inline assembly** — no hidden low-level tricks. What you see is what executes.
- **No function overloading** — one function name = one behavior. No ambiguity.
- **No operator overloading** — `+` always means addition, never "concatenate" depending on context.
- **Bounded loops only** — `for i in range(100):` not `while(condition)`. Gas costs are predictable.
- **Integer overflow protection** — built in since v0.1.0 (Solidity only added this in 0.8.0)

## Vyper Syntax

### Basic Contract Structure
```vyper
# @version 0.3.10

# State variables
owner: public(address)
balances: public(HashMap[address, uint256])
totalSupply: public(uint256)

# Events
event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    amount: uint256

# Constructor
@deploy
def __init__(_owner: address):
    self.owner = _owner

# External function (callable from outside)
@external
def transfer(_to: address, _amount: uint256) -> bool:
    assert self.balances[msg.sender] >= _amount, "Insufficient balance"
    self.balances[msg.sender] -= _amount
    self.balances[_to] += _amount
    log Transfer(msg.sender, _to, _amount)
    return True

# View function
@external
@view
def getBalance(_addr: address) -> uint256:
    return self.balances[_addr]

# Internal function (not callable externally)
@internal
def _mint(_to: address, _amount: uint256):
    self.balances[_to] += _amount
    self.totalSupply += _amount
```

### Decorators
```vyper
@external      # Callable from outside (like Solidity's external)
@internal      # Only callable within this contract
@view          # Read-only (like Solidity's view)
@pure          # No state access (like Solidity's pure)
@payable       # Can receive ETH
@nonreentrant("lock_name")  # Reentrancy guard (uses storage key "lock_name")
```

### Data Types
```vyper
# Value types
x: uint256         # unsigned 256-bit
y: int256          # signed 256-bit
z: address         # 20-byte address
b: bool            # boolean
bs: bytes32        # fixed bytes
s: String[100]     # string with max length 100

# Collections
m: HashMap[address, uint256]            # mapping
nested: HashMap[address, HashMap[address, uint256]]  # nested mapping
arr: DynArray[uint256, 100]             # dynamic array, max 100 elements
fixed: uint256[10]                      # fixed-size array

# Structs
struct Position:
    size: uint256
    entryPrice: uint256
    isLong: bool

pos: Position
pos.size = 100
```

### Interfaces
```vyper
interface ERC20:
    def transfer(_to: address, _amount: uint256) -> bool: nonpayable
    def balanceOf(_addr: address) -> uint256: view
    def approve(_spender: address, _amount: uint256) -> bool: nonpayable

# Use interface
@external
def transferTokens(_token: address, _to: address, _amount: uint256):
    success: bool = ERC20(_token).transfer(_to, _amount)
    assert success, "Transfer failed"
```

### Reentrancy Guard
```vyper
# Vyper's @nonreentrant is a decorator — simpler than Solidity's modifier
@external
@nonreentrant("withdraw_lock")
def withdraw(_amount: uint256):
    assert self.balances[msg.sender] >= _amount
    self.balances[msg.sender] -= _amount  # Effect before interaction
    send(msg.sender, _amount)             # Interaction last (CEI)
```

## The 2023 Curve Exploit — Compiler Bug

**CRITICAL**: The Curve $70M exploit was NOT a logic bug — it was a COMPILER BUG.

Vyper versions 0.2.15, 0.2.16, 0.3.0 had a broken reentrancy guard implementation. The `@nonreentrant` decorator failed to properly set/check the guard in certain contexts, allowing reentrant calls.

```vyper
# This code LOOKS safe — @nonreentrant should protect it
@external
@nonreentrant("lock")
def remove_liquidity(amount: uint256) -> uint256[2]:
    # ... some operations ...
    raw_call(msg.sender, b"", value=eth_amount)  # In vulnerable versions,
    # the reentrancy guard wasn't properly set here
    # ... more state updates ...
```

**Lesson**: When auditing Vyper code, you MUST check the compiler version. The code can be correct but the compilation can be wrong.

Always verify: `# @version X.X.X` at top of file, then check that version against known vulnerability list.

Known vulnerable versions: 0.2.15, 0.2.16, 0.3.0 (broken reentrancy locks)

## Modules (Vyper 0.4+)

Vyper's answer to inheritance — importable, composable modules:

```vyper
# ownable.vy module
owner: address

@deploy
def __init__():
    self.owner = msg.sender

@internal
def _check_owner():
    assert msg.sender == self.owner, "Not owner"

@external
def transfer_ownership(_new_owner: address):
    self._check_owner()
    self.owner = _new_owner
```

```vyper
# my_contract.vy — using the module
import ownable

uses: ownable

@deploy
def __init__():
    ownable.__init__()

@external
def admin_function():
    ownable._check_owner()
    # ... admin logic
```

## Testing with Titanoboa

Titanoboa is Vyper's native testing framework — pure Python, fast, no compiling to Solidity.

```python
import boa

def test_transfer():
    # Deploy contract
    contract = boa.load("token.vy")

    # Set up accounts
    alice = boa.env.generate_address()
    bob = boa.env.generate_address()

    # Fund alice
    contract.eval(f"self.balances[{alice}] = 1000")

    # Test transfer
    with boa.env.prank(alice):
        contract.transfer(bob, 100)

    assert contract.balances(bob) == 100
    assert contract.balances(alice) == 900

def test_reentrancy_guard():
    # Test that reentrancy is blocked
    attacker = boa.load("attacker.vy")
    victim = boa.load("victim.vy")

    with pytest.raises(Exception, match="reentrancy"):
        attacker.attack(victim.address)
```

## Snekmate (OpenZeppelin for Vyper)

Pre-audited Vyper implementations:
- `snekmate/tokens/ERC20.vy` — complete ERC-20
- `snekmate/tokens/ERC721.vy` — complete ERC-721
- `snekmate/auth/Ownable.vy` — ownership module
- `snekmate/auth/AccessControl.vy` — role-based access

```bash
pip install snekmate
```

```vyper
import snekmate.tokens.ERC20 as ERC20Module

uses: ERC20Module

@deploy
def __init__(_name: String[25], _symbol: String[5], _decimals: uint8):
    ERC20Module.__init__(_name, _symbol, _decimals, 0, "")
```

## When You'll Encounter Vyper in Production

| Protocol | What's in Vyper | Why |
|----------|-----------------|-----|
| Curve Finance | All AMM contracts (StableSwap, CryptoSwap) | Vyper existed before Solidity was mature enough for complex math |
| Yearn V2 | Vault contracts | Readability for auditors |
| Lido | Partial | Some utility contracts |
| Uniswap V1 | Historical | The original Uniswap was Vyper |

**Audit implication**: If you're auditing any of these protocols or building on top of them, you MUST be able to read Vyper fluently.
