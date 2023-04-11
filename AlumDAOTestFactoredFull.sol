pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./StringUtils.sol";



interface IAlumDAOTestActivityExternal {
    function setDecayConstant(uint256 _decayConstant) external;
    function logWork(uint256 tokenId, bytes32 description) external;
    function confirmWork(uint256 tokenId, uint256 witnessTokenId) external;
    function updateWorkContributions(address patron, uint256 amount) external;
    function getActivityScore(address patron) external view returns (uint256);
    function getActivityCount(address patron, uint256 tokenId) external view returns (uint256);
    function recordActivity(uint256 tokenId, uint256 amount) external;
}

 contract AlumDAOTestActivityExternal is ERC721Enumerable {
    using StringUtils for bytes32;
    using SafeMath for uint256;

    int256 public decayConstant;
    mapping(uint256 => WorkLog[]) private _workLogs;
    mapping(uint256 => ActivityRecord[]) private _activityRecords;
    mapping(address => uint256) private _workContributions;
    mapping(address => uint256[]) private _activityTimestamps;
    mapping(address => uint256[]) private _activityAmounts;
    
    function exp(int256 x) internal pure returns (uint256) {
        uint256 xx = uint256(x);
        uint256 y = 1 ether;
        uint256 z = y;
        for (uint256 i = 1; i < 10; i++) {
        y = y * xx / i;
        z += y;
        }
        return z;
    }

    struct WorkLog {
        uint256 timestamp;
        string description;
    }

    struct ActivityRecord {
        uint256 timestamp;
        uint256 amount;
    }

    constructor() ERC721("AlumDAOTestActivityExternal", "ALUM-ACT") {}

        function setDecayConstant(uint256 _decayConstant) public {
        decayConstant = int256(_decayConstant);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

        function logWork(uint256 tokenId, bytes32 description) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        string memory descriptionStr = StringUtils.bytes32ToString(description);
        _workLogs[tokenId].push(WorkLog(block.timestamp, descriptionStr));
    }

    function confirmWork(uint256 tokenId, uint256 witnessTokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        require(ownerOf(witnessTokenId) != ownerOf(tokenId), "Witness and token holder must be different");

        _activityTimestamps[ownerOf(tokenId)].push(block.timestamp);
        _activityAmounts[ownerOf(tokenId)].push(1);

        _activityTimestamps[ownerOf(witnessTokenId)].push(block.timestamp);
        _activityAmounts[ownerOf(witnessTokenId)].push(1);
    }

    function updateWorkContributions(address patron, uint256 amount) public  {
        _workContributions[patron] = amount;
    }

    function getLastWorkTimestamp(uint256 tokenId) internal view returns (uint256) {
        WorkLog[] storage logs = _workLogs[tokenId];
        if (logs.length > 0) {
            return logs[logs.length - 1].timestamp;
        } else {
            return 0;
        }
    }
    
    function getActivityScore(address patron) public view returns (uint256) {
    uint256 activityScore = 0;

    ActivityRecord[] memory records = _activityRecords[uint256(uint160(address(patron)))];


    for (uint i = 0; i < records.length; i++) {
        uint256 timestamp = records[i].timestamp;
        uint256 amount = records[i].amount;
        uint256 semestersPassed = (block.timestamp - timestamp) / 180 days;
        uint256 activityScoreIncrement = uint256(10 * exp(-decayConstant * int256(semestersPassed)) * amount);
        activityScore += activityScoreIncrement;
    }

    return activityScore;
}


    function getActivityCount(address patron, uint256 tokenId) public view returns (uint256) {
    uint256 semestersPassed = 0;
    uint256 lastWorkTimestamp = 0;


    WorkLog[] storage logs = _workLogs[tokenId];
    if (logs.length > 0) {
        lastWorkTimestamp = logs[logs.length - 1].timestamp;
    }

    semestersPassed = (block.timestamp - lastWorkTimestamp) / 180 days;
    uint256 activityCount = semestersPassed * getActivityScore(patron);
    return activityCount;
}

    uint256 private _activityScore;

    

    // Replace _activityScore with a local variable
    function recordActivity(uint256 tokenId, uint256 amount) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        ActivityRecord memory record = ActivityRecord({
            timestamp: block.timestamp,
            amount: amount
        });
        _activityRecords[StringUtils.addressToUint256(ownerOf(tokenId))].push(record);
        //uint256 lastWorkTimestamp = getLastWorkTimestamp(tokenId);
        //uint256 activityScore = uint256(10 * exp(-decayConstant * int256((block.timestamp - lastWorkTimestamp) / 180 days)) * amount);
    }

    fallback() external payable {
        revert("Fallback function not allowed");
    }


}


