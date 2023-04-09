pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

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
