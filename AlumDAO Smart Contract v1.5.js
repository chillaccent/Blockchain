pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AccountBoundNFT is ERC721, Ownable {
    using SafeMath for uint256;

    mapping(address => bool) private _allowed;
    mapping(uint256 => address[]) private _ownershipHistory;
    mapping(uint256 => mapping(address => bool)) private _permissions;
    mapping(address => uint256) private _lastActivity;
    mapping(address => uint256) private _educationLevel; // 1 = Bachelor's, 2 = Master's, 3 = PhD
    mapping(address => uint256) private _universityAssociation; // 0 = none, 1 = in-network, 2 = out-of-network, 3 = alumni
    mapping(address => uint256) private _donations;
    mapping(address => uint256) private _workContributions;
    mapping(address => bool) private _active;

    constructor() ERC721("AccountBoundNFT", "ABNFT") {}

    struct WorkLog {
        uint256 timestamp;
        string description;
    }

    mapping(uint256 => WorkLog[]) private _workLogs;    

    function mint() public {
        require(_allowed[msg.sender], "Account not allowed to mint NFT");
        uint256 tokenId = totalSupply().add(1);
        _safeMint(msg.sender, tokenId);
        _ownershipHistory[tokenId].push(msg.sender);
    }

    function setAllowed(address account, bool allowed) public onlyOwner {
        _allowed[account] = allowed;
    }

    function isAllowed(address account) public view returns (bool) {
        return _allowed[account];
    }

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Transfer caller is not owner nor approved");
        require(from == ownerOf(tokenId), "Transfer from account is not owner");
    
        super.transferFrom(from, to, tokenId);
    
        // Update last activity and active status
        _lastActivity[from] = block.timestamp;
        _active[from] = true;
    
        emit Transfer(from, to, tokenId);
    }

    function revokeNFT(uint256 tokenId) public onlyOwner {
        address owner = ownerOf(tokenId);

        // Update last activity and active status
        _lastActivity[owner] = block.timestamp;
        _active[owner] = false;

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

    function updateEducationLevel(address patron, uint256 level) public onlyOwner {
        _educationLevel[patron] = level;
    }

    function updateUniversityAssociation(address patron, uint256 association) public onlyOwner {
        _universityAssociation[patron] = association;
    }

    function updateDonations(address patron, uint256 amount) public onlyOwner {
        _donations[patron] = amount;
    }

    function updateWorkContributions(address patron, uint256 amount) public onlyOwner {
            _workContributions[patron] = amount;
    }
    

    function isActive(address patron) public view returns (bool) {
        return _active[patron];
    }

    

    function getScore(address patron) public view returns (uint256) {
        uint256 educationScore = getEducationScore(patron);
        uint256 donationScore = getDonationScore(patron);
        uint256 lifetimeScore = getLifetimeScore(patron);
        uint256 universityAssociationScore = getUniversityAssociationScore(patron);
        uint256 activeScore = isActive(patron) ? 10 : 1;
        uint256 activityScore = getActivityScore(patron);
    
        uint256 totalScore = educationScore.add(donationScore).add(lifetimeScore).add(universityAssociationScore).add(activeScore);
        uint256 decayFactor = exp(int256(-decayConstant * activityScore));
        uint256 finalScore = totalScore.mul(decayFactor).div(1e18);
    
        return finalScore;
    }

    mapping(address => uint256[]) private _activityTimestamps;
mapping(address => uint256[]) private _activityAmounts;

function recordActivity(uint256 tokenId, uint256 amount) public {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
    _activityTimestamps[ownerOf(tokenId)].push(block.timestamp);
    _activityAmounts[ownerOf(tokenId)].push(amount);
}

function getActivityCount(uint256 tokenId) public view returns (uint256) {
    uint256 semestersPassed = 0;
    uint256 lastWorkTimestamp = 0;
    
    WorkLog[] storage logs = _workLogs[tokenId];
    if (logs.length > 0) {
        lastWorkTimestamp = logs[logs.length - 1].timestamp;
    }
    
    semestersPassed = (block.timestamp - lastWorkTimestamp) / 180 days;
    uint256 activityCount = semestersPassed * getActivityScore(tokenId);
    return activityCount;
}


function recordActivity(address patron, uint256 amount) public {
    require(ownerOf(tokenId) == msg.sender || _permissions[tokenId][msg.sender], "Caller is not owner nor has permission");
    _activityTimestamps[patron].push(block.timestamp);
    _activityAmounts[patron].push(amount);
}

function getActivityScore(address patron) public view returns (uint256) {
    uint256 activityScore = 0;

    for (uint i = 0; i < _activityTimestamps[patron].length; i++) {
        uint256 timestamp = _activityTimestamps[patron][i];
        uint256 amount = _activityAmounts[patron][i];
        uint256 semestersPassed = (block.timestamp - timestamp) / 180 days;
        uint256 activityScoreIncrement = uint256(10 * exp(int256(-decayConstant * semestersPassed)) * amount);
        activityScore += activityScoreIncrement;
    }

    return activityScore;
}
    function logWork(uint256 tokenId, string memory description) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        _workLogs[tokenId].push(WorkLog(block.timestamp, description));
    }
    function confirmWork(uint256 tokenId, uint256 witnessTokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        require(ownerOf(witnessTokenId) != ownerOf(tokenId), "Witness and token holder must be different");
    
        _activityTimestamps[ownerOf(tokenId)].push(block.timestamp);
        _activityAmounts[ownerOf(tokenId)].push(1);
    
        _activityTimestamps[ownerOf(witnessTokenId)].push(block.timestamp);
        _activityAmounts[ownerOf(witnessTokenId)].push(1);
    }

    function getActivityCount(uint256 tokenId) public view returns (uint256) {
        uint256 semestersPassed = 0;
        uint256 lastWorkTimestamp = 0;
    
        WorkLog[] storage logs = _workLogs[tokenId];
        if (logs.length > 0) {
            lastWorkTimestamp = logs[logs.length - 1].timestamp;
        }
    
        semestersPassed = (block.timestamp - lastWorkTimestamp) / 180 days;
        uint256 activityCount = semestersPassed * getActivityScore(tokenId);
        return activityCount;
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
}
