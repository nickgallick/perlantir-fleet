# Move Language — Sui & Aptos Comprehensive Reference

## 1. Move Philosophy: Resource-Oriented Programming

Move was created at Meta (Diem project) specifically for safe digital asset management. Its core insight: **assets are not integers — they are resources governed by linear types**.

### Linear Type System

In a linear type system, every value must be used exactly once. You cannot silently copy or discard a resource. The compiler enforces this statically — before deployment, not at runtime.

```move
module example::vault {
    // This struct has NO abilities — it is a pure linear resource.
    // It cannot be copied, dropped, or stored. It MUST be explicitly consumed.
    struct HotPotato {
        value: u64,
    }

    public fun create(): HotPotato {
        HotPotato { value: 100 }
    }

    // The ONLY way to get rid of a HotPotato is to unpack it explicitly
    public fun consume(potato: HotPotato): u64 {
        let HotPotato { value } = potato;
        value
    }

    // THIS WOULD NOT COMPILE — HotPotato lacks `drop`
    // public fun discard(potato: HotPotato) {
    //     // function ends without using `potato` → compile error
    // }
}
```

### Why This Prevents Entire Classes of Bugs

**Double-spend prevention**: A `Coin<SUI>` is a resource. You cannot copy it (no `copy` ability). If you pass it to a function, you no longer have it. The compiler prevents double-spending at the language level.

```move
module example::transfer_demo {
    use sui::coin::Coin;
    use sui::sui::SUI;

    public fun try_double_spend(coin: Coin<SUI>) {
        // After this call, `coin` is MOVED — we no longer own it
        transfer::public_transfer(coin, @0xALICE);

        // THIS WOULD NOT COMPILE:
        // transfer::public_transfer(coin, @0xBOB);
        // Error: `coin` has already been moved
    }
}
```

**Accidental destruction prevention**: Without the `drop` ability, a resource cannot go out of scope. You must explicitly destroy it or transfer it. This prevents tokens from being accidentally locked or burned.

**No unauthorized minting**: Only the module that defines a struct can create instances of it. External modules cannot forge `Coin<SUI>` because they cannot access the private constructor.

---

## 2. Move Type System

### Primitive Types

```move
// Unsigned integers — Move has NO signed integers
let a: u8 = 255;
let b: u16 = 65535;
let c: u32 = 4_294_967_295;
let d: u64 = 18_446_744_073_709_551_615;
let e: u128 = 340282366920938463463374607431768211455;
let f: u256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

// Boolean
let flag: bool = true;
let result: bool = (5 > 3) && !(2 == 1);

// Address — 32 bytes on Sui/Aptos
let addr: address = @0x1;
let user: address = @0xCAFE;

// Unit type (empty tuple)
let nothing: () = ();
```

### The Four Abilities

Every struct in Move has zero or more abilities. These are the fundamental permission system:

| Ability | Meaning | Implication |
|---------|---------|-------------|
| `copy` | Value can be duplicated | `let y = x; let z = x;` is valid |
| `drop` | Value can be silently discarded | Can go out of scope without explicit destruction |
| `store` | Value can be stored inside other structs | Required for persistence in global storage |
| `key` | Value can be used as a top-level storage key | Acts as an object (Sui) or resource in global storage (Aptos) |

```move
module example::abilities {
    // Pure resource — no abilities. Must be explicitly unpacked.
    struct HotPotato { value: u64 }

    // Freely copyable and droppable — behaves like a primitive
    struct Info has copy, drop { data: u64 }

    // Storable inside other objects but not a top-level object itself
    struct Component has store { weight: u64 }

    // Top-level Sui object — requires `key` and UID
    struct MyObject has key {
        id: UID,
        value: u64,
    }

    // Top-level object that can also be nested inside other objects
    struct TransferableAsset has key, store {
        id: UID,
        amount: u64,
    }

    // Full abilities — behaves like a plain data container
    struct Metadata has copy, drop, store {
        name: vector<u8>,
        version: u64,
    }
}
```

**Critical rule**: If a struct has an ability, ALL its fields must also have that ability. A struct with `copy` cannot contain a field that lacks `copy`.

### Generics with Ability Constraints

```move
module example::generic_vault {
    use sui::object::UID;

    // T must have `store` to be placed inside this object
    struct Vault<T: store> has key {
        id: UID,
        contents: T,
    }

    // T must have `copy + drop` for this container
    struct Cache<T: copy + drop> has copy, drop {
        items: vector<T>,
    }

    // Phantom type parameter — T is not used in the struct body
    // so it does NOT need matching abilities
    struct Witness<phantom T> has drop {}

    // Generic function with ability constraints
    public fun duplicate<T: copy>(item: &T): T {
        *item  // dereference to copy
    }

    // Destroy anything that has `drop`
    public fun throw_away<T: drop>(item: T) {
        // item is silently dropped at end of scope
    }
}
```

### Vectors

```move
module example::vectors {
    use std::vector;

    public fun vector_operations() {
        // Creation
        let v: vector<u64> = vector::empty();
        let v2: vector<u64> = vector[1, 2, 3, 4, 5];

        // Mutation
        vector::push_back(&mut v, 42);
        vector::push_back(&mut v, 99);
        let last = vector::pop_back(&mut v); // 99

        // Access
        let len = vector::length(&v);
        let first_ref: &u64 = vector::borrow(&v, 0);
        let first_mut: &mut u64 = vector::borrow_mut(&mut v, 0);
        *first_mut = 100;

        // Search
        let (found, index) = vector::index_of(&v2, &3);

        // Destruction
        let val = vector::remove(&mut v2, 0);       // preserves order, O(n)
        let val2 = vector::swap_remove(&mut v2, 0);  // O(1) but reorders

        // Reverse, append
        vector::reverse(&mut v2);
        vector::append(&mut v, v2); // v2 is consumed
    }
}
```

### References

```move
module example::references {
    struct Counter has key {
        id: UID,
        value: u64,
    }

    // Immutable reference — read only
    public fun get_value(counter: &Counter): u64 {
        counter.value
    }

    // Mutable reference — read and write
    public fun increment(counter: &mut Counter) {
        counter.value = counter.value + 1;
    }

    // References are ALWAYS safe in Move:
    // - No null references
    // - No dangling references (borrow checker prevents use-after-move)
    // - No mutable aliasing (cannot have &mut and & to same value simultaneously)
    // - References cannot be stored in structs (they are ephemeral)
}
```

### Signer Type

```move
module example::signer_demo {
    use std::signer;

    // On Aptos, `signer` represents the transaction sender
    // It CANNOT be forged — only the VM creates signers
    public entry fun do_something(account: &signer) {
        let addr = signer::address_of(account);
        // `account` proves that `addr` authorized this call
    }

    // On Sui, TxContext serves a similar role
    use sui::tx_context::TxContext;
    public fun sui_version(ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
    }
}
```

---

## 3. Move vs Solidity Safety

### Reentrancy: Impossible in Move

Solidity's reentrancy vulnerability stems from dynamic dispatch — calling an unknown external contract that can call back into you:

```solidity
// VULNERABLE Solidity — classic reentrancy
contract VulnerableVault {
    mapping(address => uint256) public balances;

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient");

        // BUG: state update AFTER external call
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "Transfer failed");

        balances[msg.sender] -= amount; // attacker re-enters before this line
    }
}
```

