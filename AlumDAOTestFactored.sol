pragma solidity ^0.8.0;

pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./AlumDAOTestScore.sol";

contract AlumDAOTestFactored is AlumDAOTestScore {
    // Keep the remaining functions here
    // ...
    // Set affiliation deal between two universities
    function setAffiliationDeal(uint256 universityId1, uint256 universityId2) public {
        _affiliationDeals[universityId1][universityId2] = true;
    }

    

    // Mint function with updated associated score logic
    function mint(uint256 educationLevel, uint256 universityId) public {
        require(!_active[msg.sender], "Already active");
        require(_allowed[msg.sender], "Account not allowed to mint NFT");
        _educationLevel[msg.sender] = educationLevel;

    uint256 associatedScore = 1; // Default value for non-affiliated university
    for (uint256 i = 0; i < _universities[msg.sender].length; i++) {
        uint256 alumniUniversityId = _universities[msg.sender][i];
        if (alumniUniversityId == universityId) {
            associatedScore = 3; // Value for alma mater
        } else if (_affiliationDeals[alumniUniversityId][universityId]) {
            associatedScore = 2; // Value for affiliated university
            break;
        }
    }
    _universityAssociation[msg.sender] = associatedScore;

    uint256 tokenId = totalSupply() +1;
    _safeMint(msg.sender, tokenId);
    _ownershipHistory[tokenId].push(msg.sender);
    _lastActivity[msg.sender] = uint32(block.timestamp);
    _active[msg.sender] = true;
}


    function batchUpdate(address[] calldata alumni, uint256[] calldata educationLevels, uint256[] calldata universityAssociations, uint256[] calldata donations, uint256[] calldata workContributions) public onlyAdmin {
    require(alumni.length == educationLevels.length && alumni.length == universityAssociations.length && alumni.length == donations.length && alumni.length == workContributions.length, "Array lengths do not match");
    
    for (uint256 i = 0; i < alumni.length; i++) {
        address alum = alumni[i];
        _educationLevel[alum] = educationLevels[i];
        _universityAssociation[alum] = universityAssociations[i];
        _donations[alum] = donations[i];
        _workContributions[alum] = workContributions[i];
    }
}


    function revokeNFT(uint256 tokenId) public onlyAdmin {
        address owner = ownerOf(tokenId);

        // Update last activity and active status
        _lastActivity[owner] = uint32(block.timestamp);
        _active[owner] = false;
        _burn(tokenId);
    }

    // Replace _ownershipHistory with a local variable
    function getOwnershipHistory(uint256 tokenId) public view returns (address[] memory) {
        address[] storage history = _ownershipHistory[tokenId];
        return history;
    }
}