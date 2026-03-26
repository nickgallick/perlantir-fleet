# ZK Rollup App Development

## StarkNet / Cairo

```cairo
// src/lib.cairo — Simple storage contract
#[starknet::contract]
mod SpartaChallenge {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use core::hash::HashStateTrait;
    use core::pedersen::PedersenTrait;

    #[storage]
    struct Storage {
        owner: ContractAddress,
        prize_pool: u256,
        submissions: LegacyMap::<felt252, ByteArray>,  // challengeId → submission
        scores: LegacyMap::<(felt252, ContractAddress), u64>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        SubmissionRecorded: SubmissionRecorded,
    }

    #[derive(Drop, starknet::Event)]
    struct SubmissionRecorded {
        #[key]
        challenge_id: felt252,
        #[key]
        competitor: ContractAddress,
        timestamp: u64,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
    }

    #[abi(embed_v0)]
    impl SpartaChallengeImpl of super::ISpartaChallenge<ContractState> {
        fn submit(ref self: ContractState, challenge_id: felt252, answer_hash: ByteArray) {
            let caller = get_caller_address();
            self.submissions.write(challenge_id, answer_hash);

            self.emit(SubmissionRecorded {
                challenge_id,
                competitor: caller,
                timestamp: get_block_timestamp(),
            });
        }

        fn get_score(self: @ContractState, challenge_id: felt252, competitor: ContractAddress) -> u64 {
            self.scores.read((challenge_id, competitor))
        }
    }
}
```

```bash
# Build
scarb build

# Test
scarb test

# Deploy to StarkNet Sepolia
starkli declare target/dev/sparta_SpartaChallenge.contract_class.json \
  --account ~/.starkli-wallets/deployer/account.json \
  --keystore ~/.starkli-wallets/deployer/keystore.json

starkli deploy CLASS_HASH OWNER_ADDRESS \
  --account ~/.starkli-wallets/deployer/account.json

# Call a function
starkli call CONTRACT_ADDRESS get_score CHALLENGE_ID COMPETITOR_ADDRESS
```

## zkSync Era

### Key Differences From Mainnet

```solidity
// zkSync-safe Solidity — avoid these patterns:
// ❌ SELFDESTRUCT — not supported
// ❌ EXTCODECOPY — not supported  
// ❌ block.difficulty — returns 2500000000000000 always
// ⚠️  CREATE/CREATE2 — use SystemContractsCaller for factory patterns
// ⚠️  Libraries must be deployed separately (not linked at compile time)

// ✅ Standard ERC-20 works fine
// ✅ OpenZeppelin contracts work with minor adjustments
// ✅ Reentrancy guards work
// ✅ Proxy patterns work (with caveats on constructor logic)
```

```typescript
// hardhat.config.ts — zkSync setup
import "@matterlabs/hardhat-zksync-solc";
import "@matterlabs/hardhat-zksync-deploy";

const config = {
  zksolc: {
    version: "latest",
    settings: {
      optimizer: { enabled: true, mode: "3" },
    },
  },
  networks: {
    zkSyncMainnet: {
      url: "https://mainnet.era.zksync.io",
      ethNetwork: "mainnet",
      zksync: true,
    },
    zkSyncSepoliaTestnet: {
      url: "https://sepolia.era.zksync.dev",
      ethNetwork: "sepolia",
      zksync: true,
    },
  },
  solidity: { version: "0.8.23" },
};
```

```typescript
// deploy/deploy.ts — zkSync deployment
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import { Wallet } from "zksync-ethers";
import * as hre from "hardhat";

export default async function () {
  const wallet  = new Wallet(process.env.PRIVATE_KEY!);
  const deployer = new Deployer(hre, wallet);

  const artifact = await deployer.loadArtifact("SpartaChallenge");

  // Fee estimation (includes pubdata cost — unique to zkSync)
  const deploymentFee = await deployer.estimateDeployFee(artifact, []);
  console.log(`Deployment fee: ${hre.ethers.formatEther(deploymentFee)} ETH`);

  const contract = await deployer.deploy(artifact, [/* constructor args */]);
  await contract.waitForDeployment();

  console.log("Deployed to:", await contract.getAddress());
}
```

## Native Account Abstraction on zkSync

```solidity
// IAccount implementation — every zkSync account is a smart contract
import "@matterlabs/zksync-contracts/l2/system-contracts/interfaces/IAccount.sol";
import "@matterlabs/zksync-contracts/l2/system-contracts/libraries/TransactionHelper.sol";

contract SpartaSmartAccount is IAccount {
    using TransactionHelper for Transaction;

    address public owner;

    bytes4 constant EIP1271_MAGIC_VALUE = 0x1626ba7e;

    function validateTransaction(
        bytes32,
        bytes32 suggestedSignedHash,
        Transaction calldata _transaction
    ) external payable override returns (bytes4 magic) {
        // Validate the signer
        bytes32 txHash = _transaction.encodeHash();
        address recovered = ECDSA.recover(txHash, _transaction.signature);

        if (recovered == owner) {
            magic = ACCOUNT_VALIDATION_SUCCESS_MAGIC; // 0x6aa7c513
        } else {
            magic = bytes4(0); // Validation failed
        }
    }

    function executeTransaction(
        bytes32,
        bytes32,
        Transaction calldata _transaction
    ) external payable override {
        address to = address(uint160(_transaction.to));
        uint128 value = Utils.safeCastToU128(_transaction.value);
        bytes memory data = _transaction.data;

        (bool success,) = to.call{value: value}(data);
        require(success, "Transaction execution failed");
    }

    // zkSync calls this to pay gas — unlike ERC-4337, no separate paymaster required
    function payForTransaction(
        bytes32,
        bytes32,
        Transaction calldata _transaction
    ) external payable override {
        bool success = _transaction.payToTheBootloader();
        require(success, "Failed to pay");
    }

    function prepareForPaymaster(
        bytes32,
        bytes32,
        Transaction calldata _transaction
    ) external payable override {
        _transaction.processPaymasterInput();
    }

    receive() external payable {}
}
```

## Gas Model Differences

```
zkSync Era gas breakdown:
  execution_gas: normal EVM execution gas
  pubdata_gas: cost of publishing storage diffs to L1

Total fee = execution_gas × gas_price + pubdata_bytes × pubdata_price

Optimization:
  - Reduce storage writes (pubdata is the expensive part)
  - Pack variables (smaller storage diffs)
  - Use calldata instead of storage for temporary values
  - Batch operations to amortize pubdata cost across multiple ops
```