**Move makes this impossible** because:
1. There is NO dynamic dispatch. You cannot call arbitrary code via an address.
2. All function calls are statically resolved at compile time.
3. The borrow checker prevents simultaneous mutable access to the same resource.

```move
module example::safe_vault {
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;

    struct Vault has key {
        id: UID,
        reserves: Balance<SUI>,
    }

    /// Withdraw is inherently safe — no external calls, no reentrancy vector.
    /// The Coin is returned as a value; the caller decides what to do with it.
    public fun withdraw(vault: &mut Vault, amount: u64, ctx: &mut TxContext): Coin<SUI> {
        let withdrawn = balance::split(&mut vault.reserves, amount);
        coin::from_balance(withdrawn, ctx)
    }
}
```

### Integer Overflow: Built-in Protection

```solidity
// Solidity < 0.8.0 — VULNERABLE to overflow
contract Overflow {
    uint8 public value = 255;
    function increment() public {
        value += 1; // silently wraps to 0 in Solidity < 0.8
    }
}
```

Move aborts on ALL arithmetic overflow/underflow by default. There is no unchecked arithmetic:

```move
module example::math_safety {
    public fun safe_add(a: u64, b: u64): u64 {
        a + b  // aborts with ARITHMETIC_ERROR if overflow occurs
    }

    public fun safe_sub(a: u64, b: u64): u64 {
        a - b  // aborts if b > a (underflow)
    }

    // Division by zero also aborts automatically
    public fun safe_div(a: u64, b: u64): u64 {
        a / b  // aborts if b == 0
    }
}
```

### Access Control: Module-Level Encapsulation

In Solidity, access control is opt-in via modifiers — forgetting `onlyOwner` is a common vulnerability:

```solidity
// Solidity — access control is programmer's responsibility
contract Token {
    mapping(address => uint256) public balances;

    // VULNERABILITY: forgot `onlyOwner` modifier — anyone can mint
    function mint(address to, uint256 amount) external {
        balances[to] += amount;
    }
}
```

In Move, struct fields are private to the defining module by default. Only the module can construct, read, or modify its own types:

```move
module example::token {
    struct Treasury has key {
        id: UID,
        supply: u64,
    }

    struct AdminCap has key { id: UID }

    // Only the holder of AdminCap can mint — enforced by type system
    public fun mint(_admin: &AdminCap, treasury: &mut Treasury, amount: u64) {
        treasury.supply = treasury.supply + amount;
    }

    // No module outside `example::token` can:
    // - Create a Treasury (constructor is not public)
    // - Create an AdminCap (constructor is not public)
    // - Directly modify treasury.supply (fields are private)
}
```

### Summary Comparison

| Vulnerability | Solidity | Move |
|---|---|---|
| Reentrancy | Common, requires guards | Impossible — no dynamic dispatch |
| Integer overflow | Checked since 0.8, unchecked blocks exist | Always checked, no escape hatch |
| Access control | Opt-in modifiers | Module encapsulation by default |
| Double-spend | Logic bugs possible | Linear types prevent at compile time |
| Dangling references | N/A (storage model) | Borrow checker prevents |
| Asset duplication | Logic bugs possible | `copy` ability must be explicit |
| Unauthorized minting | Missing modifier bugs | Only defining module can construct |

---

## 4. Sui Object Model

### Objects as First-Class Citizens

On Sui, every on-chain entity is an object with a globally unique ID. Objects replace the account-based storage model with an object-centric model enabling parallel execution.

```move
module example::basic_object {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use sui::transfer;

    struct Sword has key, store {
        id: UID,
        damage: u64,
        durability: u64,
    }

    public fun forge(damage: u64, ctx: &mut TxContext): Sword {
        Sword {
            id: object::new(ctx),
            damage,
            durability: 100,
        }
    }

    public fun forge_and_transfer(damage: u64, recipient: address, ctx: &mut TxContext) {
        let sword = forge(damage, ctx);
        transfer::public_transfer(sword, recipient);
    }
}
```

### Ownership Categories

**1. Address-owned objects** — Owned by a specific address. Only that address can use them in transactions. Enables parallel execution because there are no contention conflicts.

```move
// Transfer to an address — object becomes address-owned
transfer::public_transfer(sword, @0xALICE);

// Only Alice can now use this sword in transactions
```

**2. Object-owned objects** — Owned by another object (parent-child relationship).

```move
module example::object_owned {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;

    struct Sheath has key {
        id: UID,
    }

    struct Blade has key, store {
        id: UID,
        sharpness: u64,
    }

    /// Transfer blade so it is owned by the sheath object
    public fun sheathe(sheath: &Sheath, blade: Blade) {
        transfer::public_transfer(blade, object::uid_to_address(&sheath.id));
    }
}
```

**3. Shared objects** — Accessible by anyone. Requires consensus ordering (slower than owned objects). Used for shared state like liquidity pools and orderbooks.

```move
module example::shared_counter {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;

    struct Counter has key {
        id: UID,
        value: u64,
    }

    fun init(ctx: &mut TxContext) {
        let counter = Counter {
            id: object::new(ctx),
            value: 0,
        };
        // share_object makes it accessible to ALL transactions
        transfer::share_object(counter);
    }

    public fun increment(counter: &mut Counter) {
        counter.value = counter.value + 1;
    }

    // Read-only access to shared objects does NOT require consensus
    public fun value(counter: &Counter): u64 {
        counter.value
    }
}
```

**4. Immutable objects** — Frozen forever. Cannot be mutated or transferred. Anyone can read them. No consensus needed.

```move
module example::immutable_config {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;

    struct Config has key {
        id: UID,
        max_supply: u64,
        name: vector<u8>,
    }

    fun init(ctx: &mut TxContext) {
        let config = Config {
            id: object::new(ctx),
            max_supply: 1_000_000,
            name: b"MyToken",
        };
        // freeze_object makes it permanently immutable
        transfer::freeze_object(config);
    }
}
```

### Transfer Policies

Objects with `key + store` can use `transfer::public_transfer` — anyone can transfer them. Objects with only `key` require custom transfer functions defined in their module, enabling custom transfer logic (royalties, restrictions).

```move
module example::soulbound {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;

    // key only — NO `store` ability
    // This means only THIS module can transfer it
    struct SoulboundBadge has key {
        id: UID,
        achievement: vector<u8>,
    }

    public fun mint(achievement: vector<u8>, recipient: address, ctx: &mut TxContext) {
        let badge = SoulboundBadge {
            id: object::new(ctx),
            achievement,
        };
        // Module-controlled transfer — no one else can move this badge
        transfer::transfer(badge, recipient);
    }

    // No public transfer function exposed — the badge is soulbound
}
```

### Dynamic Fields and Dynamic Object Fields

Dynamic fields allow adding heterogeneous key-value data to any object at runtime, without declaring it in the struct.

```move
module example::dynamic_demo {
    use sui::object::{Self, UID};
    use sui::dynamic_field as df;
    use sui::dynamic_object_field as dof;
    use sui::tx_context::TxContext;

    struct Character has key {
        id: UID,
        name: vector<u8>,
    }

    struct WeaponKey has copy, drop, store { slot: u8 }

    struct Weapon has key, store {
        id: UID,
        damage: u64,
    }

    struct Stats has copy, drop, store {
        strength: u64,
        agility: u64,
    }

    /// Add a plain value as dynamic field (the value is wrapped inside the parent)
    public fun set_stats(character: &mut Character, stats: Stats) {
        df::add(&mut character.id, b"stats", stats);
    }

    public fun get_stats(character: &Character): &Stats {
        df::borrow(&character.id, b"stats")
    }

    /// Add an object as a dynamic object field (the object retains its own ID
    /// and can be queried independently via its UID, but is logically owned
    /// by the parent)
    public fun equip_weapon(character: &mut Character, slot: u8, weapon: Weapon) {
        dof::add(&mut character.id, WeaponKey { slot }, weapon);
    }

    public fun unequip_weapon(character: &mut Character, slot: u8): Weapon {
        dof::remove(&mut character.id, WeaponKey { slot })
    }

    public fun borrow_weapon(character: &Character, slot: u8): &Weapon {
        dof::borrow(&character.id, WeaponKey { slot })
    }
}
```

