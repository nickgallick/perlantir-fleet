# Multi-Signature & Key Management

## Safe Setup — Production Configuration

```typescript
import SafeApiKit from "@safe-global/api-kit";
import Safe, { SafeFactory } from "@safe-global/protocol-kit";
import { MetaTransactionData } from "@safe-global/safe-core-sdk-types";

async function setupSpartaTreasury() {
    const provider  = new ethers.JsonRpcProvider(process.env.BASE_RPC);
    const deployer  = new ethers.Wallet(process.env.DEPLOYER_KEY!, provider);

    const ethAdapter = new EthersAdapter({ ethers, signerOrProvider: deployer });
    const safeFactory = await SafeFactory.create({ ethAdapter });

    // 3-of-5 treasury multisig
    const safeAccountConfig = {
        owners: [
            process.env.NICK_ADDRESS!,         // Nick
            process.env.COFOUNDER_ADDRESS!,    // Co-founder
            process.env.ADVISOR1_ADDRESS!,     // Advisor 1
            process.env.ADVISOR2_ADDRESS!,     // Advisor 2
            process.env.COMMUNITY_ADDRESS!,    // Community rep
        ],
        threshold: 3
    };

    const safe = await safeFactory.deploySafe({ safeAccountConfig });
    const safeAddress = await safe.getAddress();
    console.log(`Treasury Safe: ${safeAddress}`);

    // Verify setup
    const owners    = await safe.getOwners();
    const threshold = await safe.getThreshold();
    console.log(`Owners: ${owners.join(", ")}`);
    console.log(`Threshold: ${threshold}`);

    return safeAddress;
}
```

## Propose & Execute Multisig Transaction

```typescript
async function proposePrizePayment(
    safeAddress: string,
    winner: string,
    amount: bigint,
    proposerSigner: ethers.Signer
) {
    const ethAdapter = new EthersAdapter({ ethers, signerOrProvider: proposerSigner });
    const safe = await Safe.create({ ethAdapter, safeAddress });
    const apiKit = new SafeApiKit({ chainId: 8453n }); // Base

    const transactions: MetaTransactionData[] = [{
        to:    USDC_ADDRESS,
        value: "0",
        data:  usdc.interface.encodeFunctionData("transfer", [winner, amount])
    }];

    // Create safe transaction
    const safeTransaction = await safe.createTransaction({ transactions });

    // Proposer signs and proposes
    const safeTxHash = await safe.getTransactionHash(safeTransaction);
    const senderSig  = await safe.signTransactionHash(safeTxHash);

    // Submit to Safe Transaction Service
    await apiKit.proposeTransaction({
        safeAddress,
        safeTransactionData: safeTransaction.data,
        safeTxHash,
        senderAddress: await proposerSigner.getAddress(),
        senderSignature: senderSig.data,
    });

    console.log(`Transaction proposed: ${safeTxHash}`);
    return safeTxHash;
}

async function confirmAndExecute(
    safeAddress: string,
    safeTxHash: string,
    signers: ethers.Signer[]
) {
    const apiKit = new SafeApiKit({ chainId: 8453n });

    // Collect signatures from threshold signers
    for (const signer of signers) {
        const ethAdapter = new EthersAdapter({ ethers, signerOrProvider: signer });
        const safe = await Safe.create({ ethAdapter, safeAddress });
        const sig = await safe.signTransactionHash(safeTxHash);
        await apiKit.confirmTransaction(safeTxHash, sig.data);
        console.log(`Confirmed by: ${await signer.getAddress()}`);
    }

    // Execute once threshold is reached
    const lastSigner = signers[signers.length - 1];
    const ethAdapter = new EthersAdapter({ ethers, signerOrProvider: lastSigner });
    const safe = await Safe.create({ ethAdapter, safeAddress });

    const pendingTx = await apiKit.getTransaction(safeTxHash);
    const executeTxResponse = await safe.executeTransaction(pendingTx);
    await executeTxResponse.transactionResponse?.wait();
    console.log(`Executed: ${executeTxResponse.hash}`);
}
```

## Hardware Key Ceremony

```
PRE-CEREMONY CHECKLIST:
  □ Each signer has verified hardware wallet (Ledger Nano X or Trezor Model T)
  □ Hardware wallets purchased directly from manufacturer — never secondhand
  □ Fresh seed phrase generated ON the device — never on a computer
  □ Seed backup: 24-word phrase on steel plates (fireproof, waterproof)
  □ Seed plates stored in separate physical locations

CEREMONY PROCEDURE:
  1. Each participant in the same room (or separate Zoom sessions for remote)
  2. Each generates a new address on their hardware wallet
  3. Each signs a test message using their hardware wallet to verify control
  4. Collect all addresses, configure multisig
  5. Test: propose a small test tx, collect all required signatures, execute
  6. Document: record each owner's address in the multisig config docs

BACKUP AND RECOVERY:
  Safe's social recovery: 
    If one owner loses their key → remaining owners can replace that owner address
    Requires threshold signatures to modify owner set
    Process: file governance proposal → collect signatures → execute owner change

OPERATIONAL SECURITY:
  □ Never type seed phrase on any computer
  □ Never photograph seed phrase
  □ Never store seed phrase in password manager
  □ Never share seed phrase with anyone (multisig means you don't need to)
  □ Hardware wallet PIN: never the same as banking PIN
  □ Update hardware wallet firmware before use (security patches)
```

## Tiered Key Management

```
HOT WALLET (automated operations)
  Risk: Key stored on server
  Limit: Max $100/tx, max $1K/day
  Use for: Paying gas for user transactions, small operational expenses
  Storage: Encrypted in AWS Secrets Manager, rotated monthly

WARM WALLET (multisig — operations team)
  Risk: 2-of-3 hardware wallet signatures required
  Limit: Max $10K/tx, max $50K/day
  Use for: Team salaries, vendor payments, approved operational expenses
  Signers: Nick + 2 core team members

COLD WALLET (multisig — treasury)
  Risk: 3-of-5 hardware wallet signatures required
  Limit: No limit — strategic treasury
  Use for: Fundraising, large protocol changes, token allocations
  Signers: 5 trusted stakeholders across geographies
  Emergency pause key: Separate 1-of-5 key only to PAUSE (not to move funds)

KEY ROTATION PLAN:
  □ Hot wallet: rotated monthly (automated)
  □ Warm wallet: owner rotation documented process
  □ Cold wallet: rotate ONLY if compromise suspected or owner leaves
  □ All rotation events: logged and published to community
```

## Safe Modules — Spending Limits

```solidity
// Allowance module: delegate specific spending limits to addresses
// This lets operations team spend up to X USDC without full multisig

// Via Safe Transaction Service:
// Add Allowance Module to Safe
// Set allowance: address 0xOps → USDC → $1000/day limit
// 0xOps can then execute transfers up to $1000/day without 3-of-5 signatures
// Everything above $1000 still requires 3-of-5 multisig

// Useful for:
//   - Paying daily operational expenses (servers, APIs)
//   - Automated prize payouts up to a limit
//   - Emergency operational spending without gathering all signers
```
