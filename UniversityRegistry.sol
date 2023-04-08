pragma solidity ^0.8.0;

contract UniversityRegistry {
    mapping(uint256 => uint256) public tokenIdToUniversityId;
    mapping(uint256 => bool) public universityIdExists;
    mapping(uint256 => mapping(uint256 => bool)) public universityAffiliations;

    function addUniversity(uint256 universityId) external {
        require(!universityIdExists[universityId], "University already exists");
        universityIdExists[universityId] = true;
    }

    function removeUniversity(uint256 universityId) external {
        require(universityIdExists[universityId], "University does not exist");
        universityIdExists[universityId] = false;
    }

    function addUniversityAffiliation(uint256 universityId, uint256 affiliatedUniversityId) external {
        require(universityIdExists[universityId], "University does not exist");
        require(universityIdExists[affiliatedUniversityId], "Affiliated university does not exist");
        universityAffiliations[universityId][affiliatedUniversityId] = true;
    }

    function removeUniversityAffiliation(uint256 universityId, uint256 affiliatedUniversityId) external {
        require(universityIdExists[universityId], "University does not exist");
        require(universityIdExists[affiliatedUniversityId], "Affiliated university does not exist");
        universityAffiliations[universityId][affiliatedUniversityId] = false;
    }

    function updateUniversityAffiliation(uint256 universityId, uint256 affiliatedUniversityId, bool isAffiliated) external {
        require(universityIdExists[universityId], "University does not exist");
        require(universityIdExists[affiliatedUniversityId], "Affiliated university does not exist");
        universityAffiliations[universityId][affiliatedUniversityId] = isAffiliated;
    }
}

contract NFTContract {
    UniversityRegistry public universityRegistry;

    constructor(address _universityRegistryAddress) {
        universityRegistry = UniversityRegistry(_universityRegistryAddress);
    }

    function mintNFT(uint256 tokenId, uint256 universityId) external {
        require(universityRegistry.universityIdExists[universityId], "University does not exist");
        universityRegistry.tokenIdToUniversityId[tokenId] = universityId;
        // mint NFT with tokenId and universityId
    }

    function updateUniversityAffiliation(uint256 universityId, uint256 affiliatedUniversityId, bool isAffiliated) external {
        universityRegistry.updateUniversityAffiliation(universityId, affiliatedUniversityId, isAffiliated);
    }
}