**Key difference**: `dynamic_field` wraps the value so it is no longer independently addressable. `dynamic_object_field` keeps the child object addressable by its own ID on-chain (useful for explorers and indexing).

---

## 5. Sui-Specific Patterns

### Transaction Context (TxContext)

```move
module example::ctx_usage {
    use sui::tx_context::{Self, TxContext};
    use sui::object;

    public fun demo(ctx: &mut TxContext) {
        let sender: address = tx_context::sender(ctx);
        let epoch: u64 = tx_context::epoch(ctx);
        let epoch_ts_ms: u64 = tx_context::epoch_timestamp_ms(ctx);

        // Creating a new UID consumes entropy from ctx
        let uid = object::new(ctx);
        // ... use uid for a new object
    }
}
```

### One-Time Witness (OTW) Pattern

The OTW is a struct that is guaranteed to be created only once — in the module's `init` function. The framework passes it as the first argument to `init` if the struct matches the module name in uppercase and has only `drop`.

```move
module example::my_coin {
    use sui::coin;
    use sui::transfer;
    use sui::tx_context::TxContext;

    /// OTW — struct name matches module name in UPPERCASE, has only `drop`
    struct MY_COIN has drop {}

    /// `init` receives the OTW as first argument — guaranteed called only once at publish
    fun init(witness: MY_COIN, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency(
            witness,           // consumed here — can never be created again
            9,                 // decimals
            b"MYC",            // symbol
            b"My Coin",        // name
            b"Example coin",   // description
            option::none(),    // icon URL
            ctx,
        );
        // Transfer treasury cap to publisher
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(metadata);
    }
}
```

### Publisher Pattern

The `Publisher` object proves that the holder published a specific package. Used for setting `Display` and transfer policies.

```move
module example::my_nft {
    use sui::package;
    use sui::transfer;
    use sui::tx_context::TxContext;

    struct MY_NFT has drop {}

    fun init(otw: MY_NFT, ctx: &mut TxContext) {
        let publisher = package::claim(otw, ctx);
        // publisher proves we are the creator of this package
        transfer::public_transfer(publisher, tx_context::sender(ctx));
    }
}
```

### Display Standard

The `Display<T>` object defines how objects of type `T` are rendered by wallets, explorers, and marketplaces.

```move
module example::nft_display {
    use sui::display;
    use sui::package::Publisher;
    use sui::transfer;
    use sui::tx_context::TxContext;

    struct GameItem has key, store {
        id: UID,
        name: vector<u8>,
        level: u64,
        img_hash: vector<u8>,
    }

    public fun setup_display(publisher: &Publisher, ctx: &mut TxContext) {
        let mut d = display::new<GameItem>(publisher, ctx);

        display::add(&mut d, b"name".to_string(), b"{name}".to_string());
        display::add(&mut d, b"image_url".to_string(),
            b"https://assets.example.com/{img_hash}".to_string());
        display::add(&mut d, b"description".to_string(),
            b"A level {level} game item".to_string());
        display::add(&mut d, b"project_url".to_string(),
            b"https://example.com".to_string());

        display::update_version(&mut d);
        transfer::public_transfer(d, tx_context::sender(ctx));
    }
}
```

### Kiosk for NFT Trading with Royalties

Sui Kiosk provides a decentralized trading primitive with enforced royalties via transfer policies.

```move
module example::kiosk_usage {
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap};
    use sui::transfer_policy::{Self, TransferPolicy, TransferPolicyCap};
    use sui::package::Publisher;
    use sui::tx_context::TxContext;
    use sui::sui::SUI;
    use sui::coin::Coin;

    struct Collectible has key, store {
        id: UID,
        rarity: u8,
    }

    /// Creator sets up a transfer policy with royalty rules
    public fun create_policy(
        publisher: &Publisher,
        ctx: &mut TxContext,
    ): (TransferPolicy<Collectible>, TransferPolicyCap<Collectible>) {
        transfer_policy::new<Collectible>(publisher, ctx)
    }

    /// Seller: place item in kiosk and list for sale
    public fun list_item(
        kiosk: &mut Kiosk,
        cap: &KioskOwnerCap,
        item: Collectible,
        price: u64,
    ) {
        kiosk::place(kiosk, cap, item);
        let item_id = object::id(&item);
        kiosk::list<Collectible>(kiosk, cap, item_id, price);
    }

    /// Buyer: purchase from kiosk, pay royalties via transfer policy
    public fun buy_item(
        kiosk: &mut Kiosk,
        item_id: object::ID,
        payment: Coin<SUI>,
        policy: &mut TransferPolicy<Collectible>,
        ctx: &mut TxContext,
    ): Collectible {
        let (item, request) = kiosk::purchase(kiosk, item_id, payment);
        // Transfer request must be resolved by satisfying policy rules (royalties etc.)
        transfer_policy::confirm_request(policy, request);
        item
    }
}
```

### Coin Creation (create_currency)

```move
module example::usdc_example {
    use sui::coin::{Self, TreasuryCap, Coin};
    use sui::transfer;
    use sui::tx_context::TxContext;

    struct USDC_EXAMPLE has drop {}

    fun init(witness: USDC_EXAMPLE, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency(
            witness, 6, b"USDC", b"USD Coin", b"Stablecoin example", option::none(), ctx,
        );
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
    }

    /// Mint new coins — requires TreasuryCap (admin capability)
    public fun mint(
        treasury: &mut TreasuryCap<USDC_EXAMPLE>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        let minted = coin::mint(treasury, amount, ctx);
        transfer::public_transfer(minted, recipient);
    }

    /// Burn coins — returns them to the treasury
    public fun burn(treasury: &mut TreasuryCap<USDC_EXAMPLE>, coin: Coin<USDC_EXAMPLE>) {
        coin::burn(treasury, coin);
    }
}
```

### Clock Module

```move
module example::time_locked {
    use sui::clock::{Self, Clock};
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;

    struct TimeLock has key {
        id: UID,
        unlock_time_ms: u64,
        value: u64,
    }

    public fun create_lock(
        value: u64,
        lock_duration_ms: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ): TimeLock {
        TimeLock {
            id: object::new(ctx),
            unlock_time_ms: clock::timestamp_ms(clock) + lock_duration_ms,
            value,
        }
    }

    public fun unlock(lock: TimeLock, clock: &Clock): u64 {
        let TimeLock { id, unlock_time_ms, value } = lock;
        assert!(clock::timestamp_ms(clock) >= unlock_time_ms, 0);
        object::delete(id);
        value
    }
}
```

---

## 6. Aptos Architecture

### Account Model

Aptos uses a traditional account model where resources are stored under accounts. Each account has an address and can hold multiple resources.

