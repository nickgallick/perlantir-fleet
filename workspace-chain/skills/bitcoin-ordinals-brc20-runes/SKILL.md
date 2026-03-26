# Bitcoin Ordinals, BRC-20 & Runes

## Bitcoin Script Fundamentals

```
Stack-based execution — no loops, no recursion, NOT Turing-complete (by design)

P2TR (Pay to Taproot) — current standard:
  Spending conditions: either key path (single sig) OR script path (arbitrary script)
  Script path hidden until spent: privacy + flexibility
  Tapscript: slightly extended scripting within Taproot

OP_RETURN:
  One output in a tx can have OP_RETURN — arbitrary data, unspendable
  Standard way to embed protocol data in Bitcoin transactions
  Runes use OP_RETURN for all operations
  Limit: 80 bytes (expanded in some implementations)

Witness data (SegWit/Taproot):
  Ordinals use witness data for inscriptions
  Witness data not counted fully toward block weight (cheaper per byte)
  Taproot witness can hold arbitrary data of any size (up to block limit)
```

## Ordinals — Inscription Format

```
Satoshi numbering: each sat has an ordinal number based on mining order
  - First sat of genesis block = ordinal 0
  - Order: coinbase sats first, then inputs in order, then outputs in order

Inscription envelope (in Tapscript spend script):
  OP_FALSE
  OP_IF
    OP_PUSH "ord"           # marker
    OP_PUSH 0x01            # tag: content-type
    OP_PUSH "image/png"     # content type
    OP_PUSH 0x00            # separator (empty push)
    OP_PUSH <data_chunk_1>  # content data
    OP_PUSH <data_chunk_2>  # more data (can be multiple pushes)
    ...
  OP_ENDIF

The OP_FALSE makes the IF branch never execute — the inscription is essentially
dead code in the script. But it's permanently in the blockchain.
The ordinal of the first sat in the first output becomes the "inscription ID".
```

```python
# Python: create an ordinal inscription (conceptual)
from bitcoinlib.transactions import Transaction

def create_inscription(content_type: str, content: bytes, signing_key) -> Transaction:
    # Encode inscription as Tapscript
    envelope = (
        b'\x00'         # OP_FALSE
        b'\x63'         # OP_IF
        + push_bytes(b"ord")
        + push_bytes(b'\x01')
        + push_bytes(content_type.encode())
        + push_bytes(b'')   # OP_0 separator
        + push_data_chunks(content)  # Split into 520-byte chunks (max push size)
        + b'\x68'       # OP_ENDIF
    )

    # Create reveal transaction spending the commit transaction
    # Commit tx: pay to P2TR(key, script=envelope) — commits to the inscription
    # Reveal tx: spend the commit with the inscription script path

    return tx
```

## BRC-20 Token Protocol

```json
// Deploy a new token
{"p":"brc-20","op":"deploy","tick":"ORDI","max":"21000000","lim":"1000","dec":"18"}

// Mint (anyone can call up to "lim" per inscription, until "max" reached)
{"p":"brc-20","op":"mint","tick":"ORDI","amt":"1000"}

// Transfer (inscribe to commit the transfer, then send the inscription)
{"p":"brc-20","op":"transfer","tick":"ORDI","amt":"500"}
```

**Critical: BRC-20 is NOT enforced by Bitcoin**
- Bitcoin nodes have no idea what "brc-20" means
- Validity is determined by indexers (off-chain software)
- Indexer consensus failures = chaos (happened multiple times)
- The "transfer" operation is a 2-step process: inscribe the transfer intent, then send the sat to the recipient
- This is awkward UX — one reason Runes replaced it

## Runes — UTXO-Native Fungible Tokens

```
Runes are more Bitcoin-native:
  - Live in UTXOs (not arbitrary sats)
  - Use OP_RETURN for all operations (no junk UTXOs)
  - No inscription overhead
  - Launched with Bitcoin halving in April 2024

Runestone: data in OP_RETURN output that encodes rune operations
Cenotaph: malformed runestone → all runes in that tx burned (penalty)

Etching (deploy):
  Runestone {
    etching: Some(Etching {
      rune: Some(Rune::from("UNCOMMON•GOODS")),  // Name with spacers
      divisibility: Some(0),
      symbol: Some('⧫'),
      premine: Some(1_000_000),   // Initial supply to etcher
      terms: Some(Terms {
        amount: Some(1),           // Mintable amount per mint
        cap: Some(1_000_000_000),  // Max total mints
        height: (Some(840_000), Some(1_050_000)),  // Valid block range
        offset: (None, None),
      }),
      turbo: false,
    }),
    ...
  }

Transfer via edict:
  Runestone {
    edicts: vec![Edict {
      id: RuneId { block: 840000, tx: 1 },  // Which rune
      amount: 100,                           // How many
      output: 0,                             // Send to which output index
    }],
    ...
  }
```

## Stacks — Smart Contracts on Bitcoin

```clarity
;; Clarity (Stacks smart contract language)
;; Decidable: you can always know if a function will succeed before executing it
;; No reentrancy by design (no dynamic dispatch)

(define-fungible-token sparta-token u100000000)

(define-public (transfer (amount uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) (err u401))
    (ft-transfer? sparta-token amount sender recipient)
  )
)

;; Post-conditions: Bitcoin-level security guarantee
;; Caller can specify: "this tx must transfer exactly X STX/tokens or it fails"
;; Prevents rug pulls in Clarity contracts
(define-public (safe-swap (amount uint))
  ;; Post-condition enforced at protocol level: if token not sent, tx fails
  (begin
    (try! (contract-call? .token-contract transfer amount tx-sender contract-caller))
    (stx-transfer? (* amount price) (as-contract tx-sender) tx-sender)
  )
)
```

## When to Use Bitcoin Ecosystem

- **Ordinals**: rare/collectible NFTs where "Bitcoin-backed" permanence justifies the complexity
- **Runes**: fungible tokens with Bitcoin-level security (no bridge risk, no smart contract risk)
- **Stacks**: DeFi that settles on Bitcoin, for audiences who want Bitcoin yield
- **Lightning**: microtransactions, streaming payments in BTC
- **BitVM**: fraud-proof computation (still early but enables complex logic on Bitcoin without consensus changes)
