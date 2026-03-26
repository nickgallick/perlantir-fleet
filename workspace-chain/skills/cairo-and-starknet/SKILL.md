# Cairo Language & StarkNet Architecture Reference

## Cairo Language Fundamentals

### felt252 and Type System

The primitive type is `felt252` — a field element in the Stark prime field P = 2^251 + 17*2^192 + 1. Arithmetic wraps modulo P. Division is field inversion (NOT integer division).

```cairo
let a: felt252 = 100;
let diff = a - 200;  // wraps modulo P — a huge number, NOT -100
let ratio = 10 / 3;  // field inversion, NOT integer 3
```

Use bounded integer types for safe arithmetic (panics on overflow):

```cairo
let x: u8 = 255;
let y: u128 = 1000;
let big: u256 = u256 { low: 1_u128, high: 0_u128 }; // u256 is two u128s
let signed: i32 = -42;
let flag: bool = true;
let short: felt252 = 'hello';          // short string, max 31 ASCII bytes
let long: ByteArray = "longer string"; // arbitrary length
```

### Ownership, Snapshots, References

Cairo uses a linear type system (like Rust). Values must be used exactly once — moved, destroyed, or snapshotted.

```cairo
#[derive(Drop)]       // allows silent discard at scope end
struct Wallet { balance: u256 }

#[derive(Copy, Drop)] // allows implicit copy (only for types of Copy fields)
struct Point { x: felt252, y: felt252 }

fn snapshots_and_refs() {
    let arr = array![1, 2, 3];
    let len = read_len(@arr);  // @ creates a snapshot (read-only, no move)
    let _ = *arr.at(0);        // * desnaps (copies out — only for Copy types)

    let mut nums: Array<u32> = array![];
    push(ref nums, 42);       // ref passes mutable reference
}
fn read_len(arr: @Array<u32>) -> usize { arr.len() }
fn push(ref arr: Array<u32>, v: u32) { arr.append(v); }
```

### Arrays and Dictionaries

```cairo
fn collections() {
    let mut arr: Array<u32> = array![10, 20, 30];
    arr.append(40);
    let val = *arr.at(1);                     // 20, panics if OOB
    let safe: Option<@u32> = arr.get(99);     // None
    let front: Option<u32> = arr.pop_front(); // Some(10)
    let span: Span<u32> = arr.span();         // read-only view

    let mut dict: Felt252Dict<u128> = Default::default();
    dict.insert('alice', 1000);
    let bal = dict.get('alice');    // 1000
    let zero = dict.get('nobody'); // 0 (default for unset keys)
    // Dict must be squashed on scope exit (Destruct trait, handled automatically)
}
```

### Enums, Pattern Matching, Option/Result

```cairo
#[derive(Drop)]
enum Action { Move: (i32, i32), Attack: u32, Wait }

fn handle(action: Action) -> felt252 {
    match action {
        Action::Move((x, y)) => 'moved',
        Action::Attack(dmg)  => 'attacked',
        Action::Wait         => 'waited',
    }
}

fn error_handling() -> Result<u32, felt252> {
    let opt: Option<u32> = Option::Some(42);
    let v = opt.unwrap();          // panics if None
    let v = opt.unwrap_or(0);      // default if None

    if 0_u32 == 0 { return Result::Err('division by zero'); }
    Result::Ok(100)
    // Use ? operator to propagate errors in functions returning Result
}
```

### Traits, Generics, Structs

```cairo
trait Describable<T> { fn describe(self: @T) -> ByteArray; }

#[derive(Drop, Copy)]
struct Token { symbol: felt252, decimals: u8 }

impl TokenDesc of Describable<Token> {
    fn describe(self: @Token) -> ByteArray { "A token" }
}

fn generic_fn<T, +Describable<T>, +Drop<T>, +Copy<T>>(item: T) -> ByteArray {
    item.describe()
}

#[derive(Drop, Copy)]
struct Rectangle { width: u64, height: u64 }

#[generate_trait]
impl RectImpl of RectTrait {
    fn area(self: @Rectangle) -> u64 { *self.width * *self.height }
    fn scale(ref self: Rectangle, f: u64) { self.width *= f; self.height *= f; }
}
```

---

## Sierra & CASM — Two-Stage Compilation

```
Cairo (.cairo) → Sierra (Safe IR) → CASM (Cairo Assembly) → Execution Trace → STARK Proof
```

