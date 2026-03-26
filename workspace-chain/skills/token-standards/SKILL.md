# Token Standards

## ERC-20 (Fungible Tokens)
**Use for**: Currency, utility tokens, governance tokens, stablecoins, LP tokens

### Core Interface
```solidity
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
```

### Extensions
- **ERC-20Permit (EIP-2612)**: Gasless approvals via EIP-712 signatures. User signs off-chain, protocol submits permit + transferFrom in one tx.
- **ERC-20Votes**: Snapshot-based voting power. Checkpoints at every transfer. Required for governance.
- **ERC-20Burnable**: `burn(amount)` and `burnFrom(account, amount)`.
- **ERC-20Capped**: Max supply enforced in `_mint()`.
- **ERC-20Pausable**: Owner can pause all transfers (emergency stop).

### Gotchas — Non-Standard Tokens
| Token | Issue | Solution |
|-------|-------|----------|
| USDT | `transfer()` doesn't return bool | Use SafeERC20 |
| Fee-on-transfer tokens | Received amount < sent amount | Check balance before/after |
| Rebasing tokens (stETH) | Balance changes without transfers | Use wstETH (wrapped) |
| Blocklist tokens (USDC) | Addresses can be blocked from transfers | Handle transfer failures gracefully |
| Upgradeable tokens | Behavior can change | Monitor for upgrades |

**ALWAYS use OpenZeppelin's SafeERC20 for external token interactions.**

## ERC-721 (Non-Fungible Tokens)
**Use for**: Unique digital assets, NFT collections, deeds, certificates

### Core Interface
```solidity
interface IERC721 {
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
```

### Extensions
- **ERC721Metadata**: `name()`, `symbol()`, `tokenURI(uint256 tokenId)`
- **ERC721Enumerable**: `totalSupply()`, `tokenByIndex()`, `tokenOfOwnerByIndex()` — expensive gas, avoid if not needed
- **ERC721URIStorage**: Per-token custom URI storage

### Patterns
- **Lazy minting**: Don't mint on-chain until purchased. Save gas for unsold tokens.
- **Merkle allowlists**: Verify eligibility via Merkle proof instead of storing all addresses.
- **Reveal**: Mint with placeholder URI, reveal real metadata later via URI update.

## ERC-1155 (Multi-Token)
**Use for**: Game items, prediction market outcome tokens, mixed fungible + non-fungible

### Key Advantage
Single contract for multiple token types. Batch operations save gas.
```solidity
interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
    function setApprovalForAll(address operator, bool approved) external;
}
```
- Token ID determines type (fungible or unique based on supply)
- Perfect for prediction markets: each outcome is a token ID
- Gnosis Conditional Token Framework is built on ERC-1155

## ERC-4626 (Tokenized Vaults)
**Use for**: Yield-bearing tokens, staking positions, any deposit→shares pattern

```solidity
interface IERC4626 is IERC20 {
    function asset() external view returns (address);
    function totalAssets() external view returns (uint256);
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
    function mint(uint256 shares, address receiver) external returns (uint256 assets);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
    function convertToShares(uint256 assets) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
}
```

### ⚠️ CRITICAL: First Depositor / Inflation Attack
**Attack**: First depositor deposits 1 wei, then donates large amount to vault, inflating share price. Next depositor's shares round to 0.
**Prevention**: Virtual shares/assets offset (OpenZeppelin 4.9+), or initial dead shares deposit by the protocol.

## Other Key Standards

### EIP-712 (Typed Structured Data Signing)
Standard for signing structured data off-chain. Used by Permit, meta-transactions, order books.
```solidity
bytes32 constant DOMAIN_TYPEHASH = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
);
```

### EIP-4337 (Account Abstraction)
Smart contract wallets with UserOperations, Bundlers, EntryPoint, Paymasters. See account-abstraction skill.

### EIP-1167 (Minimal Proxy / Clones)
Deploy cheap copies of a contract. ~45 bytes of bytecode, delegates all calls to implementation.

### EIP-2535 (Diamond Standard)
Multiple implementation contracts (facets) behind one proxy. Function selector → facet routing.

### EIP-7702 (Set EOA Code)
Allows EOAs to temporarily adopt smart contract code. Bridges EOA and smart wallet worlds.

### EIP-5192 (Soulbound Tokens)
Non-transferable tokens. `locked(uint256 tokenId)` returns true if token can't be transferred.

### ERC-2981 (Royalty Standard)
```solidity
function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);
```
Standard way to signal royalty info. Not enforced on-chain by default — requires marketplace cooperation or transfer hooks.