```move
module example::aptos_basics {
    use std::signer;
    use aptos_framework::account;

    struct UserProfile has key {
        name: vector<u8>,
        score: u64,
    }

    /// Move resource under the signer's account
    public entry fun create_profile(account: &signer, name: vector<u8>) {
        let profile = UserProfile { name, score: 0 };
        move_to(account, profile);  // stores at signer's address
    }

    /// Read a resource from any address
    public fun get_score(addr: address): u64 acquires UserProfile {
        let profile = borrow_global<UserProfile>(addr);
        profile.score
    }

    /// Mutate a resource at the signer's address
    public entry fun increment_score(account: &signer) acquires UserProfile {
        let addr = signer::address_of(account);
        let profile = borrow_global_mut<UserProfile>(addr);
        profile.score = profile.score + 1;
    }

    /// Check existence before access
    public fun has_profile(addr: address): bool {
        exists<UserProfile>(addr)
    }

    /// Remove and destroy a resource
    public entry fun delete_profile(account: &signer) acquires UserProfile {
        let addr = signer::address_of(account);
        let UserProfile { name: _, score: _ } = move_from<UserProfile>(addr);
    }
}
```

### Resource Accounts

Resource accounts are autonomous accounts not controlled by any private key. Used for deploying modules that manage shared state.

```move
module example::resource_account_demo {
    use aptos_framework::account;
    use aptos_framework::resource_account;
    use std::signer;

    struct ModuleData has key {
        signer_cap: account::SignerCapability,
    }

    /// Called once during initialization when the resource account is created
    fun init_module(resource_signer: &signer) {
        let signer_cap = resource_account::retrieve_resource_account_cap(
            resource_signer, @deployer
        );
        move_to(resource_signer, ModuleData { signer_cap });
    }

    /// Use the stored signer capability to act as the resource account
    public fun do_something_as_resource() acquires ModuleData {
        let module_data = borrow_global<ModuleData>(@example);
        let resource_signer = account::create_signer_with_capability(&module_data.signer_cap);
        // `resource_signer` can now sign for the resource account
    }
}
```

### Aptos Coin Framework

```move
module example::aptos_token {
    use aptos_framework::coin::{Self, MintCapability, BurnCapability};
    use std::string;
    use std::signer;

    struct MyToken {}

    struct Capabilities has key {
        mint_cap: MintCapability<MyToken>,
        burn_cap: BurnCapability<MyToken>,
    }

    fun init_module(account: &signer) {
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<MyToken>(
            account,
            string::utf8(b"My Token"),
            string::utf8(b"MTK"),
            8,  // decimals
            true, // monitor_supply
        );
        coin::destroy_freeze_cap(freeze_cap);
        move_to(account, Capabilities { mint_cap, burn_cap });
    }

    public entry fun mint(admin: &signer, to: address, amount: u64) acquires Capabilities {
        let caps = borrow_global<Capabilities>(signer::address_of(admin));
        let coins = coin::mint(amount, &caps.mint_cap);
        coin::deposit(to, coins);
    }
}
```

### Aptos Fungible Asset (FA) Standard

The newer Fungible Asset standard on Aptos replaces the legacy coin module:

```move
module example::fa_token {
    use aptos_framework::fungible_asset::{Self, MintRef, TransferRef, BurnRef, Metadata};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::primary_fungible_store;
    use std::string;
    use std::option;

    struct TokenRefs has key {
        mint_ref: MintRef,
        transfer_ref: TransferRef,
        burn_ref: BurnRef,
    }

    fun init_module(admin: &signer) {
        let constructor_ref = object::create_named_object(admin, b"MY_FA");
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            &constructor_ref,
            option::some(1_000_000_000_00000000), // max supply
            string::utf8(b"My FA Token"),
            string::utf8(b"MFA"),
            8,
            string::utf8(b"https://example.com/icon.png"),
            string::utf8(b"https://example.com"),
        );

        let mint_ref = fungible_asset::generate_mint_ref(&constructor_ref);
        let transfer_ref = fungible_asset::generate_transfer_ref(&constructor_ref);
        let burn_ref = fungible_asset::generate_burn_ref(&constructor_ref);

        move_to(admin, TokenRefs { mint_ref, transfer_ref, burn_ref });
    }
}
```

### Events

```move
module example::events_demo {
    use aptos_framework::event;

    #[event]
    struct SwapEvent has drop, store {
        user: address,
        amount_in: u64,
        amount_out: u64,
        pool_id: u64,
    }

    public fun perform_swap(user: address, amount_in: u64, amount_out: u64) {
        // Emit event — indexed and queryable off-chain
        event::emit(SwapEvent {
            user,
            amount_in,
            amount_out,
            pool_id: 1,
        });
    }
}
```

### Table vs SmartTable

```move
module example::table_demo {
    use aptos_framework::table::{Self, Table};
    use aptos_framework::smart_table::{Self, SmartTable};

    struct Registry has key {
        // Table — O(1) lookup, keys must be known, not iterable
        balances: Table<address, u64>,

        // SmartTable — auto-splits buckets, better for large datasets,
        // supports iteration and length queries
        metadata: SmartTable<address, vector<u8>>,
    }

    public fun table_ops(registry: &mut Registry, addr: address) {
        // Table operations
        table::add(&mut registry.balances, addr, 100);
        let balance = table::borrow(&registry.balances, addr);
        let balance_mut = table::borrow_mut(&mut registry.balances, addr);
        *balance_mut = 200;
        let exists = table::contains(&registry.balances, addr);
        let removed = table::remove(&mut registry.balances, addr);

        // SmartTable operations — similar API but with length/iteration
        smart_table::add(&mut registry.metadata, addr, b"data");
        let len = smart_table::length(&registry.metadata);
    }
}
```

### Aggregator for Parallel Execution

Aggregators allow parallel increments/decrements without contention — critical for high-throughput counters like total supply.

```move
module example::parallel_counter {
    use aptos_framework::aggregator_v2::{Self, Aggregator};

    struct GlobalCounter has key {
        count: Aggregator<u64>,
    }

    public fun init_counter(account: &signer) {
        move_to(account, GlobalCounter {
            count: aggregator_v2::create_unbounded_aggregator(),
        });
    }

    /// Multiple transactions can call this in parallel without conflicts
    public fun increment(counter: &mut GlobalCounter) {
        aggregator_v2::add(&mut counter.count, 1);
    }

    public fun get_count(counter: &GlobalCounter): u64 {
        aggregator_v2::read(&counter.count)
    }
}
```

---

## 7. Move Prover — Formal Verification

The Move Prover uses SMT solvers (Z3) to mathematically verify properties about your code. Specifications are written alongside implementation and checked at compile time.

### Basic Specifications

```move
module example::verified_math {
    /// Safe addition with formal spec
    public fun safe_add(a: u64, b: u64): u64 {
        a + b
    }
    spec safe_add {
        // Precondition — function aborts if this is violated
        aborts_if a + b > MAX_U64;
        // Postcondition — guaranteed if function returns
        ensures result == a + b;
    }

    /// Transfer between balances
    public fun transfer(from: &mut u64, to: &mut u64, amount: u64) {
        assert!(*from >= amount, 1);
        *from = *from - amount;
        *to = *to + amount;
    }
    spec transfer {
        aborts_if *from < amount;
        aborts_if *to + amount > MAX_U64;
        ensures *from == old(*from) - amount;
        ensures *to == old(*to) + amount;
        // Conservation: total tokens unchanged
        ensures *from + *to == old(*from) + old(*to);
    }
}
```