**Why Sierra exists:** Before Sierra, failed transactions (assertion failure, OOG) were unprovable, yet the sequencer spent resources. Sierra guarantees every program is provable:

- **Gas metering built-in** — `withdraw_gas` inserted at loop heads/function entries. If gas runs out, execution halts provably and fees are still charged.
- **No undefined behavior** — fallible operations return Results instead of panicking unprovably.
- **Branch alignment** — every conditional accounts for all paths so the prover always has a valid trace.

Sierra uses **libfuncs** — provably-terminating primitives. **CASM** is the low-level Cairo VM code with write-once memory, registers (`ap`, `fp`, `pc`), and builtins (range_check, pedersen, poseidon, ecdsa, bitwise, ec_op). On **declare**, Sierra is submitted; the sequencer compiles to CASM. **Class hash** = `poseidon(sierra_program, abi, entry_points)`.

---

## StarkNet Architecture

L1 holds the StarkNet Core Contract (state root) and Verifier (STARK proof checker). L2 has the Sequencer, Prover, and SHARP.

**Sequencer** — receives, orders, executes transactions; produces blocks and execution traces. Currently centralized (StarkWare), decentralization planned. **SHARP** (Shared Prover) — aggregates traces from multiple blocks into one STARK proof, amortizing cost. **State** — Merkle-Patricia trie. Leaves = contract states (`class_hash`, `storage_root`, `nonce`). Each contract's storage is its own sub-trie. State commitment posted to L1 after proof verification.

### Transaction Lifecycle

1. User signs → sends to sequencer gateway
2. `__validate__` called on account contract (signature/nonce check)
3. `__execute__` called if valid
4. Block produced → trace to SHARP → STARK proof
5. Proof + state diff → L1 verifier → state root updated on L1

Statuses: `RECEIVED` → `ACCEPTED_ON_L2` → `ACCEPTED_ON_L1`

Transaction types: **INVOKE** (call function), **DECLARE** (register class), **DEPLOY_ACCOUNT** (counterfactual deploy), **L1_HANDLER** (from L1 message).

---

## Storage Model

Contract storage is flat key-value (felt → felt). The compiler maps complex types:

- Simple variable: slot = `sn_keccak("var_name") mod 2^251`
- `u256`: two consecutive slots (low, high)
- `Map<K, V>`: slot = `pedersen(sn_keccak("map_name"), key)`
- Nested `Map<K1, Map<K2, V>>`: `pedersen(pedersen(base, k1), k2)`
- Structs: flatten to consecutive slots from base address

```cairo
#[starknet::contract]
mod StorageDemo {
    use starknet::storage::Map;
    #[storage]
    struct Storage {
        balance: u256,                                             // 2 slots
        balances: Map<ContractAddress, u256>,                      // hash-addressed
        allowances: Map<ContractAddress, Map<ContractAddress, u256>>, // nested
    }
}
```

**StorePacking** — pack multiple small values into one felt252 to save storage ops:

```cairo
impl PackedStorePacking of StorePacking<MyStruct, u256> {
    fn pack(value: MyStruct) -> u256 { u256 { low: value.a, high: value.b } }
    fn unpack(value: u256) -> MyStruct { MyStruct { a: value.low, b: value.high } }
}
```

---

## Account Abstraction — Native

Every account is a smart contract. No EOAs. Any signature scheme works (ECDSA, Schnorr, multisig, passkeys). Multicall is native.

### validate/execute Separation

```cairo
#[starknet::contract]
mod Account {
    use starknet::{get_tx_info, account::Call};
    use core::ecdsa::check_ecdsa_signature;

    #[storage]
    struct Storage { public_key: felt252 }

    #[constructor]
    fn constructor(ref self: ContractState, pub_key: felt252) {
        self.public_key.write(pub_key);
    }

    #[abi(embed_v0)]
    impl AccountImpl of IAccount<ContractState> {
        fn __validate__(ref self: ContractState, calls: Array<Call>) -> felt252 {
            let tx = get_tx_info().unbox();
            let sig = tx.signature;
            assert(sig.len() == 2, 'bad sig len');
            assert(
                check_ecdsa_signature(tx.transaction_hash, self.public_key.read(), *sig.at(0), *sig.at(1)),
                'invalid signature'
            );
            starknet::VALIDATED
        }

        fn __execute__(ref self: ContractState, calls: Array<Call>) -> Array<Span<felt252>> {
            let mut results: Array<Span<felt252>> = array![];
            let mut i: usize = 0;
            loop {
                if i >= calls.len() { break; }
                let call = calls.at(i);
                let res = starknet::syscalls::call_contract_syscall(
                    *call.to, *call.selector, call.calldata.span()
                ).unwrap();
                results.append(res);
                i += 1;
            };
            results
        }
    }
}
```

