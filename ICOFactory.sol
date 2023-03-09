// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./UpgradableFile.sol";
import "./ICO.sol";

contract FactoryICO is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 public ICOCreationFee;
    address factoryContract;
    address[] public ICOAddresses;

    struct ICODetails {
        string projectName;
        string description;
        uint256 presaleRate;
        uint256 softCap;
        uint256 hardCap;
        uint256 minBuy;
        uint256 maxBuy;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
    }

    mapping(address => mapping(string => mapping(uint256 => ICODetails)))
        public icoDetails;
    //["Kuldeep", "PJCT", 500000, 10000000000000000000, "100000000000000000000", "1000000000000000000", "100000000000000000000", "1677752985", "1677756585",false]

    struct AddInfo {
        address icoOwner;
        address payoutCurrency;
        address tokenAddress;
    }
    mapping(address => mapping(string => AddInfo))
        public addInfo;
    //["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8","0xd9145CCE52D386f254917e481eB44e9943F39138"]

    struct SocialDetails {
        string website;
        string facebook;
        string twitter;
        string telegram;
        string github;
        string instagram;
        string discord;
        string reddit;
    }
    
    mapping(address => mapping(string => SocialDetails)) public socialDetails;
    //["we","fa","tw","te","gi","in","di","re"]

    struct vestingInfo {
        uint256 presalePercent;
        uint256 vestingPeriodDays;
        uint256 eachCyclePercent;
        uint8 vestingRound;
    }
    vestingInfo public VestingInfo;

   // [1000, 1, 1000, 10]

    struct ICORequest {
        bool creator;
        bool admin;
        bool decision;
    }
    mapping(address => mapping(string => mapping(uint256 => ICORequest)))
        public icoRequest;

    struct ProjectRounds {
        uint256 totalRounds;
    }
    mapping(address => mapping(string => ProjectRounds)) public projectRounds;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address factorycontract,
        uint256 _ICOCreationFee,
        vestingInfo memory _VestingInfo
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        ICOCreationFee = _ICOCreationFee;
        factoryContract = factorycontract;

        uint256 total = _VestingInfo.presalePercent +
            (_VestingInfo.vestingRound - 1) *
            _VestingInfo.eachCyclePercent;
        require(total == 10000, "%");

        VestingInfo = vestingInfo(
            _VestingInfo.presalePercent,
            _VestingInfo.vestingPeriodDays,
            _VestingInfo.eachCyclePercent,
            _VestingInfo.vestingRound
        );
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    //-------------------------------------------------------------------

    function updateICOCreationFee(uint256 _ICOCreationFee) public onlyOwner {
        ICOCreationFee = _ICOCreationFee;
    }

    function updateVestingInfo(vestingInfo memory _VestingInfo)
        public
        onlyOwner
    {
        uint256 total = _VestingInfo.presalePercent +
            (_VestingInfo.vestingRound - 1) *
            _VestingInfo.eachCyclePercent;
        require(total == 10000, "%");
        VestingInfo = vestingInfo(
            _VestingInfo.presalePercent,
            _VestingInfo.vestingPeriodDays,
            _VestingInfo.eachCyclePercent,
            _VestingInfo.vestingRound
        );
    }

    //-------------------------------------------------------------------

    function createICO(
        ICODetails memory _ICODetails,
        AddInfo memory _AddInfo,
        SocialDetails memory _SocialDetails
    ) public payable {
        require(projectRounds[_AddInfo.icoOwner][_ICODetails.projectName].totalRounds == 0 && _ICODetails.startTime < _ICODetails.endTime && _ICODetails.startTime > block.timestamp && msg.value == ICOCreationFee,"exist or time or Fee");
       
        //require(_AddInfo.isActive == false, "false");

        //require(msg.value == ICOCreationFee,"Fee");
        icoDetails[_AddInfo.icoOwner][_ICODetails.projectName][
            projectRounds[_AddInfo.icoOwner][_ICODetails.projectName]
                .totalRounds
        ] = ICODetails(
            _ICODetails.projectName,
            _ICODetails.description,
            _ICODetails.presaleRate,
            _ICODetails.softCap,
            _ICODetails.hardCap,
            _ICODetails.minBuy,
            _ICODetails.maxBuy,
            _ICODetails.startTime,
            _ICODetails.endTime,
            false
        );
        socialDetails[_AddInfo.icoOwner][
            _ICODetails.projectName
        ] = SocialDetails(
            _SocialDetails.website,
            _SocialDetails.facebook,
            _SocialDetails.twitter,
            _SocialDetails.telegram,
            _SocialDetails.github,
            _SocialDetails.instagram,
            _SocialDetails.discord,
            _SocialDetails.reddit
        );
        addInfo[_AddInfo.icoOwner][_ICODetails.projectName]
         = AddInfo(
            _AddInfo.icoOwner,
            _AddInfo.payoutCurrency,
            _AddInfo.tokenAddress
        );
        icoRequest[_AddInfo.icoOwner][_ICODetails.projectName][
            projectRounds[_AddInfo.icoOwner][_ICODetails.projectName]
                .totalRounds
        ] = ICORequest(true, false, false);
        payable(owner()).transfer(ICOCreationFee);
        //IERC20(_AddInfo.tokenAddress).approve(address(this),IERC20(_AddInfo.tokenAddress).totalSupply());
    }

    function createICORounds(ICODetails memory _ICODetails) public payable {
        require(projectRounds[msg.sender][_ICODetails.projectName].totalRounds != 0 && _ICODetails.startTime < _ICODetails.endTime && _ICODetails.startTime > block.timestamp && msg.value == ICOCreationFee,"Create or time or Fee");
        // require(
        //     ,
        //     "time"
        // );
        //require(msg.value == ICOCreationFee,"Fee");
        icoDetails[msg.sender][_ICODetails.projectName][
            projectRounds[msg.sender][_ICODetails.projectName].totalRounds
        ] = ICODetails(
            _ICODetails.projectName,
            _ICODetails.description,
            _ICODetails.presaleRate,
            _ICODetails.softCap,
            _ICODetails.hardCap,
            _ICODetails.minBuy,
            _ICODetails.maxBuy,
            _ICODetails.startTime,
            _ICODetails.endTime,
            false
        );

        // addInfo[msg.sender][_ICODetails.projectName][
        //     projectRounds[msg.sender][_ICODetails.projectName]
        //         .totalRounds
        // ] = AddInfo(
        //     msg.sender,
        //     addInfo[msg.sender][_ICODetails.projectName][projectRounds[msg.sender][_ICODetails.projectName]
        //         .totalRounds-1].payoutCurrency,
        //     addInfo[msg.sender][_ICODetails.projectName][projectRounds[msg.sender][_ICODetails.projectName]
        //         .totalRounds-1].tokenAddress,
        //     false
        // );
        icoRequest[msg.sender][_ICODetails.projectName][
            projectRounds[msg.sender][_ICODetails.projectName].totalRounds
        ] = ICORequest(true, false, false);
        payable(owner()).transfer(ICOCreationFee);
    }

    
    function ICOApproval(
        address icoOwner,
        string memory projectName,
        uint8 round,
        bool decision
    ) public onlyOwner {
        require(round == projectRounds[icoOwner][projectName].totalRounds && icoRequest[icoOwner][projectName][round].admin == false && icoRequest[icoOwner][projectName][round].creator==true,"round or already decide or request");
       // require(icoRequest[icoOwner][projectName][round].admin == false,"");
        if (decision == true) {
            icoRequest[icoOwner][projectName][round] = ICORequest(
                true,
                true,
                true
            );

            icoDetails[icoOwner][projectName][round].isActive = true;

            ICO ico = new ICO(
                factoryContract,
                address(this),
                icoOwner,
                owner(),
                projectName,
                round
            );
            ICOAddresses.push(address(ico));
            //    uint amount = icoDetails[icoOwner][projectName][round].presaleRate * icoDetails[icoOwner][projectName][round].hardCap / 10 ** IERC20Metadata(addInfo[icoOwner][projectName][round].payoutCurrency).decimals();
            //    IERC20(tokenAddress).transferFrom(address(this),address(ico),amount);
            ICOfactory(factoryContract).collectInfo(
                address(ico),
                icoDetails[icoOwner][projectName][round].startTime,
                icoDetails[icoOwner][projectName][round].endTime
            );

            
        } else {
            icoRequest[icoOwner][projectName][round] = ICORequest(
                true,
                true,
                false
            );
        }
        projectRounds[icoOwner][projectName].totalRounds++;
    }

    function ICOInfo(
        address icoOwner,
        string memory projectName,
        uint256 round
    ) external view returns (ICODetails memory) {
        return icoDetails[icoOwner][projectName][round];
    }

    // function SocialInfo(address icoOwner, string memory projectName) external view returns (SocialDetails memory){
    //     return socialDetails[icoOwner][projectName];
    // }

    function AdditionalInfo(
        address icoOwner,
        string memory projectName
    ) external view returns (AddInfo memory) {
        return addInfo[icoOwner][projectName];
    }

    function VestInfo() external view returns (vestingInfo memory) {
        return VestingInfo;
    }

    function allICOAddresses() public view returns (address[] memory) {
        return ICOAddresses;
    }
}
