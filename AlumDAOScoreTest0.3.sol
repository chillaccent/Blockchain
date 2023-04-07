pragma solidity ^0.8.0;
pragma abicoder v2;



import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";




contract AlumDAOTest is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    mapping(address => bool) private _allowed;
    mapping(uint256 => address[]) private _ownershipHistory;
    mapping(uint256 => mapping(address => bool)) private _permissions;
    mapping(address => uint32) private _lastActivity;
    mapping(address => uint256) private _educationLevel; // 1 = Bachelor's, 2 = Master's, 3 = PhD
    mapping(address => uint256) private _universityAssociation; // 0 = none, 1 = in-network, 2 = out-of-network, 3 = alumni
    mapping(address => uint256) private _donations;
    mapping(address => uint256) private _workContributions;
    mapping(address => bool) private _active;
    mapping(uint256 => WorkLog[]) private _workLogs;
    mapping(address => uint256[]) private _activityTimestamps;
    mapping(address => uint256[]) private _activityAmounts;
    mapping(address => ActivityRecord[]) private _activityRecords;
    mapping(address => bool) private _admins; 

    int256 public decayConstant;
    uint32 private constant MAX_EDUCATION_LEVEL = 5;
    uint32 private constant MAX_ASSOCIATION = 5;
    uint32 private constant MAX_PERMISSION_TYPE = 3;
    uint32 private constant MAX_PERMISSION_SCOPE = 3;

    uint32 private myUint32;
       

    constructor() ERC721("AlumDAOScoreTest", "ADSTT") {}


    struct WorkLog {
        uint256 timestamp;
        string description;
    }

    struct ActivityRecord {
    uint256 timestamp;
    uint256 amount;
}
    modifier onlyAdmin() {
        require(_admins[msg.sender], "Only AlumDAO admins can call this function");
        _;
    }

    function setAdmin(address account, bool isAdmin) public onlyAdmin {
        _admins[account] = isAdmin;
    }

    function mint(uint256 educationLevel, uint256 universityAssociation) public {
        require(!_active[msg.sender], "Alumnus is already active");
        require(_allowed[msg.sender], "Account not allowed to mint NFT");
        _educationLevel[msg.sender] = educationLevel;
        _universityAssociation[msg.sender] = universityAssociation;
        uint256 tokenId = totalSupply().add(1);
        _safeMint(msg.sender, tokenId);
        _ownershipHistory[tokenId].push(msg.sender);
        _lastActivity[msg.sender] = uint32(block.timestamp);
        _active[msg.sender] = true;
    }


    function setAllowed(address account, bool allowed) public onlyOwner {
        _allowed[account] = allowed;
    }

    function isAllowed(address account) public view returns (bool) {
        return _allowed[account];
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

    //event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Transfer caller is not owner nor approved");
        require(from == ownerOf(tokenId), "Transfer from account is not owner");
    
        super.transferFrom(from, to, tokenId);
    
        // Update last activity and active status
        _lastActivity[from] = uint32(block.timestamp);
        _active[from] = true;
    
        emit Transfer(from, to, tokenId);
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
    uint8 i = 0;
    while (i < 32 && _bytes32[i] != 0) {
        i++;
    }
    bytes memory bytesArray = new bytes(i);
    for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
        bytesArray[i] = _bytes32[i];
    }
    return string(bytesArray);
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


    function setPermission(uint256 tokenId, address account, bool allowed) public {
        require(ownerOf(tokenId) == msg.sender || _permissions[tokenId][msg.sender], "Caller is not owner nor has permission");
        _permissions[tokenId][account] = allowed;
    }

    function getPermission(uint256 tokenId, address account) public view returns (bool) {
        return _permissions[tokenId][account];
    }

    function updateEducationLevel(address patron, uint256 level) public onlyAdmin {
        _educationLevel[patron] = level;
    }

    function updateUniversityAssociation(address patron, uint256 association) public onlyAdmin {
        _universityAssociation[patron] = association;
    }

    function updateDonations(address patron, uint256 amount) public onlyAdmin {
        _donations[patron] = amount;
    }

    function updateWorkContributions(address patron, uint256 amount) public onlyAdmin {
            _workContributions[patron] = amount;
    }
    

    function isActive(address patron) public view returns (bool) {
        return _active[patron];
    }

    function setDecayConstant(uint256 _decayConstant) public onlyAdmin {
        decayConstant = int256(_decayConstant);
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
    function recordActivity(uint256 tokenId, uint256 amount) public onlyAdmin {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        ActivityRecord memory record = ActivityRecord({
            timestamp: block.timestamp,
            amount: amount
        });
        _activityRecords[ownerOf(tokenId)].push(record);
        //uint256 lastWorkTimestamp = getLastWorkTimestamp(tokenId);
        //uint256 activityScore = uint256(10 * exp(-decayConstant * int256((block.timestamp - lastWorkTimestamp) / 180 days)) * amount);
    }

    function getActivityScore(address patron) public view returns (uint256) {
    uint256 activityScore = 0;

    ActivityRecord[] memory records = _activityRecords[patron];

    for (uint i = 0; i < records.length; i++) {
        uint256 timestamp = records[i].timestamp;
        uint256 amount = records[i].amount;
        uint256 semestersPassed = (block.timestamp - timestamp) / 180 days;
        uint256 activityScoreIncrement = uint256(10 * exp(-decayConstant * int256(semestersPassed)) * amount);
        activityScore += activityScoreIncrement;
    }

    return activityScore;
}

    function getLastWorkTimestamp(uint256 tokenId) internal view returns (uint256) {
        WorkLog[] storage logs = _workLogs[tokenId];
        if (logs.length > 0) {
            return logs[logs.length - 1].timestamp;
        } else {
            return 0;
        }
    }

    function logWork(uint256 tokenId, bytes32 description) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        string memory descriptionStr = bytes32ToString(description);
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

    function getDonationScore(address patron) public view returns (uint256) {
        uint256 donations = _donations[patron];
        uint256 donationScore = uint256(ln(donations.div(500)).mul(10));

        return donationScore;
    }

    function getLifetimeScore(address patron) public view returns (uint256) {
        uint256 lifetimeDonations = _donations[patron].mul(5);
        uint256 lifetimeWorkContributions = _workContributions[patron].mul(15);

        uint256 lifetimeScore = lifetimeDonations.add(lifetimeWorkContributions);

        return lifetimeScore;
    }

    function getUniversityAssociationScore(address patron) public view returns (uint256) {
        uint256 universityAssociation = _universityAssociation[patron];
        uint256 universityAssociationScore = 0;

        if (universityAssociation == 1) {
            universityAssociationScore = 3;
        } else if (universityAssociation == 2) {
            universityAssociationScore = 1;
        } else if (universityAssociation == 3) {
            universityAssociationScore = 5;
        }

        return universityAssociationScore;
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

    function ln(uint256 x) internal pure returns (uint256) {
        require(x > 0, "Cannot take ln of 0");
        uint256 result = 0;
        uint256 y = x;

        while (y >= 2 * 1e18) {
            result = result.add(405465108108164381); // ln(2)
            y = y.div(2);
        }

        while (y > 1e18) {
            result = result.add(3988425490); // ln(10)
        }
        return result.mul(1e18).div(10**18).add(6103515625); // ln(3)
    }

    function getScore(address patron) public view returns (uint256) {
        uint256 educationScore = getEducationScore(patron);
        uint256 donationScore = getDonationScore(patron);
        uint256 lifetimeScore = getLifetimeScore(patron);
        uint256 universityAssociationScore = getUniversityAssociationScore(patron);
        uint256 activeScore = isActive(patron) ? 10 : 1;
        uint256 activityScore = getActivityScore(patron);
    
        uint256 totalScore = educationScore.add(donationScore).add(lifetimeScore).add(universityAssociationScore).add(activeScore);
        uint256 decayFactor = exp(((-decayConstant) * int256(activityScore)));
        uint256 finalScore = totalScore.mul(decayFactor).div(1e18);
    
        return finalScore;
    }

}