`__validate__` must: verify signature, return `VALIDATED`, use minimal gas, NOT write storage (writes are reverted). `__execute__` performs actual operations.

**Session keys pattern:** store `SessionKey { public_key, expires_at, allowed_selector, max_calls }` in storage. In `__validate__`, if signer matches a session key, enforce scope restrictions.

---

## Contract Development

### Full Contract Structure

```cairo
#[starknet::interface]
trait ICounter<TContractState> {
    fn get_count(self: @TContractState) -> u256;
    fn increment(ref self: TContractState);
}

#[starknet::contract]
mod Counter {
    use starknet::{ContractAddress, get_caller_address};

    #[storage]
    struct Storage { count: u256, owner: ContractAddress }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event { Incremented: Incremented }

    #[derive(Drop, starknet::Event)]
    struct Incremented { #[key] by: ContractAddress, new_count: u256 }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
    }

    #[abi(embed_v0)]
    impl CounterImpl of super::ICounter<ContractState> {
        fn get_count(self: @ContractState) -> u256 { self.count.read() }
        fn increment(ref self: ContractState) {
            let new = self.count.read() + 1;
            self.count.write(new);
            self.emit(Incremented { by: get_caller_address(), new_count: new });
        }
    }
}
```

Key attributes: `#[starknet::contract]` (contract module), `#[storage]` (persistent state), `#[event]` (log enum), `#[key]` (indexed event field), `#[constructor]` (deploy-time init), `#[abi(embed_v0)]` (expose impl as ABI), `#[starknet::interface]` (external interface trait).

### Component System

Components are compile-time-checked reusable modules (like mixins):

```cairo
#[starknet::component]
mod OwnableComponent {
    use starknet::{ContractAddress, get_caller_address};
    #[storage]
    struct Storage { owner: ContractAddress }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event { OwnershipTransferred: OwnershipTransferred }
    #[derive(Drop, starknet::Event)]
    struct OwnershipTransferred { previous: ContractAddress, new_owner: ContractAddress }

    #[embeddable_as(OwnableImpl)]
    impl Ownable<TContractState, +HasComponent<TContractState>> of IOwnable<ComponentState<TContractState>> {
        fn owner(self: @ComponentState<TContractState>) -> ContractAddress { self.owner.read() }
        fn transfer_ownership(ref self: ComponentState<TContractState>, new: ContractAddress) {
            assert(get_caller_address() == self.owner.read(), 'not owner');
            let prev = self.owner.read();
            self.owner.write(new);
            self.emit(OwnershipTransferred { previous: prev, new_owner: new });
        }
    }
}

// Using the component:
#[starknet::contract]
mod MyContract {
    component!(path: super::OwnableComponent, storage: ownable, event: OwnableEvent);
    #[abi(embed_v0)]
    impl OwnableImpl = super::OwnableComponent::OwnableImpl<ContractState>;

    #[storage]
    struct Storage { #[substorage(v0)] ownable: super::OwnableComponent::Storage }
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event { OwnableEvent: super::OwnableComponent::Event }
}
```

### Dispatchers (Cross-Contract Calls)

`#[starknet::interface]` generates dispatchers automatically:

```cairo
// IERC20Dispatcher { contract_address } — external calls
// IERC20LibraryDispatcher { class_hash } — library/delegatecall-style
let token = IERC20Dispatcher { contract_address: token_addr };
let bal = token.balance_of(user);
token.transfer(recipient, amount);
```

---

## Testing with snforge

