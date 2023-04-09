pragma solidity ^0.8.0;

import "./AlumDAOTestDonation.Sol";

contract AlumDAOTestActivity is AlumDAOTestDonation {

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
        function setDecayConstant(uint256 _decayConstant) public onlyAdmin {
        decayConstant = int256(_decayConstant);
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

    function updateWorkContributions(address patron, uint256 amount) public onlyAdmin {
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

}