### Struct Invariants

```move
module example::invariants {
    struct Pool has key {
        reserve_a: u64,
        reserve_b: u64,
        lp_supply: u64,
    }

    // Global invariant — must hold at ALL times
    spec Pool {
        // LP supply is zero iff both reserves are zero
        invariant (lp_supply == 0) ==> (reserve_a == 0 && reserve_b == 0);
        // Reserves are always > 0 when pool has liquidity
        invariant (lp_supply > 0) ==> (reserve_a > 0 && reserve_b > 0);
    }

    public fun add_liquidity(pool: &mut Pool, a: u64, b: u64): u64 {
        let lp_tokens = if (pool.lp_supply == 0) {
            // Initial deposit
            let initial = (a as u128) * (b as u128);
            // sqrt approximation for demo
            (a + b) / 2
        } else {
            let lp_a = (a as u128) * (pool.lp_supply as u128) / (pool.reserve_a as u128);
            let lp_b = (b as u128) * (pool.lp_supply as u128) / (pool.reserve_b as u128);
            let lp = if (lp_a < lp_b) { lp_a } else { lp_b };
            (lp as u64)
        };
        pool.reserve_a = pool.reserve_a + a;
        pool.reserve_b = pool.reserve_b + b;
        pool.lp_supply = pool.lp_supply + lp_tokens;
        lp_tokens
    }
    spec add_liquidity {
        aborts_if a == 0 || b == 0;
        ensures pool.reserve_a == old(pool.reserve_a) + a;
        ensures pool.reserve_b == old(pool.reserve_b) + b;
        ensures pool.lp_supply > old(pool.lp_supply);
    }
}
```

### Global Specifications and Schema

```move
module example::global_specs {
    struct TokenStore has key {
        balance: u64,
    }

    /// Specification schema — reusable spec blocks
    spec schema PreservesBalance {
        addr: address;
        let pre_balance = global<TokenStore>(addr).balance;
        let post_balance = global<TokenStore>(addr).balance;
        ensures pre_balance == post_balance;
    }

    /// Apply schema to a function
    public fun read_only_operation(addr: address): u64 acquires TokenStore {
        borrow_global<TokenStore>(addr).balance
    }
    spec read_only_operation {
        include PreservesBalance { addr };
    }

    /// Module-level invariant — applies to ALL public functions
    spec module {
        // Total supply across all accounts never changes
        // (would be checked across every public function entry/exit)
        invariant forall addr: address where exists<TokenStore>(addr):
            global<TokenStore>(addr).balance <= 1_000_000;
    }
}
```

### Specification Language Features

```move
spec module {
    // Quantifiers
    invariant forall addr: address: exists<CoinStore>(addr) ==> global<CoinStore>(addr).balance >= 0;
    invariant exists addr: address: exists<AdminCap>(addr);

    // Old values (pre-state)
    ensures balance == old(balance) + deposit_amount;

    // Global state access
    requires exists<Config>(@admin);
    ensures global<Config>(@admin).paused == false;

    // Aborts conditions
    aborts_if !exists<TokenStore>(addr) with ENotRegistered;
    aborts_if amount == 0 with EZeroAmount;

    // Helper functions in specs
    spec fun total_supply(): u64 {
        global<Treasury>(@token_addr).total_supply
    }
}
```

---

## 8. Real Examples

### Full DEX (AMM) on Sui — Constant Product Market Maker

