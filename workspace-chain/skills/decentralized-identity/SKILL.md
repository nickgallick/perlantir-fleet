# Decentralized Identity

## ENS Integration

```typescript
import { createPublicClient, http } from "viem";
import { mainnet } from "viem/chains";
import { normalize } from "viem/ens";

const client = createPublicClient({ chain: mainnet, transport: http() });

// Forward resolution: name → address
async function resolveENS(name: string): Promise<string | null> {
    return await client.getEnsAddress({ name: normalize(name) });
}

// Reverse resolution: address → name
async function reverseResolve(address: string): Promise<string | null> {
    return await client.getEnsName({ address: address as `0x${string}` });
}

// Get avatar
async function getAvatar(name: string): Promise<string | null> {
    return await client.getEnsAvatar({ name: normalize(name) });
}

// In React — show "nick.eth" instead of "0x1234...abcd"
function AddressDisplay({ address }: { address: string }) {
    const { data: ensName }   = useEnsName({ address, chainId: 1 });
    const { data: ensAvatar } = useEnsAvatar({ name: ensName, chainId: 1 });

    return (
        <div>
            {ensAvatar && <img src={ensAvatar} width={24} height={24} />}
            {ensName ?? `${address.slice(0,6)}...${address.slice(-4)}`}
        </div>
    );
}
```

## EAS (Ethereum Attestation Service)

```typescript
import { EAS, SchemaEncoder } from "@ethereum-attestation-service/eas-sdk";
import { ethers } from "ethers";

// Mainnet EAS address
const EAS_ADDRESS = "0xA1207F3BBa224E2c9c3c6D5aF63D0eb1582Ce587";

// Step 1: Create a schema
// Schema: "address agent, uint256 elo, uint8 tier, string season"
// Register via EAS schema registry (one-time)

const SPARTA_SCHEMA_UID = "0x..."; // After registration

// Step 2: Issue attestation (by Arena contract or admin)
async function attestAgentTier(
    agentAddress: string,
    elo: number,
    tier: number,
    season: string,
    signer: ethers.Signer
) {
    const eas = new EAS(EAS_ADDRESS);
    eas.connect(signer);

    const encoder = new SchemaEncoder("address agent,uint256 elo,uint8 tier,string season");
    const encodedData = encoder.encodeData([
        { name: "agent",  value: agentAddress, type: "address" },
        { name: "elo",    value: elo,          type: "uint256" },
        { name: "tier",   value: tier,         type: "uint8"   },
        { name: "season", value: season,       type: "string"  },
    ]);

    const tx = await eas.attest({
        schema: SPARTA_SCHEMA_UID,
        data: {
            recipient:            agentAddress,
            expirationTime:       0n,    // Never expires
            revocable:            false, // Achievement is permanent
            data:                 encodedData,
        },
    });

    const uid = await tx.wait();
    console.log(`Attestation UID: ${uid}`);
    return uid;
}

// Step 3: Verify attestation (in other contracts or frontends)
async function verifyAgentTier(agentAddress: string, minTier: number): Promise<boolean> {
    const attestations = await eas.getAttestations({
        schema:    SPARTA_SCHEMA_UID,
        recipient: agentAddress
    });

    return attestations.some(a => {
        const decoded = decoder.decodeData(a.data);
        return decoded.tier >= minTier && !a.revocationTime;
    });
}
```

## On-Chain Attestation Contract (Solidity)

```solidity
interface IEAS {
    struct AttestationRequest {
        bytes32 schema;
        AttestationRequestData data;
    }
    struct AttestationRequestData {
        address recipient;
        uint64  expirationTime;
        bool    revocable;
        bytes32 refUID;
        bytes   data;
        uint256 value;
    }
    function attest(AttestationRequest calldata request) external payable returns (bytes32);
}

contract SpartaAttestor {
    IEAS public immutable eas;
    bytes32 public immutable tierSchema;

    constructor(address _eas, bytes32 _schema) {
        eas     = IEAS(_eas);
        tierSchema = _schema;
    }

    // Called when agent achieves Diamond tier on-chain
    function attestDiamondAchievement(address agent) external onlyArena {
        bytes memory data = abi.encode(agent, uint256(2200), uint8(3), "Season1");

        eas.attest(IEAS.AttestationRequest({
            schema: tierSchema,
            data: IEAS.AttestationRequestData({
                recipient:      agent,
                expirationTime: 0,
                revocable:      false,
                refUID:         bytes32(0),
                data:           data,
                value:          0
            })
        }));
    }
}
```

## Gitcoin Passport Sybil Check

```typescript
const PASSPORT_API = "https://api.scorer.gitcoin.co";

async function getPassportScore(address: string): Promise<number> {
    const response = await fetch(
        `${PASSPORT_API}/registry/score/${process.env.PASSPORT_SCORER_ID}/${address}`,
        { headers: { "X-API-Key": process.env.PASSPORT_API_KEY! } }
    );
    const data = await response.json();
    return data.score ?? 0;
}

// Require minimum score 15 for airdrop eligibility
// Score 15+ = likely a real human (not a Sybil)
// Score 0-14 = possible Sybil → require additional verification
```

## SIWE (Sign-In With Ethereum)

```typescript
import { SiweMessage } from "siwe";

// Backend: generate nonce
app.get("/nonce", (req, res) => {
    const nonce = generateNonce();
    req.session.nonce = nonce;
    res.send(nonce);
});

// Frontend: user signs message
const message = new SiweMessage({
    domain:  "sparta.perlantir.ai",
    address: userAddress,
    statement: "Sign in to Agent Sparta",
    uri:     "https://sparta.perlantir.ai",
    version: "1",
    chainId: 8453, // Base
    nonce:   await fetchNonce()
});

const signature = await signer.signMessage(message.prepareMessage());

// Backend: verify
app.post("/verify", async (req, res) => {
    const { message, signature } = req.body;
    const siweMsg = new SiweMessage(message);
    const result  = await siweMsg.verify({ signature, nonce: req.session.nonce });

    if (result.success) {
        req.session.address = result.data.address;
        // Check ENS name, tier attestations, etc.
        const tier = await getAgentTier(result.data.address);
        res.json({ success: true, address: result.data.address, tier });
    }
});
```
