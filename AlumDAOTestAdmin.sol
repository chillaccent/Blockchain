pragma solidity ^0.8.0;

import "./AlumDAOTestBase.sol";

contract AlumDAOTestAdmin is AlumDAOTestBase {

    modifier onlyAdmin() {
        require(_admins[msg.sender], "Only AlumDAO admins can call this function");
        _;
    }

    function setAdmin(address account, bool isAdmin) public onlyAdmin {
        _admins[account] = isAdmin;
    }
}