pragma solidity ^0.8.0;

import "./AlumDAOTestActivity.sol";

contract AlumDAOTestScore is AlumDAOTestActivity {
    // Move scoring-related functions and logic here
    // ...

            function isActive(address patron) public view returns (bool) {
        return _active[patron];
    }


    function getLifetimeScore(address patron) public view returns (uint256) {
        uint256 lifetimeDonations = _donations[patron] * 5;
        uint256 lifetimeWorkContributions = _workContributions[patron] * (15);

        uint256 lifetimeScore = lifetimeDonations + (lifetimeWorkContributions);

        return lifetimeScore;
    }


    function getScore(address patron) public view returns (uint256) {
        uint256 educationScore = getEducationScore(patron);
        uint256 donationScore = getDonationScore(patron);
        uint256 lifetimeScore = getLifetimeScore(patron);
        uint256 universityAssociationScore = getUniversityAssociationScore(patron);
        uint256 activeScore = isActive(patron) ? 10 : 1;
        uint256 activityScore = getActivityScore(patron);
        uint256 totalScore = educationScore + (donationScore) + (lifetimeScore) + (universityAssociationScore) + (activeScore);
        uint256 decayFactor = exp(((-decayConstant) * int256(activityScore)));
        uint256 finalScore = totalScore * (decayFactor) / (1e18);
    
        return finalScore;
    }

}