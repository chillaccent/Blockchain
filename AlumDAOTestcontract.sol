pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AlumDAOTest is ERC721, Ownable {
    mapping(address => bool) private _allowed;
    mapping(uint256 => address[]) private _ownershipHistory;
    mapping(uint256 => mapping(address => bool)) private _permissions;

    constructor() ERC721("AlumDAOTest", "ALUMT") {}

    function mint() public {
        require(_allowed[msg.sender], "Account not allowed to mint NFT");
        uint256 tokenId = totalSupply() + 1;
        _safeMint(msg.sender, tokenId);
        _ownershipHistory[tokenId].push(msg.sender);
    }

    function setAllowed(address account, bool allowed) public onlyOwner {
        _allowed[account] = allowed;
    }

    function isAllowed(address account) public view returns (bool) {
        return _allowed[account];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Transfer caller is not owner nor approved");
        require(from == ownerOf(tokenId), "Transfer from account is not owner");
        require(to == address(0), "NFT can only be transferred to the zero address");
        _ownershipHistory[tokenId].push(to);
        super.transferFrom(from, to, tokenId);
    }

    function revokeNFT(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }

    function getOwnershipHistory(uint256 tokenId) public view returns (address[] memory) {
        return _ownershipHistory[tokenId];
    }

    function setPermission(uint256 tokenId, address account, bool allowed) public {
        require(ownerOf(tokenId) == msg.sender || _permissions[tokenId][msg.sender], "Caller is not owner nor has permission");
        _permissions[tokenId][account] = allowed;
    }

    function getPermission(uint256 tokenId, address account) public view returns (bool) {
        return _permissions[tokenId][account];
    }
}