```cairo
#[cfg(test)]
mod tests {
    use snforge_std::{declare, ContractClassTrait, DeclareResultTrait,
        start_cheat_caller_address, stop_cheat_caller_address,
        start_cheat_block_timestamp, spy_events, EventSpyAssertionsTrait};

    fn deploy_counter() -> ICounterDispatcher {
        let contract = declare("Counter").unwrap().contract_class();
        let owner = starknet::contract_address_const::<'owner'>();
        let mut calldata = array![];
        owner.serialize(ref calldata);
        let (addr, _) = contract.deploy(@calldata).unwrap();
        ICounterDispatcher { contract_address: addr }
    }

    #[test]
    fn test_increment() {
        let counter = deploy_counter();
        counter.increment();
        assert(counter.get_count() == 1, 'should be 1');
    }

    #[test]
    fn test_with_cheats() {
        let counter = deploy_counter();
        let alice = starknet::contract_address_const::<'alice'>();
        start_cheat_caller_address(counter.contract_address, alice); // prank caller
        counter.increment();
        stop_cheat_caller_address(counter.contract_address);

        start_cheat_block_timestamp(counter.contract_address, 1700000000); // warp time
    }

    #[test]
    fn test_events() {
        let counter = deploy_counter();
        let mut spy = spy_events();
        counter.increment();
        spy.assert_emitted(@array![(
            counter.contract_address,
            Counter::Event::Incremented(Counter::Incremented {
                by: starknet::contract_address_const::<0>(), new_count: 1
            })
        )]);
    }

    #[test]
    #[should_panic(expected: 'some error')]
    fn test_panic() { panic!("some error"); }
}
```

```bash
snforge test                          # run all
snforge test test_increment           # run specific
snforge test --filter "test_erc20"    # filter
```

---

## Real Examples

### ERC-20 Implementation

```cairo
#[starknet::contract]
mod ERC20 {
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::Map;
    use core::num::traits::Zero;

    #[storage]
    struct Storage {
        name: ByteArray, symbol: ByteArray, decimals: u8,
        total_supply: u256,
        balances: Map<ContractAddress, u256>,
        allowances: Map<ContractAddress, Map<ContractAddress, u256>>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event { Transfer: Transfer, Approval: Approval }
    #[derive(Drop, starknet::Event)]
    struct Transfer { #[key] from: ContractAddress, #[key] to: ContractAddress, value: u256 }
    #[derive(Drop, starknet::Event)]
    struct Approval { #[key] owner: ContractAddress, #[key] spender: ContractAddress, value: u256 }

    #[constructor]
    fn constructor(ref self: ContractState, name: ByteArray, symbol: ByteArray,
                   decimals: u8, initial_supply: u256, recipient: ContractAddress) {
        self.name.write(name); self.symbol.write(symbol); self.decimals.write(decimals);
        self._mint(recipient, initial_supply);
    }

    #[abi(embed_v0)]
    impl ERC20Impl of super::IERC20<ContractState> {
        fn name(self: @ContractState) -> ByteArray { self.name.read() }
        fn symbol(self: @ContractState) -> ByteArray { self.symbol.read() }
        fn decimals(self: @ContractState) -> u8 { self.decimals.read() }
        fn total_supply(self: @ContractState) -> u256 { self.total_supply.read() }
        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.balances.read(account)
        }
        fn allowance(self: @ContractState, owner: ContractAddress, spender: ContractAddress) -> u256 {
            self.allowances.read(owner).read(spender)
        }
        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            self._transfer(get_caller_address(), recipient, amount); true
        }
        fn transfer_from(ref self: ContractState, sender: ContractAddress,
                         recipient: ContractAddress, amount: u256) -> bool {
            let caller = get_caller_address();
            let allowed = self.allowances.read(sender).read(caller);
            assert(allowed >= amount, 'ERC20: insufficient allowance');
            self.allowances.entry(sender).entry(caller).write(allowed - amount);
            self._transfer(sender, recipient, amount); true
        }
        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
            let owner = get_caller_address();
            self.allowances.entry(owner).entry(spender).write(amount);
            self.emit(Approval { owner, spender, value: amount }); true
        }
    }

    #[generate_trait]
    impl Internal of InternalTrait {
        fn _transfer(ref self: ContractState, from: ContractAddress, to: ContractAddress, amount: u256) {
            assert(!from.is_zero(), 'ERC20: from 0'); assert(!to.is_zero(), 'ERC20: to 0');
            let bal = self.balances.read(from);
            assert(bal >= amount, 'ERC20: insufficient balance');
            self.balances.write(from, bal - amount);
            self.balances.write(to, self.balances.read(to) + amount);
            self.emit(Transfer { from, to, value: amount });
        }
        fn _mint(ref self: ContractState, to: ContractAddress, amount: u256) {
            assert(!to.is_zero(), 'ERC20: mint to 0');
            self.total_supply.write(self.total_supply.read() + amount);
            self.balances.write(to, self.balances.read(to) + amount);
            self.emit(Transfer { from: Zero::zero(), to, value: amount });
        }
    }
}
```