```move
module dex::amm {
    use sui::object::{Self, UID, ID};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance, Supply};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    use sui::math;

    // ======== Errors ========
    const EZeroAmount: u64 = 0;
    const EInsufficientLiquidity: u64 = 1;
    const ESlippageExceeded: u64 = 2;
    const EPoolAlreadyExists: u64 = 3;

    // ======== Constants ========
    const FEE_BPS: u64 = 30; // 0.3% fee
    const BPS_BASE: u64 = 10000;
    const MIN_LIQUIDITY: u64 = 1000; // minimum locked forever

    // ======== Types ========

    /// LP token type — phantom generics ensure uniqueness per pair
    struct LP<phantom A, phantom B> has drop {}

    /// The liquidity pool — shared object
    struct Pool<phantom A, phantom B> has key {
        id: UID,
        reserve_a: Balance<A>,
        reserve_b: Balance<B>,
        lp_supply: Supply<LP<A, B>>,
        fee_bps: u64,
    }

    // ======== Events ========
    #[event]
    struct PoolCreated has copy, drop {
        pool_id: ID,
        creator: address,
    }

    #[event]
    struct SwapExecuted has copy, drop {
        pool_id: ID,
        sender: address,
        amount_in: u64,
        amount_out: u64,
        a_to_b: bool,
    }

    #[event]
    struct LiquidityAdded has copy, drop {
        pool_id: ID,
        amount_a: u64,
        amount_b: u64,
        lp_minted: u64,
    }

    // ======== Pool Creation ========

    public fun create_pool<A, B>(
        coin_a: Coin<A>,
        coin_b: Coin<B>,
        ctx: &mut TxContext,
    ): Coin<LP<A, B>> {
        let amount_a = coin::value(&coin_a);
        let amount_b = coin::value(&coin_b);
        assert!(amount_a > 0 && amount_b > 0, EZeroAmount);

        let lp_supply = balance::create_supply(LP<A, B> {});
        let initial_lp = math::sqrt(amount_a) * math::sqrt(amount_b);
        assert!(initial_lp > MIN_LIQUIDITY, EInsufficientLiquidity);

        // Lock minimum liquidity forever to prevent pool draining
        let mut lp_supply_mut = lp_supply;
        let lp_balance = balance::increase_supply(&mut lp_supply_mut, initial_lp);

        let pool = Pool<A, B> {
            id: object::new(ctx),
            reserve_a: coin::into_balance(coin_a),
            reserve_b: coin::into_balance(coin_b),
            lp_supply: lp_supply_mut,
            fee_bps: FEE_BPS,
        };

        event::emit(PoolCreated {
            pool_id: object::id(&pool),
            creator: tx_context::sender(ctx),
        });

        transfer::share_object(pool);
        coin::from_balance(lp_balance, ctx)
    }

    // ======== Swap ========

    /// Swap coin A for coin B
    public fun swap_a_for_b<A, B>(
        pool: &mut Pool<A, B>,
        coin_in: Coin<A>,
        min_out: u64,
        ctx: &mut TxContext,
    ): Coin<B> {
        let amount_in = coin::value(&coin_in);
        assert!(amount_in > 0, EZeroAmount);

        let reserve_a = balance::value(&pool.reserve_a);
        let reserve_b = balance::value(&pool.reserve_b);

        let amount_out = compute_output(amount_in, reserve_a, reserve_b, pool.fee_bps);
        assert!(amount_out >= min_out, ESlippageExceeded);
        assert!(amount_out < reserve_b, EInsufficientLiquidity);

        // Deposit input, withdraw output
        balance::join(&mut pool.reserve_a, coin::into_balance(coin_in));
        let out_balance = balance::split(&mut pool.reserve_b, amount_out);

        event::emit(SwapExecuted {
            pool_id: object::id(pool),
            sender: tx_context::sender(ctx),
            amount_in,
            amount_out,
            a_to_b: true,
        });

        coin::from_balance(out_balance, ctx)
    }

    /// Swap coin B for coin A
    public fun swap_b_for_a<A, B>(
        pool: &mut Pool<A, B>,
        coin_in: Coin<B>,
        min_out: u64,
        ctx: &mut TxContext,
    ): Coin<A> {
        let amount_in = coin::value(&coin_in);
        assert!(amount_in > 0, EZeroAmount);

        let reserve_a = balance::value(&pool.reserve_a);
        let reserve_b = balance::value(&pool.reserve_b);

        let amount_out = compute_output(amount_in, reserve_b, reserve_a, pool.fee_bps);
        assert!(amount_out >= min_out, ESlippageExceeded);
        assert!(amount_out < reserve_a, EInsufficientLiquidity);

        balance::join(&mut pool.reserve_b, coin::into_balance(coin_in));
        let out_balance = balance::split(&mut pool.reserve_a, amount_out);

        event::emit(SwapExecuted {
            pool_id: object::id(pool),
            sender: tx_context::sender(ctx),
            amount_in,
            amount_out,
            a_to_b: false,
        });

        coin::from_balance(out_balance, ctx)
    }

    // ======== Liquidity ========

    public fun add_liquidity<A, B>(
        pool: &mut Pool<A, B>,
        coin_a: Coin<A>,
        coin_b: Coin<B>,
        ctx: &mut TxContext,
    ): Coin<LP<A, B>> {
        let amount_a = coin::value(&coin_a);
        let amount_b = coin::value(&coin_b);
        assert!(amount_a > 0 && amount_b > 0, EZeroAmount);

        let reserve_a = balance::value(&pool.reserve_a);
        let reserve_b = balance::value(&pool.reserve_b);
        let lp_total = balance::supply_value(&pool.lp_supply);

        // Calculate LP tokens: min(a/reserve_a, b/reserve_b) * lp_total
        let lp_a = (amount_a as u128) * (lp_total as u128) / (reserve_a as u128);
        let lp_b = (amount_b as u128) * (lp_total as u128) / (reserve_b as u128);
        let lp_amount = if (lp_a < lp_b) { (lp_a as u64) } else { (lp_b as u64) };
        assert!(lp_amount > 0, EInsufficientLiquidity);

        balance::join(&mut pool.reserve_a, coin::into_balance(coin_a));
        balance::join(&mut pool.reserve_b, coin::into_balance(coin_b));
        let lp_balance = balance::increase_supply(&mut pool.lp_supply, lp_amount);

        event::emit(LiquidityAdded {
            pool_id: object::id(pool),
            amount_a,
            amount_b,
            lp_minted: lp_amount,
        });

        coin::from_balance(lp_balance, ctx)
    }

    public fun remove_liquidity<A, B>(
        pool: &mut Pool<A, B>,
        lp_coin: Coin<LP<A, B>>,
        ctx: &mut TxContext,
    ): (Coin<A>, Coin<B>) {
        let lp_amount = coin::value(&lp_coin);
        let lp_total = balance::supply_value(&pool.lp_supply);
        let reserve_a = balance::value(&pool.reserve_a);
        let reserve_b = balance::value(&pool.reserve_b);

        let amount_a = (reserve_a as u128) * (lp_amount as u128) / (lp_total as u128);
        let amount_b = (reserve_b as u128) * (lp_amount as u128) / (lp_total as u128);

        balance::decrease_supply(&mut pool.lp_supply, coin::into_balance(lp_coin));

        let coin_a = coin::from_balance(balance::split(&mut pool.reserve_a, (amount_a as u64)), ctx);
        let coin_b = coin::from_balance(balance::split(&mut pool.reserve_b, (amount_b as u64)), ctx);

        (coin_a, coin_b)
    }

    // ======== Internal ========

    /// Constant product formula with fee: dy = (dx * fee_mult * ry) / (rx * BPS + dx * fee_mult)
    fun compute_output(amount_in: u64, reserve_in: u64, reserve_out: u64, fee_bps: u64): u64 {
        let fee_multiplier = BPS_BASE - fee_bps; // 9970 for 0.3% fee
        let numerator = (amount_in as u128) * (fee_multiplier as u128) * (reserve_out as u128);
        let denominator = (reserve_in as u128) * (BPS_BASE as u128)
                        + (amount_in as u128) * (fee_multiplier as u128);
        (numerator / denominator as u64)
    }

    // ======== View Functions ========

    public fun get_reserves<A, B>(pool: &Pool<A, B>): (u64, u64) {
        (balance::value(&pool.reserve_a), balance::value(&pool.reserve_b))
    }

    public fun get_lp_supply<A, B>(pool: &Pool<A, B>): u64 {
        balance::supply_value(&pool.lp_supply)
    }
}
```

### Escrow Pattern

```move
module example::escrow {
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct Escrow<T: key + store> has key {
        id: UID,
        sender: address,
        recipient: address,
        item: T,
        /// ID of the item the sender expects in return
        expected_item_id: ID,
    }

    /// Lock an item in escrow, specifying the recipient and what you expect back
    public fun create<T: key + store>(
        item: T,
        recipient: address,
        expected_item_id: ID,
        ctx: &mut TxContext,
    ) {
        let escrow = Escrow {
            id: object::new(ctx),
            sender: tx_context::sender(ctx),
            recipient,
            item,
            expected_item_id,
        };
        transfer::share_object(escrow);
    }

    /// Recipient completes the swap by providing the expected item
    public fun exchange<T: key + store, U: key + store>(
        escrow: Escrow<T>,
        return_item: U,
        ctx: &mut TxContext,
    ) {
        let Escrow { id, sender, recipient, item, expected_item_id } = escrow;

        // Verify caller is the intended recipient
        assert!(tx_context::sender(ctx) == recipient, 0);
        // Verify the return item matches what was expected
        assert!(object::id(&return_item) == expected_item_id, 1);

        // Complete the exchange
        transfer::public_transfer(item, recipient);
        transfer::public_transfer(return_item, sender);
        object::delete(id);
    }

    /// Sender can cancel and reclaim their item
    public fun cancel<T: key + store>(escrow: Escrow<T>, ctx: &mut TxContext) {
        let Escrow { id, sender, recipient: _, item, expected_item_id: _ } = escrow;
        assert!(tx_context::sender(ctx) == sender, 0);
        transfer::public_transfer(item, sender);
        object::delete(id);
    }
}
```

### NFT Collection with Royalties (Sui)