//Base contract
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract AlumDAOTestBase is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    mapping(address => bool) public  _allowed;
    mapping(uint256 => address[]) public _ownershipHistory;
    mapping(uint256 => mapping(address => bool)) public _permissions;
    mapping(address => uint32) public _lastActivity;
    mapping(address => uint256) public _educationLevel; // 1 = Bachelor's, 2 = Master's, 3 = PhD
    mapping(address => uint256) public _universityAssociation; // 0 = none, 1 = in-network, 2 = out-of-network, 3 = alumni
    mapping (uint256 => uint256[]) public _affiliatedUniversities;
    mapping (uint256 => mapping (uint256 => bool)) public _affiliationDeals;
    mapping (address => uint256[]) public _universities;
    mapping(address => uint256) public _donations;
    mapping(address => uint256) public _workContributions;
    mapping(address => bool) public _active;
    mapping(uint256 => WorkLog[]) public _workLogs;
    mapping(address => uint256[]) public _activityTimestamps;
    mapping(address => uint256[]) public _activityAmounts;
    mapping(address => ActivityRecord[]) public _activityRecords;
    mapping(address => bool) public _admins;


    int256 public decayConstant;
    uint32 public constant MAX_EDUCATION_LEVEL = 5;
    uint32 public constant MAX_ASSOCIATION = 5;
    uint32 public constant MAX_PERMISSION_TYPE = 3;
    uint32 public constant MAX_PERMISSION_SCOPE = 3;

    uint32 public myUint32;

    struct WorkLog {
        uint256 timestamp;
        string description;
    }

    struct ActivityRecord {
        uint256 timestamp;
        uint256 amount;
    }

    function exp(int256 x) internal pure returns (uint256) {
        uint256 xx = uint256(x);
        uint256 y = 1 ether;
        uint256 z = y;
        for (uint256 i = 1; i < 10; i++) {
            y = y * xx / i;
            z += y;
        }
        return z;
    }

    function ln(uint256 x) internal  pure returns (uint256) {
        require(x > 0, "Cannot take ln of 0");
        uint256 result = 0;
        uint256 y = x;

        while (y >= 2 * 1e18) {
            result = result + (405465108108164381); // ln(2)
            y = y / (2);
        }

        while (y > 1e18) {
            result = result + (3988425490); // ln(10)
        }
        return result * (1e18) / (10**18) + (6103515625); // ln(3)
    }

    function setAllowed(address account, bool allowed) public onlyOwner {
        _allowed[account] = allowed;
    }

    function isAllowed(address account) public view returns (bool) {
        return _allowed[account];
    }
       
    // ...
    constructor() ERC721("AlumDAOScoreTest", "ADSTT") {}
}


pragma solidity ^0.8.0;


contract AlumDAOTestAdmin is AlumDAOTestBase {

    modifier onlyAdmin() {
        require(_admins[msg.sender], "Only AlumDAO admins can call this function");
        _;
    }

    function setAdmin(address account, bool isAdmin) public onlyAdmin {
        _admins[account] = isAdmin;
    }
}

pragma solidity ^0.8.0;



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

pragma solidity ^0.8.0;



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


pragma solidity ^0.8.0;



contract AlumDAOTestDonation is AlumDAOTestEducation {
    // Move donation-related functions and logic here
    // ...
        function updateDonations(address patron, uint256 amount) public onlyAdmin {
        _donations[patron] = amount;
    }

        function getDonationScore(address patron) public view returns (uint256) {
        uint256 donations = _donations[patron];
        uint256 donationScore = uint256(ln(donations / 500) * 10);

        return donationScore;
    }


}


pragma solidity ^0.8.0;

import "./StringUtils.sol";
import "./AlumDAOTestActivityExternal.sol";


contract AlumDAOTestActivity is AlumDAOTestDonation {
    using StringUtils for bytes32;
    using SafeMath for uint256;

     IAlumDAOTestActivityExternal public activityExternal;

    constructor(address _alumDAOTestActivityExternalAddress) AlumDAOTestDonation() {
    activityExternal = IAlumDAOTestActivityExternal(_alumDAOTestActivityExternalAddress);
}

    function setDecayConstant(uint256 _decayConstant) public onlyAdmin {
        activityExternal.setDecayConstant(_decayConstant);
    }

    // Call the logWork function using the activityExternal instance
    function logWork(uint256 tokenId, bytes32 description) public {
        activityExternal.logWork(tokenId, description);
    }

    // Call the confirmWork function using the activityExternal instance
    function confirmWork(uint256 tokenId, uint256 witnessTokenId) public {
        activityExternal.confirmWork(tokenId, witnessTokenId);
    }

    // Call the updateWorkContributions function using the activityExternal instance
    function updateWorkContributions(address patron, uint256 amount) public onlyAdmin {
        activityExternal.updateWorkContributions(patron, amount);
    }

    // Call the getActivityScore function using the activityExternal instance
    function getActivityScore(address patron) public view returns (uint256) {
        return activityExternal.getActivityScore(patron);
    }

    // Call the getActivityCount function using the activityExternal instance
    function getActivityCount(address patron, uint256 tokenId) public view returns (uint256) {
        return activityExternal.getActivityCount(patron, tokenId);
    }

    // Call the recordActivity function using the activityExternal instance
    function recordActivity(uint256 tokenId, uint256 amount) public onlyAdmin {
        activityExternal.recordActivity(tokenId, amount);
    }
}

pragma solidity ^0.8.0;


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
pragma solidity ^0.8.0;

pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

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
