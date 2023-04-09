pragma solidity ^0.8.0;

import "./AlumDAOTestAdmin.sol";

contract AlumDAOTestUniversity is AlumDAOTestAdmin {


    function addUniversityToAlumni(address alum, uint256 universityId) public onlyAdmin {
        _universities[alum].push(universityId);
    }

    function removeUniversityFromAlumni(address alum, uint256 universityId) public onlyAdmin {
        uint256[] storage universities = _universities[alum];

        for (uint256 i = 0; i < universities.length; i++) {
            if (universities[i] == universityId) {
                universities[i] = universities[universities.length - 1];
                universities.pop();
                break;
            }
        }
    }

    function addAffiliatedUniversity(uint256 universityId, uint256 affiliatedUniversityId) public {
        _affiliatedUniversities[universityId].push(affiliatedUniversityId);
    }

    function updateUniversityAssociation(address patron, uint256 association) public onlyAdmin {
        _universityAssociation[patron] = association;
    }

    function updateAffiliation(uint256 universityId, uint256 affiliateUniversityId, bool isAffiliated) public onlyAdmin {
        _affiliationDeals[universityId][affiliateUniversityId] = isAffiliated;
    }

    function getAffiliatedUniversities(uint256 universityId) public view returns (uint256[] memory) {
        return _affiliatedUniversities[universityId];
    }

    function isAffiliated(uint256 universityId1, uint256 universityId2) public view returns (bool) {
        return _affiliationDeals[universityId1][universityId2];
    }

    function getAlumniUniversities(address alum) public view returns (uint256[] memory) {
        return _universities[alum];
    }

    function getUniversityAssociationScore(address patron) public view returns (uint256) {
        uint256 universityAssociation = _universityAssociation[patron];
        uint256 universityAssociationScore = 0;

        if (universityAssociation == 1) {
            universityAssociationScore = 1;
        } else if (universityAssociation == 2) {
            universityAssociationScore = 3;
        } else if (universityAssociation == 3) {
            universityAssociationScore = 5;
        }

        return universityAssociationScore;
    }

}