```move
module nft::collection {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::package::{Self, Publisher};
    use sui::display;
    use sui::event;
    use std::string::{Self, String};

    // ======== OTW ========
    struct COLLECTION has drop {}

    // ======== Types ========
    struct CollectionNFT has key, store {
        id: UID,
        name: String,
        description: String,
        image_url: String,
        edition: u64,
        attributes: vector<Attribute>,
    }

    struct Attribute has store, copy, drop {
        key: String,
        value: String,
    }

    struct MintCap has key {
        id: UID,
        supply: u64,
        max_supply: u64,
        collection_name: String,
    }

    // ======== Events ========
    #[event]
    struct NFTMinted has copy, drop {
        nft_id: object::ID,
        edition: u64,
        recipient: address,
    }

    // ======== Init ========
    fun init(otw: COLLECTION, ctx: &mut TxContext) {
        let publisher = package::claim(otw, ctx);

        // Setup display template
        let mut d = display::new<CollectionNFT>(&publisher, ctx);
        display::add(&mut d, string::utf8(b"name"), string::utf8(b"{name}"));
        display::add(&mut d, string::utf8(b"description"), string::utf8(b"{description}"));
        display::add(&mut d, string::utf8(b"image_url"), string::utf8(b"{image_url}"));
        display::add(&mut d, string::utf8(b"edition"), string::utf8(b"#{edition}"));
        display::update_version(&mut d);

        let mint_cap = MintCap {
            id: object::new(ctx),
            supply: 0,
            max_supply: 10_000,
            collection_name: string::utf8(b"My NFT Collection"),
        };

        let sender = tx_context::sender(ctx);
        transfer::public_transfer(publisher, sender);
        transfer::public_transfer(d, sender);
        transfer::transfer(mint_cap, sender); // MintCap is not `store`, only creator controls it
    }

    // ======== Minting ========
    public fun mint(
        cap: &mut MintCap,
        name: String,
        description: String,
        image_url: String,
        attributes: vector<Attribute>,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        assert!(cap.supply < cap.max_supply, 0);
        cap.supply = cap.supply + 1;

        let nft = CollectionNFT {
            id: object::new(ctx),
            name,
            description,
            image_url,
            edition: cap.supply,
            attributes,
        };

        event::emit(NFTMinted {
            nft_id: object::id(&nft),
            edition: cap.supply,
            recipient,
        });

        transfer::public_transfer(nft, recipient);
    }

    // ======== Helpers ========
    public fun new_attribute(key: String, value: String): Attribute {
        Attribute { key, value }
    }

    public fun supply(cap: &MintCap): u64 { cap.supply }
    public fun max_supply(cap: &MintCap): u64 { cap.max_supply }
}
```

---

## 9. Testing

### Basic Test Structure

```move
module example::math {
    const EOverflow: u64 = 1;

    public fun safe_multiply(a: u64, b: u64): u64 {
        let result = (a as u128) * (b as u128);
        assert!(result <= (18446744073709551615u128), EOverflow);
        (result as u64)
    }

    public fun percentage(amount: u64, bps: u64): u64 {
        ((amount as u128) * (bps as u128) / 10000 as u64)
    }

    // ======== Tests ========
    #[test]
    fun test_safe_multiply() {
        assert!(safe_multiply(100, 200) == 20000, 0);
        assert!(safe_multiply(0, 999) == 0, 0);
        assert!(safe_multiply(1, 1) == 1, 0);
    }

    #[test]
    #[expected_failure(abort_code = EOverflow)]
    fun test_multiply_overflow() {
        // u64 max * 2 should overflow
        safe_multiply(18446744073709551615, 2);
    }

    #[test]
    fun test_percentage() {
        assert!(percentage(10000, 500) == 500, 0);  // 5%
        assert!(percentage(10000, 10000) == 10000, 0); // 100%
        assert!(percentage(10000, 1) == 1, 0);       // 0.01%
    }

    #[test]
    #[expected_failure] // any abort is expected
    fun test_divide_by_zero() {
        let _ = 100 / 0;
    }
}
```

### Test-Only Modules and Functions

```move
module example::token {
    struct Token has key, store {
        id: UID,
        value: u64,
    }

    public fun value(token: &Token): u64 { token.value }

    // This function only exists during testing — stripped from production builds
    #[test_only]
    public fun create_for_testing(value: u64, ctx: &mut TxContext): Token {
        Token { id: object::new(ctx), value }
    }

    #[test_only]
    public fun destroy_for_testing(token: Token) {
        let Token { id, value: _ } = token;
        object::delete(id);
    }
}

// Entire module available only in tests
#[test_only]
module example::token_tests {
    use example::token;
    use sui::test_scenario;

    #[test]
    fun test_token_creation() {
        let mut scenario = test_scenario::begin(@0xALICE);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let token = token::create_for_testing(100, ctx);
            assert!(token::value(&token) == 100, 0);
            token::destroy_for_testing(token);
        };
        test_scenario::end(scenario);
    }
}
```

### Sui test_scenario — Multi-Transaction Testing

```move
#[test_only]
module dex::amm_tests {
    use sui::test_scenario::{Self as ts, Scenario};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::test_utils;
    use dex::amm::{Self, Pool, LP};

    // Dummy coin for testing
    struct USDC has drop {}

    #[test]
    fun test_full_amm_flow() {
        let admin = @0xADMIN;
        let alice = @0xALICE;
        let bob = @0xBOB;

        // Transaction 1: Admin creates pool
        let mut scenario = ts::begin(admin);
        {
            let ctx = ts::ctx(&mut scenario);
            let sui_coin = coin::mint_for_testing<SUI>(1_000_000, ctx);
            let usdc_coin = coin::mint_for_testing<USDC>(1_000_000, ctx);
            let lp_coin = amm::create_pool(sui_coin, usdc_coin, ctx);
            transfer::public_transfer(lp_coin, admin);
        };

        // Transaction 2: Alice swaps SUI for USDC
        ts::next_tx(&mut scenario, alice);
        {
            let mut pool = ts::take_shared<Pool<SUI, USDC>>(&scenario);
            let ctx = ts::ctx(&mut scenario);

            let sui_in = coin::mint_for_testing<SUI>(10_000, ctx);
            let usdc_out = amm::swap_a_for_b(&mut pool, sui_in, 1, ctx);

            // Verify we got some USDC
            assert!(coin::value(&usdc_out) > 0, 0);
            transfer::public_transfer(usdc_out, alice);
            ts::return_shared(pool);
        };

        // Transaction 3: Bob adds liquidity
        ts::next_tx(&mut scenario, bob);
        {
            let mut pool = ts::take_shared<Pool<SUI, USDC>>(&scenario);
            let ctx = ts::ctx(&mut scenario);

            let sui = coin::mint_for_testing<SUI>(500_000, ctx);
            let usdc = coin::mint_for_testing<USDC>(500_000, ctx);
            let lp = amm::add_liquidity(&mut pool, sui, usdc, ctx);

            assert!(coin::value(&lp) > 0, 0);
            transfer::public_transfer(lp, bob);
            ts::return_shared(pool);
        };

        // Transaction 4: Verify pool state
        ts::next_tx(&mut scenario, admin);
        {
            let pool = ts::take_shared<Pool<SUI, USDC>>(&scenario);
            let (reserve_a, reserve_b) = amm::get_reserves(&pool);
            // Reserves should have increased from initial 1M each
            assert!(reserve_a > 1_000_000, 0);
            ts::return_shared(pool);
        };

        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = amm::EZeroAmount)]
    fun test_swap_zero_fails() {
        let mut scenario = ts::begin(@0x1);
        {
            let ctx = ts::ctx(&mut scenario);
            let sui = coin::mint_for_testing<SUI>(1_000_000, ctx);
            let usdc = coin::mint_for_testing<USDC>(1_000_000, ctx);
            let lp = amm::create_pool(sui, usdc, ctx);
            transfer::public_transfer(lp, @0x1);
        };

        ts::next_tx(&mut scenario, @0x1);
        {
            let mut pool = ts::take_shared<Pool<SUI, USDC>>(&scenario);
            let ctx = ts::ctx(&mut scenario);

            // Zero-value swap should abort
            let zero_coin = coin::mint_for_testing<SUI>(0, ctx);
            let out = amm::swap_a_for_b(&mut pool, zero_coin, 0, ctx);
            transfer::public_transfer(out, @0x1);
            ts::return_shared(pool);
        };

        ts::end(scenario);
    }
}
```

### Aptos Testing Pattern

