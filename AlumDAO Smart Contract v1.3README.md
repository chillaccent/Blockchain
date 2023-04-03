This is a smart contract for an ERC-721 non-fungible token (NFT) called AccountBoundNFT. It allows for minting NFTs, setting permissions for NFTs, and tracking the ownership history of NFTs.

The contract inherits from the OpenZeppelin ERC721 and Ownable contracts and has three mappings:

_allowed: a private mapping of addresses to a boolean value that determines if an account is allowed to mint an NFT.
_ownershipHistory: a mapping of token IDs to an array of addresses that represents the ownership history of the token.
_permissions: a mapping of token IDs to a mapping of addresses to a boolean value that determines if an account has permission to view, use, or transfer an NFT.
The mint() function allows an account to mint an NFT only if it is allowed to do so, as determined by the _allowed mapping. If the account is allowed, a new token ID is generated, the NFT is minted, and the address of the account that minted the NFT is added to the ownership history of the token.

The setAllowed() function allows the contract owner to set whether an account is allowed to mint NFTs.

The isAllowed() function returns a boolean value indicating whether an account is allowed to mint NFTs.

The transferFrom() function overrides the OpenZeppelin ERC721 transferFrom() function and ensures that an NFT can only be transferred to the zero address. The ownership history of the token is updated with the new address of the owner.

The revokeNFT() function allows the contract owner to burn an NFT.

The getOwnershipHistory() function returns an array of addresses that represents the ownership history of an NFT.

The setPermission() function allows the owner of an NFT or an account with permission to set whether another account is allowed to view, use, or transfer the NFT.

The getPermission() function returns a boolean value indicating whether an account is allowed to view, use, or transfer an NFT.