### AMM (Constant Product)

```cairo
#[starknet::contract]
mod AMM {
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use starknet::storage::Map;

    #[storage]
    struct Storage {
        token_a: ContractAddress, token_b: ContractAddress,
        reserve_a: u256, reserve_b: u256,
        total_lp: u256, lp_balances: Map<ContractAddress, u256>,
        fee_bps: u256, // e.g. 30 = 0.3%
    }

    #[abi(embed_v0)]
    impl AMMImpl of super::IAMM<ContractState> {
        fn add_liquidity(ref self: ContractState, amt_a: u256, amt_b: u256) -> u256 {
            let caller = get_caller_address();
            let this = get_contract_address();
            IERC20Dispatcher { contract_address: self.token_a.read() }.transfer_from(caller, this, amt_a);
            IERC20Dispatcher { contract_address: self.token_b.read() }.transfer_from(caller, this, amt_b);
            let lp = if self.total_lp.read() == 0 { sqrt(amt_a * amt_b) } else {
                let la = amt_a * self.total_lp.read() / self.reserve_a.read();
                let lb = amt_b * self.total_lp.read() / self.reserve_b.read();
                if la < lb { la } else { lb }
            };
            self.reserve_a.write(self.reserve_a.read() + amt_a);
            self.reserve_b.write(self.reserve_b.read() + amt_b);
            self.total_lp.write(self.total_lp.read() + lp);
            self.lp_balances.write(caller, self.lp_balances.read(caller) + lp);
            lp
        }

        fn swap_a_for_b(ref self: ContractState, amount_in: u256) -> u256 {
            let in_after_fee = amount_in * (10000 - self.fee_bps.read());
            let out = in_after_fee * self.reserve_b.read() / (self.reserve_a.read() * 10000 + in_after_fee);
            let (caller, this) = (get_caller_address(), get_contract_address());
            IERC20Dispatcher { contract_address: self.token_a.read() }.transfer_from(caller, this, amount_in);
            IERC20Dispatcher { contract_address: self.token_b.read() }.transfer(caller, out);
            self.reserve_a.write(self.reserve_a.read() + amount_in);
            self.reserve_b.write(self.reserve_b.read() - out);
            out
        }
    }

    fn sqrt(v: u256) -> u256 {
        if v == 0 { return 0; }
        let mut z = v; let mut x = v / 2 + 1;
        loop { if x >= z { break z; } z = x; x = (v / x + x) / 2; }
    }
}
```

### Vault Pattern (ERC-4626 style)

```cairo
#[starknet::contract]
mod Vault {
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use starknet::storage::Map;

    #[storage]
    struct Storage {
        asset: ContractAddress, total_shares: u256, total_assets: u256,
        shares: Map<ContractAddress, u256>,
    }

    #[abi(embed_v0)]
    impl VaultImpl of super::IVault<ContractState> {
        fn deposit(ref self: ContractState, assets: u256) -> u256 {
            let (caller, supply) = (get_caller_address(), self.total_shares.read());
            let minted = if supply == 0 { assets }
                else { assets * supply / self.total_assets.read() };
            assert(minted > 0, 'zero shares');
            IERC20Dispatcher { contract_address: self.asset.read() }
                .transfer_from(caller, get_contract_address(), assets);
            self.total_shares.write(supply + minted);
            self.total_assets.write(self.total_assets.read() + assets);
            self.shares.write(caller, self.shares.read(caller) + minted);
            minted
        }

        fn withdraw(ref self: ContractState, share_amount: u256) -> u256 {
            let caller = get_caller_address();
            let user_shares = self.shares.read(caller);
            assert(user_shares >= share_amount, 'insufficient shares');
            let assets_out = share_amount * self.total_assets.read() / self.total_shares.read();
            self.shares.write(caller, user_shares - share_amount);
            self.total_shares.write(self.total_shares.read() - share_amount);
            self.total_assets.write(self.total_assets.read() - assets_out);
            IERC20Dispatcher { contract_address: self.asset.read() }.transfer(caller, assets_out);
            assets_out
        }
    }
}
```