```move
#[test_only]
module example::aptos_test {
    use aptos_framework::account;
    use aptos_framework::coin;
    use example::my_module;

    #[test(admin = @example, user = @0xBEEF)]
    fun test_with_signers(admin: &signer, user: &signer) {
        // Create test accounts
        account::create_account_for_test(@example);
        account::create_account_for_test(@0xBEEF);

        // Initialize module
        my_module::init_for_test(admin);

        // Perform operations
        my_module::do_something(user);

        // Assert state
        assert!(my_module::get_value(@0xBEEF) == 42, 0);
    }

    #[test(admin = @example)]
    #[expected_failure(abort_code = 0x50001, location = example::my_module)]
    fun test_unauthorized_access(admin: &signer) {
        // Should fail with specific error
        my_module::admin_only_action(admin);
    }
}
```

---

## 10. Security Checklist

### Critical Checks

**1. Capability Leaks** — Capabilities (AdminCap, TreasuryCap) must never be publicly transferable without intent.

```move
// BAD: Anyone who gets a reference can use admin functions
public fun dangerous(treasury: &mut TreasuryCap<TOKEN>, amount: u64, ctx: &mut TxContext) {
    let coins = coin::mint(treasury, amount, ctx);
    transfer::public_transfer(coins, tx_context::sender(ctx));
}

// GOOD: Wrap admin functions with additional auth
struct AdminCap has key { id: UID }

public fun mint(
    _admin: &AdminCap,    // Proves caller holds the capability object
    treasury: &mut TreasuryCap<TOKEN>,
    amount: u64,
    recipient: address,
    ctx: &mut TxContext,
) {
    let coins = coin::mint(treasury, amount, ctx);
    transfer::public_transfer(coins, recipient);
}
```

**2. Shared Object Contention** — Overusing shared objects kills throughput.

```move
// BAD: Global counter as shared object — every transaction contends
struct GlobalState has key {
    id: UID,
    total_users: u64,     // every new user must write here
    total_volume: u64,    // every swap must write here
}

// GOOD: Use owned objects where possible, split state
struct UserState has key {
    id: UID,
    volume: u64,           // per-user, no contention
}
// Only aggregate when needed via off-chain indexing
```

**3. Flash Loan Safety** — Ensure hot-potato pattern enforces repayment.

```move
module example::flash_loan {
    struct FlashReceipt {
        // NO abilities — must be consumed by `repay`
        pool_id: ID,
        amount: u64,
    }

    public fun borrow(pool: &mut Pool, amount: u64, ctx: &mut TxContext): (Coin<SUI>, FlashReceipt) {
        let coin = coin::from_balance(balance::split(&mut pool.reserves, amount), ctx);
        let receipt = FlashReceipt { pool_id: object::id(pool), amount };
        (coin, receipt)
    }

    /// The ONLY way to dispose of FlashReceipt — forces repayment
    public fun repay(pool: &mut Pool, coin: Coin<SUI>, receipt: FlashReceipt) {
        let FlashReceipt { pool_id, amount } = receipt;
        assert!(object::id(pool) == pool_id, 0);
        assert!(coin::value(&coin) >= amount, 1); // must repay at least borrowed amount
        balance::join(&mut pool.reserves, coin::into_balance(coin));
    }
}
```

**4. Integer Precision** — Use u128 or u256 intermediates for multiplication before division.

```move
// BAD: loses precision
let result = amount * price / PRECISION;
// If amount=3, price=2, PRECISION=4 → 3*2/4 = 1 (lost 0.5)

// GOOD: upcast to u128 for intermediate
let result = ((amount as u128) * (price as u128) / (PRECISION as u128) as u64);
```

**5. Object ID Verification** — Always verify object IDs in multi-object operations.

```move
// BAD: no verification that the cap belongs to this pool
public fun admin_action(pool: &mut Pool, cap: &AdminCap) { /* ... */ }

// GOOD: verify the cap is for this specific pool
public fun admin_action(pool: &mut Pool, cap: &AdminCap) {
    assert!(cap.pool_id == object::id(pool), EWrongPool);
}
```

**6. Witness Pattern Correctness** — Ensure one-time witnesses are truly one-time.

```move
// The OTW struct MUST:
// - Be named after the module in UPPERCASE
// - Have ONLY the `drop` ability
// - Have NO fields
// - Be consumed in `init` — never stored

// CORRECT
struct MY_MODULE has drop {}
fun init(witness: MY_MODULE, ctx: &mut TxContext) { /* ... */ }

// WRONG — has `copy`, could be duplicated
struct MY_MODULE has copy, drop {}
```

### Full Security Checklist

| Category | Check | Severity |
|---|---|---|
| **Capabilities** | AdminCap/TreasuryCap cannot be forged or leaked | Critical |
| **Capabilities** | Capability objects verified against target objects (pool ID match) | Critical |
| **Object Model** | Shared objects used only when necessary (prefer owned) | High |
| **Object Model** | Immutable objects used for config/metadata | Medium |
| **Object Model** | Dynamic fields cleaned up properly (no orphaned data) | Medium |
| **Arithmetic** | u128/u256 intermediates for multiply-then-divide | High |
| **Arithmetic** | Division-by-zero impossible (checked before division) | High |
| **Arithmetic** | Rounding direction favors the protocol, not the user | High |
| **Flash Loans** | Hot potato pattern used (no abilities on receipt) | Critical |
| **Flash Loans** | Receipt amount verified against actual repayment | Critical |
| **Access Control** | init function sets up capabilities correctly | Critical |
| **Access Control** | No public constructors for privileged types | Critical |
| **Access Control** | Module-level encapsulation for sensitive fields | High |
| **Witness** | OTW has only `drop`, no fields, consumed in init | Critical |
| **Coins/Tokens** | TreasuryCap holder is authorized (not leaked) | Critical |
| **Coins/Tokens** | Supply tracking is accurate | High |
| **Testing** | Edge cases tested (zero amounts, max values, empty pools) | High |
| **Testing** | Multi-transaction scenarios tested | High |
| **Testing** | Expected failures verified with specific abort codes | Medium |
| **Sui-Specific** | transfer::transfer vs transfer::public_transfer intentional | High |
| **Sui-Specific** | Shared vs owned object choice is deliberate | High |
| **Aptos-Specific** | acquires annotations on all global storage accessors | High |
| **Aptos-Specific** | Resource account signer capabilities stored securely | Critical |
| **Prover** | Key invariants have formal specifications | Medium |
| **Prover** | Conservation properties proven (total supply, balances) | High |

### Common Attack Vectors in Move

**Price Oracle Manipulation**: Even though reentrancy is impossible, price manipulation via flash loans is still possible. Always use time-weighted average prices (TWAP) or external oracles.

**Governance Attacks**: Flash-borrowing governance tokens to pass proposals is possible if voting uses current balance. Use checkpointed/snapshotted balances.

**Rounding Exploits**: Repeated small operations that round in the user's favor can drain pools. Always round against the user (round down for withdrawals, round up for deposits).

**Object Wrapping Attacks**: On Sui, wrapping an object inside another changes its accessibility. Ensure users cannot wrap objects they should not control.

**Unchecked Type Parameters**: Generic functions that do not constrain type parameters may be called with unintended types. Always use phantom types or ability constraints to restrict usage.

```move
// BAD: Any type T could be used to drain the vault
public fun withdraw<T>(vault: &mut Vault<T>): Coin<T> { /* ... */ }

// GOOD: Require authorization witness specific to T
public fun withdraw<T>(vault: &mut Vault<T>, _auth: &AdminCap<T>): Coin<T> { /* ... */ }
```
