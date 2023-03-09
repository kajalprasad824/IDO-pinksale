// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./UpgradableFile.sol";

///----------------------------------------------------------------------------------------------------///
///----------------------------------------------------------------------------------------------------///
///----------------------------------------------------------------------------------------------------///

contract FactoryContract is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    address[] public ICO;

    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    struct Info {
        uint256 startTime;
        uint256 endTime;
        bool hardCap;
        bool isActive;
    }
    mapping(address => Info) public info;

    function collectInfo(
        address ico,
        uint256 startTime,
        uint256 endTime
    ) public {
        info[ico] = Info(startTime, endTime, false, true);
        ICO.push(ico);
    }

    function collectHardCapInfo(address ico, bool hardCap) public {
        info[ico] = Info(
            info[ico].startTime,
            info[ico].endTime,
            hardCap,
            info[ico].isActive
        );
    }

    function collectActiveInfo(address ico, bool isActive) public {
        info[ico] = Info(
            info[ico].startTime,
            info[ico].endTime,
            info[ico].hardCap,
            isActive
        );
    }

    function collectEndTime(address ico,uint _endTime) public {
        info[ico] = Info(
            info[ico].startTime,
            _endTime,
            info[ico].hardCap,
            info[ico].isActive
        );
    }

    function Upcoming() public view returns (address[100] memory) {
        address[100] memory upcoming;
        for (uint256 i = 0; i < ICO.length; i++) {
            if (
                info[ICO[i]].startTime > block.timestamp &&
                info[ICO[i]].isActive == true
            ) {
                upcoming[i] = ICO[i];
            }
        }

        return upcoming;
    }

    function Ended() public view returns (address[100] memory) {
        address[100] memory ended;
        for (uint256 i = 0; i < ICO.length; i++) {
            if (
                info[ICO[i]].hardCap == true || info[ICO[i]].endTime < block.timestamp
            ) {
                ended[i] = ICO[i];
            }
        }
        return ended;
    }

    function Running() public view returns (address[100] memory) {
        address[100] memory running;
        for (uint256 i = 0; i < ICO.length; i++) {
            if (
                info[ICO[i]].startTime < block.timestamp &&
                info[ICO[i]].endTime > block.timestamp &&
                info[ICO[i]].isActive == true && info[ICO[i]].hardCap == false
            ) {
                running[i] = ICO[i];
            }
        }

        return running;
    }

    function Cancelled() public view returns (address[100] memory) {
        address[100] memory cancel;
        for (uint256 i = 0; i < ICO.length; i++) {
            if (info[ICO[i]].isActive == false) {
                cancel[i] = ICO[i];
            }
        }

        return cancel;
    }

    function Filled() public view returns (address[100] memory) {
        address[100] memory filled;
        for (uint256 i = 0; i < ICO.length; i++) {
            if (info[ICO[i]].hardCap == true && info[ICO[i]].isActive == true) {
                filled[i] = ICO[i];
            }
        }

        return filled;
    }

    function allICOAddresses() public view returns (address[] memory) {
        return ICO;
    }
}
// factory contract address 0x6a1cb6d091789e9D78c4504E9e58f774F90a3025