---

## StarkNet-Specific Patterns

### L1 ↔ L2 Messaging

**L1→L2:** Call `sendMessageToL2(toAddress, selector, payload)` on StarkNet core contract (Solidity). Handle on L2 with `#[l1_handler]`:

```cairo
#[l1_handler]
fn deposit_from_l1(ref self: ContractState, from_address: felt252, recipient: ContractAddress, amount: u256) {
    assert(from_address == self.l1_bridge.read(), 'unauthorized L1 sender');
    self.balances.write(recipient, self.balances.read(recipient) + amount);
}
```

**L2→L1:** Use `send_message_to_l1_syscall`. Consumable on L1 after STARK proof verified:

```cairo
fn send_to_l1(ref self: ContractState, l1_recipient: felt252, amount: u256) {
    let payload = array![l1_recipient, amount.low.into(), amount.high.into()];
    starknet::syscalls::send_message_to_l1_syscall(self.l1_bridge.read(), payload.span()).unwrap();
}
```

L1 consumption: `starknetCore.consumeMessageFromL2(l2Sender, payload)`.

### Contract Classes vs. Instances

A **class** is code (Sierra). An **instance** is a deployed contract with address and storage. Multiple instances share one class.

```bash
starkli declare my_contract.contract_class.json   # upload code, get class_hash
starkli deploy <class_hash> <constructor_args>     # create instance
```

Address = `pedersen("STARKNET_CONTRACT_ADDRESS", deployer, salt, class_hash, pedersen(calldata))`.

**Counterfactual deployment** (for accounts): compute address → fund it → send DEPLOY_ACCOUNT tx.

### Upgradeable Contracts

No proxy pattern needed — `replace_class_syscall` is a first-class primitive:

```cairo
fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
    assert(get_caller_address() == self.owner.read(), 'unauthorized');
    assert(!new_class_hash.is_zero(), 'invalid class hash');
    starknet::syscalls::replace_class_syscall(new_class_hash).unwrap();
    // Takes effect for all subsequent calls (including same tx after this point)
}
```

Storage layout must remain compatible across upgrades — new code must correctly interpret existing slots.

---

## Security Checklist

### 1. Reentrancy
Cross-contract dispatcher calls can reenter. Use checks-effects-interactions:
```cairo
// GOOD: update state BEFORE external call
self.balances.write(caller, balance - amount);
token.transfer(caller, amount);
```

### 2. felt252 Arithmetic Traps
- Subtraction wraps modulo P: `5 - 10` = `P - 5` (huge). Use u256 for monetary values.
- Division is field inversion, not integer division. `7 / 2 != 3`.

### 3. Access Control
- Validate `get_caller_address()` on privileged functions.
- `get_caller_address()` = direct caller (the account contract), not tx originator. Use `get_tx_info().account_contract_address` for originator.

### 4. Integer Overflow
Bounded types panic on overflow. Handle edge cases with explicit checks and meaningful error messages.

### 5. Storage Collisions in Components
Components sharing variable names collide on storage slots. Use `#[substorage(v0)]` for namespacing.

### 6. Unprotected replace_class
Gate `replace_class_syscall` with multisig/timelock. Unprotected = full contract hijack.

### 7. L1↔L2 Message Validation
- Always verify `from_address` in `#[l1_handler]`.
- L1→L2 messages can replay without nonce protection.
- L2→L1 only valid after proof — no instant finality.

### 8. Storage Zero Defaults
Uninitialized storage returns zero. Cannot distinguish "zero balance" from "never deposited". Use explicit flags when zero is a valid value.

### 9. Front-Running and Signature Replay
Transactions visible in mempool — use slippage protection, deadlines, commit-reveal. Protocol manages nonces for INVOKE, but off-chain signatures (permits) need explicit replay protection.

### Checklist Summary

- [ ] u256/u128 for monetary values, never felt252; checks-effects-interactions
- [ ] Validate caller on privileged functions; gate replace_class with multisig+timelock
- [ ] Verify from_address in #[l1_handler]; namespace component storage with #[substorage(v0)]
- [ ] Handle zero-default storage; slippage limits and deadlines on DeFi ops
- [ ] Nonces for off-chain signature replay; test zero/max/edge cases
- [ ] Constructor initializes all critical state; events for all state changes
- [ ] __validate__ cannot be tricked into VALIDATED for malicious txns
