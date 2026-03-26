# TON & Telegram Blockchain

## Architecture Fundamentals

TON is fundamentally different from EVM chains in one key way: **asynchronous messaging**.

```
EVM (synchronous):
  ContractA.call() → ContractB.call() → ContractC.call()
  Everything in one atomic transaction. All or nothing.

TON (asynchronous):
  ContractA sends message → ContractB processes in NEXT block → sends message → ContractC processes in block after
  Each message is its own transaction. Multi-step processes span multiple blocks.
  Reentrancy is IMPOSSIBLE by design (each contract handles one message at a time).
  But: error handling is complex (what if step 3 fails? You need to handle rollbacks manually).
```

## FunC / Tact Syntax

```tact
// Tact (higher-level, recommended for new developers)
contract JettonWallet {
    balance: Int as coins;
    owner: Address;
    master: Address;

    init(owner: Address, master: Address) {
        self.balance = 0;
        self.owner = owner;
        self.master = master;
    }

    // Receive incoming transfer message
    receive(msg: TokenTransfer) {
        require(sender() == self.master || sender() == self.owner, "Unauthorized");

        if (msg.destination == self.owner) {
            self.balance += msg.amount;
        } else {
            // Forward to destination's jetton wallet
            let destination_wallet = initOf JettonWallet(msg.destination, self.master);
            send(SendParameters{
                to: contractAddress(destination_wallet),
                value: ton("0.05"),    // Gas for the next message
                mode: SendIgnoreErrors,
                body: TokenTransfer{
                    amount: msg.amount,
                    destination: msg.destination,
                    response_destination: msg.response_destination
                }.toCell()
            });
            self.balance -= msg.amount;
        }
    }
}
```

```func
;; FunC (lower-level, closer to assembly)
() recv_internal(int my_balance, int msg_value, cell in_msg_full, slice in_msg_body) impure {
    ;; Parse sender
    slice cs = in_msg_full.begin_parse();
    int flags = cs~load_uint(4);

    if (flags & 1) { ;; bounced message
        return ();
    }

    slice sender_address = cs~load_msg_addr();

    ;; Load storage
    (int balance, slice owner_address, slice jetton_master_address, cell jetton_wallet_code)
        = load_data();

    ;; Handle transfer operation
    int op = in_msg_body~load_uint(32);

    if (op == op::transfer()) {
        int query_id = in_msg_body~load_uint(64);
        int jetton_amount = in_msg_body~load_coins();

        ;; Deduct from sender's balance
        throw_unless(705, balance >= jetton_amount);
        balance -= jetton_amount;

        ;; Send to recipient's jetton wallet
        ;; (recipient's wallet contract address derived from owner + master)
        cell state_init = calculate_jetton_wallet_state_init(destination, jetton_master_address, jetton_wallet_code);
        slice to_wallet_address = calc_address(state_init);

        send_raw_message(build_transfer_message(to_wallet_address, jetton_amount), 64);
        save_data(balance, owner_address, jetton_master_address, jetton_wallet_code);
    }
}
```

## Telegram Mini Apps + TON

```typescript
// A Telegram Mini App (runs inside Telegram)
// User never leaves Telegram. No MetaMask needed.

import TonConnect from "@tonconnect/sdk";
import WebApp from "@twa-dev/sdk";

// Get Telegram user info
const user = WebApp.initDataUnsafe.user;
console.log(`User: ${user.username}, ID: ${user.id}`);

// Connect TON wallet (Tonkeeper, MyTonWallet — built into Telegram)
const tonConnect = new TonConnect({ manifestUrl: "https://myapp.com/tonconnect.json" });
await tonConnect.connect({ jsBridgeKey: "tonkeeper" });

const wallet = tonConnect.wallet;
console.log(`Wallet: ${wallet.account.address}`);

// Send TON
await tonConnect.sendTransaction({
    validUntil: Math.floor(Date.now() / 1000) + 360,
    messages: [{
        address: "EQD...",   // Recipient TON address
        amount: "1000000000" // 1 TON in nanotons
    }]
});
```

## Agent Sparta on TON — Why It Makes Sense

```
Distribution advantage:
  - 900M Telegram users vs ~50M crypto users on EVM
  - No wallet installation required (Wallet in Telegram is built-in)
  - No gas complexity (TON handles gas abstraction better than EVM)
  - Telegram Mini App = seamless UX within an app users already use daily

Architecture:
  - Challenge contract: TON smart contract (Tact)
  - Entry fee: USDT/TON jetton transfer to challenge contract
  - Submission: encrypted text via Telegram bot + hash committed on-chain
  - Judging: oracle reports score → contract distributes winnings
  - Payout: TON jetton transfer back to winner's TON wallet

Trade-off:
  - Less DeFi composability (smaller TVL, fewer protocols)
  - Async messaging adds complexity to multi-step flows
  - Smaller smart contract developer ecosystem

Conclusion: EVM (Base) for DeFi integration; TON for viral consumer distribution.
Consider launching on BOTH — same challenge, two entry points.
```
