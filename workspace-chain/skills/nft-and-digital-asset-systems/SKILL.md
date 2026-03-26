# NFT & Digital Asset Systems

## Beyond Basic ERC-721

### Royalty Standard (ERC-2981)
Signal royalty info to marketplaces (not enforced on-chain, requires marketplace cooperation).
```solidity
contract RoyaltyNFT is ERC721, ERC2981 {
    constructor() ERC721("MyNFT", "NFT") {}

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        override
        returns (address, uint256)
    {
        address royaltyAddress = owner();
        uint256 royaltyAmount = (salePrice * 500) / 10_000;  // 5% royalty
        return (royaltyAddress, royaltyAmount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
```

### Soulbound Tokens (ERC-5192)
Non-transferable NFTs (certificates, credentials, achievements).
```solidity
interface IERC5192 {
    function locked(uint256 tokenId) external view returns (bool);
}

contract SoulboundNFT is ERC721, IERC5192 {
    mapping(uint256 => bool) public _locked;

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override
    {
        if (from != address(0) && to != address(0)) {
            require(!_locked[tokenId], "Token is soulbound");
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function locked(uint256 tokenId) external view returns (bool) {
        return _locked[tokenId];
    }
}
```

### On-Chain Metadata
Metadata generated dynamically instead of URI to immutable IPFS.
```solidity
contract DynamicNFT is ERC721 {
    mapping(uint256 => Data) public tokenData;

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Token doesn't exist");

        Data memory data = tokenData[tokenId];
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name":"Token #', tokenId.toString(),
            '","description":"Dynamic metadata",',
            '"level":', data.level.toString(),
            ',"power":', data.power.toString(),
            '}'
        ))));
        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}
```

### Lazy Minting
Don't mint on-chain until purchased. Save gas for unsold inventory.
```solidity
contract LazyMintNFT {
    struct Voucher {
        uint256 tokenId;
        uint256 price;
        string uri;
        bytes signature;
    }

    function redeem(Voucher calldata voucher) external payable {
        require(msg.value >= voucher.price, "Insufficient payment");

        // Verify signature
        bytes32 hash = keccak256(abi.encode(voucher));
        require(recoverSigner(hash, voucher.signature) == minter, "Invalid signature");

        // Mint on redemption
        _mint(msg.sender, voucher.tokenId);
        _setTokenURI(voucher.tokenId, voucher.uri);
    }
}
```

### Merkle Tree Allowlist
Efficient allowlist verification for NFT mints.
```solidity
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract AllowlistNFT is ERC721 {
    bytes32 public allowlistRoot;
    mapping(address => bool) public hasMinted;

    function mintWithProof(bytes32[] calldata proof) external {
        require(!hasMinted[msg.sender], "Already minted");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, allowlistRoot, leaf), "Not in allowlist");

        hasMinted[msg.sender] = true;
        _mint(msg.sender, totalSupply());
    }
}
```

## Advanced: ERC-1155 (Multi-Token)
Single contract for fungible + non-fungible assets.
```solidity
contract GameAssets is ERC1155 {
    uint256 constant GOLD = 0;      // Fungible
    uint256 constant SWORD_NFT = 1; // Non-fungible (only minted once)

    function mintGold(address to, uint256 amount) external {
        _mint(to, GOLD, amount, "");
    }

    function mintSword(address to) external {
        _mint(to, SWORD_NFT, 1, "");
    }

    function batchTransfer(address to, uint256[] calldata ids, uint256[] calldata amounts) external {
        _safeBatchTransferFrom(msg.sender, to, ids, amounts, "");
    }
}
```

## OpenSea Integration
Seaport protocol for marketplace orders.
```solidity
// Standard ERC-2981 royalties
function royaltyInfo(uint256, uint256 salePrice) external view returns (address, uint256) {
    return (owner(), (salePrice * 500) / 10000);  // 5%
}

// Implement onERC721Received if you're an auction/escrow contract
function onERC721Received(address, address, uint256, bytes calldata) public pure returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
}
```

## NFT Security Considerations
- **Enumerable contracts are expensive**: `tokenOfOwnerByIndex()` can gas-grief. Avoid unless necessary.
- **Metadata mismatch**: If URI points to mutable IPFS, metadata can change post-purchase.
- **Permit vulnerabilities**: ERC-721 Permit (EIP-4494) has some edge cases. Use battle-tested implementations.
- **Reentrancy in callbacks**: `onERC721Received` is a callback. Can reentrancy-attack if not careful.

## Use Case for Agent Sparta: Achievement NFTs
Mint Soulbound NFTs for challenge winners:
```solidity
contract ChallengeAchievement is ERC721, IERC5192 {
    mapping(uint256 => bool) _locked;  // All achievements are soulbound

    function mintAchievement(address winner, string memory challengeName) external onlyOperator {
        uint256 tokenId = totalSupply();
        _mint(winner, tokenId);
        _setTokenURI(tokenId, generateURI(challengeName));
        _locked[tokenId] = true;
    }
}
```
Winners get a non-transferable proof of victory. Can't be sold, purely for bragging rights.
