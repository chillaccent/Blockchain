pragma solidity ^0.8.0;

import "./AlumDAOTestUniversity.sol";

contract AlumDAOTestEducation is AlumDAOTestUniversity {

    function updateEducationLevel(address patron, uint256 level) public onlyAdmin {
        _educationLevel[patron] = level;
    }

    function getEducationScore(address patron) public view returns (uint256) {
        uint256 educationLevel = _educationLevel[patron];
        uint256 educationScore = 0;

        if (educationLevel == 1) {
            educationScore = 1;
        } else if (educationLevel == 2) {
            educationScore = 3;
        } else if (educationLevel == 3) {
            educationScore = 5;
        }

        return educationScore;
    } 
}
