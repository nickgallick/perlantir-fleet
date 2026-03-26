# Polkadot, ink!, & Substrate

## ink! Smart Contracts

```rust
// ink! 4.x — Rust-based, compiles to Wasm
#![cfg_attr(not(feature = "std"), no_std, no_main)]

#[ink::contract]
mod sparta_simple {
    use ink::storage::Mapping;

    #[ink(storage)]
    pub struct SpartaSimple {
        balances: Mapping<AccountId, Balance>,
        total_supply: Balance,
        owner: AccountId,
    }

    #[ink(event)]
    pub struct Transfer {
        #[ink(topic)]
        from: Option<AccountId>,
        #[ink(topic)]
        to: Option<AccountId>,
        value: Balance,
    }

    impl SpartaSimple {
        #[ink(constructor)]
        pub fn new(total_supply: Balance) -> Self {
            let caller = Self::env().caller();
            let mut balances = Mapping::default();
            balances.insert(caller, &total_supply);

            Self::env().emit_event(Transfer {
                from: None,
                to: Some(caller),
                value: total_supply,
            });

            Self {
                balances,
                total_supply,
                owner: caller,
            }
        }

        #[ink(message)]
        pub fn transfer(&mut self, to: AccountId, value: Balance) -> bool {
            let from = self.env().caller();
            let from_balance = self.balances.get(from).unwrap_or(0);

            if from_balance < value {
                return false;
            }

            self.balances.insert(from, &(from_balance - value));
            let to_balance = self.balances.get(to).unwrap_or(0);
            self.balances.insert(to, &(to_balance + value));

            self.env().emit_event(Transfer {
                from: Some(from),
                to: Some(to),
                value,
            });
            true
        }

        #[ink(message)]
        pub fn balance_of(&self, account: AccountId) -> Balance {
            self.balances.get(account).unwrap_or(0)
        }
    }
}
```

## Substrate — Build Your Own Chain

```rust
// Custom pallet for Agent Sparta challenge logic
// Pallets are modular runtime components — Lego blocks for blockchain features

#[frame_support::pallet]
pub mod pallet_sparta {
    use frame_support::pallet_prelude::*;
    use frame_system::pallet_prelude::*;

    #[pallet::pallet]
    pub struct Pallet<T>(_);

    #[pallet::config]
    pub trait Config: frame_system::Config {
        type RuntimeEvent: From<Event<Self>> + IsType<<Self as frame_system::Config>::RuntimeEvent>;
        type Currency: Currency<Self::AccountId>;
        #[pallet::constant]
        type MinPrize: Get<BalanceOf<Self>>;
    }

    #[pallet::storage]
    pub type Challenges<T: Config> = StorageMap<_, Blake2_128Concat, T::Hash, Challenge<T>>;

    #[pallet::event]
    #[pallet::generate_deposit(pub(super) fn deposit_event)]
    pub enum Event<T: Config> {
        ChallengeCreated { id: T::Hash, creator: T::AccountId, prize: BalanceOf<T> },
        PrizeAwarded { id: T::Hash, winner: T::AccountId, amount: BalanceOf<T> },
    }

    #[pallet::call]
    impl<T: Config> Pallet<T> {
        #[pallet::weight(10_000)]
        pub fn create_challenge(
            origin: OriginFor<T>,
            prize: BalanceOf<T>,
        ) -> DispatchResult {
            let creator = ensure_signed(origin)?;
            ensure!(prize >= T::MinPrize::get(), Error::<T>::PrizeTooSmall);

            T::Currency::reserve(&creator, prize)?;

            let id = T::Hashing::hash_of(&(creator.clone(), prize, frame_system::Pallet::<T>::block_number()));
            Challenges::<T>::insert(id, Challenge { creator: creator.clone(), prize, status: Status::Open });

            Self::deposit_event(Event::ChallengeCreated { id, creator, prize });
            Ok(())
        }
    }
}
```

## When Polkadot/Substrate Matters

| Use Polkadot | Don't Use Polkadot |
|-------------|-------------------|
| Need app-specific chain with shared security | Simple dApp on existing chain |
| Custom consensus or governance rules | Standard ERC-20/ERC-721 |
| Parachain for Polkadot ecosystem | EVM ecosystem DeFi |
| Cross-chain via XCM (Polkadot native) | Smaller developer ecosystem OK |
