# Safe Multisig Operations

## $500K Treasury Operation Ceremony

### Pre-Ceremony (48 Hours Before)

```
□ Agree on the transaction in writing (Notion/Telegram/email)
  - Exact recipient address (not ENS — resolve ENS and record the 0x address)
  - Exact USDC amount (e.g., 500,000.000000 — include all decimal places)
  - Purpose and authorization (link to governance vote or approval thread)
  - Deadline (when must this execute by)

□ Share the RESOLVED address through a secondary channel (Signal, voice call)
  - Do NOT rely solely on the primary comms channel — it could be compromised
  - Each signer independently verifies the recipient address from the original source

□ Each signer confirms Ledger is charged and firmware is up to date
  - Check: Settings → Device → Firmware on the Ledger itself
  - Update if not on latest — security patches matter

□ Remind all signers: NEVER sign on the browser UI alone
  - The browser can show you a different address than what's on the Ledger screen
  - The Ledger screen is the ONLY source of truth
```

### Transaction Proposal

```typescript
// Proposer creates the tx programmatically (or via Safe UI)
import SafeApiKit from "@safe-global/api-kit";
import Safe, { EthersAdapter } from "@safe-global/protocol-kit";
import { MetaTransactionData } from "@safe-global/safe-core-sdk-types";
import { ethers } from "ethers";

const SAFE_ADDRESS = "0x...";  // Treasury Safe address
const USDC_ADDRESS = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
const RECIPIENT    = "0x...";  // VERIFIED recipient
const AMOUNT_USDC  = "500000000000"; // 500,000 USDC (6 decimals)

async function proposeTx(signerKey: string) {
    const provider   = new ethers.JsonRpcProvider(process.env.RPC_URL);
    const signer     = new ethers.Wallet(signerKey, provider);
    const ethAdapter = new EthersAdapter({ ethers, signerOrProvider: signer });
    const safe       = await Safe.create({ ethAdapter, safeAddress: SAFE_ADDRESS });
    const apiKit     = new SafeApiKit({ chainId: 1n });

    const usdcInterface = new ethers.Interface(["function transfer(address,uint256)"]);
    const txData = usdcInterface.encodeFunctionData("transfer", [RECIPIENT, AMOUNT_USDC]);

    const tx: MetaTransactionData = {
        to:    USDC_ADDRESS,
        value: "0",
        data:  txData,
    };

    const safeTx    = await safe.createTransaction({ transactions: [tx] });
    const safeTxHash = await safe.getTransactionHash(safeTx);
    const sig        = await safe.signTransactionHash(safeTxHash);

    await apiKit.proposeTransaction({
        safeAddress:         SAFE_ADDRESS,
        safeTransactionData: safeTx.data,
        safeTxHash,
        senderAddress:  await signer.getAddress(),
        senderSignature: sig.data,
    });

    // Share this hash with all signers
    console.log("Safe Transaction Hash:", safeTxHash);
    // This hash UNIQUELY identifies this transaction
    // All signers must verify THIS hash corresponds to the correct tx details
}
```

### Each Signer's Checklist

```
BEFORE SIGNING:
□ Open app.safe.global → navigate to your Safe → Transactions → Queue
□ Find the pending transaction with the correct hash
□ Click on it — verify the details in the UI:
  - To: USDC contract (0xA0b8...)
  - Function: transfer(address, uint256)
  - Parameters:
    - recipient: 0x[EXPECTED ADDRESS] ← compare character by character
    - amount: 500000000000 ← 500,000 USDC (move decimal 6 places)

□ Connect Ledger via USB (not Bluetooth for signing)
□ Open Ethereum app on Ledger
□ Click "Sign" in the Safe UI

ON THE LEDGER SCREEN — VERIFY:
□ Screen 1: "Review transaction" or "Sign typed data"
□ Scroll through ALL screens on the Ledger
□ Verify the recipient address shown on Ledger matches expected
□ Verify the amount shown on Ledger: 500000.000000 USDC or 500000000000 raw
□ If ANYTHING doesn't match what you expected — DO NOT SIGN. Abort and alert others.

AFTER SIGNING:
□ Confirm signature appears in the Safe UI
□ Notify other signers via secondary channel that you've signed
```

### Execution

```
Once threshold is met (e.g., 3 of 5 signatures collected):

□ Any signer can execute
□ Executor checks gas estimate is reasonable (<$5 for USDC transfer on mainnet, less on L2)
□ Execute via Safe UI or programmatically:

    const executeTxResponse = await safe.executeTransaction(pendingTx);
    await executeTxResponse.transactionResponse?.wait();

□ Record the on-chain transaction hash
□ Verify on Etherscan:
  - From: Safe address
  - To: USDC contract
  - Function: transfer
  - Recipient: CORRECT address
  - Amount: 500,000 USDC

□ Notify all parties: tx confirmed, hash, block number
```

### Red Flags — Stop Everything

```
ABORT AND ALERT if any of these happen:

1. Ledger screen shows a different address than expected
   → DO NOT SIGN. Transaction may have been tampered with.

2. Someone messages urgently saying "sign quickly, no time to verify"
   → SOCIAL ENGINEERING. Legitimate treasury ops are never rushed.

3. The Safe UI shows different details than what was agreed
   → Possible malicious transaction injection. Verify Safe Transaction Hash.

4. A signer's Ledger shows "blind signing" warning
   → Contract data not being decoded — high risk. Only proceed if you understand the raw calldata.

5. More than 24 hours since the transaction was proposed with no explanation
   → Check if Safe was compromised. Verify with each signer independently.
```

## Programmatic Safe Interaction

```typescript
// Check Safe state before any operation
async function auditSafe(safeAddress: string) {
    const safe = await Safe.create({ ethAdapter, safeAddress });

    console.log("Owners:", await safe.getOwners());
    console.log("Threshold:", await safe.getThreshold());
    console.log("Nonce:", await safe.getNonce());
    console.log("Balance:", await provider.getBalance(safeAddress));

    // Verify no unexpected pending transactions
    const pending = await apiKit.getPendingTransactions(safeAddress);
    console.log("Pending txs:", pending.results.length);
    if (pending.results.length > 0) {
        console.log("⚠️ There are pending transactions. Review before proceeding.");
    }
}
```
