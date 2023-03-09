// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//-------------------------------------------------------------------------

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

//------------------Interface of Factory Contract----------------------------

interface ICOfactory {
    struct vestingInfo {
        uint256 presalePercent;
        uint256 vestingPeriodDays;
        uint256 eachCyclePercent;
        uint8 vestingRound;
    }

    struct AddInfo {
        address icoOwner;
        address payoutCurrency;
        address tokenAddress;      
    }

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

    // struct SocialDetails {
    //     string website;
    //     string facebook;
    //     string twitter;
    //     string telegram;
    //     string github;
    //     string instagram;
    //     string discord;
    //     string reddit;
    // }

    function ICOInfo(
        address icoOwner,
        string memory projectName,
        uint256 round
    ) external view returns (ICODetails memory);

    // function SocialInfo(address icoOwner, string memory projectName) external view returns (SocialDetails memory);

    function AdditionalInfo(
        address icoOwner,
        string memory projectName
    ) external view returns (AddInfo memory);

    function VestInfo() external view returns (vestingInfo memory);

    function collectInfo(
        address ico,
        uint256 startTime,
        uint256 endTime
    ) external;

    function collectHardCapInfo(address ico, bool hardCap) external;

    function collectActiveInfo(address ico, bool isActive) external;

    function collectEndTime(address ico,uint _endTime) external;
}

//-------------------------------------------------------------------------

contract ICO is Ownable {
    address public Admin;
    address public factorycontract;
    address[] public investors;
    ICOfactory icoFactory;

    struct vestingInfo {
        uint256 presalePercent;
        uint256 vestingPeriodDays;
        uint256 eachCyclePercent;
        uint8 vestingRound;
    }
    vestingInfo public VestingInfo;

    struct TokenInfo {
        string name;
        string symbol;
        uint8 decimal;
        address payoutCurrency;
        address tokenAddress;
    }
    TokenInfo public tokenInfo;

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
    ICODetails public icoDetails;

    // struct SocialDetails {
    //     string website;
    //     string facebook;
    //     string twitter;
    //     string telegram;
    //     string github;
    //     string instagram;
    //     string discord;
    //     string reddit;
    // }
    // SocialDetails public socialDetails;

    struct invest {
        uint256 totalAmount;
        uint256 totalToken;
        uint256 claimedToken;
        uint8 vestingRound;
    }
    mapping(address => invest) public Invest;

    struct FinalizeRequest {
        bool creator;
        bool admin;
        bool decision;
    }
    FinalizeRequest public finalizeRequest;

    struct soldInfo {
        uint256 soldToken;
        uint256 availableToken;
        uint256 amountRaised;
    }
    soldInfo public SoldInfo;

    constructor(
        address FactoryContract,
        address ICOfactoryContract,
        address icoOwner,
        address admin,
        string memory projectName,
        uint256 round
    ) {
        Admin = admin;
        _transferOwnership(icoOwner);
        icoFactory = ICOfactory(ICOfactoryContract);
        factorycontract = FactoryContract;

        ICOfactory.ICODetails memory ico = icoFactory.ICOInfo(
            icoOwner,
            projectName,
            round
        );
        icoDetails = ICODetails(
            ico.projectName,
            ico.description,
            ico.presaleRate,
            ico.softCap,
            ico.hardCap,
            ico.minBuy,
            ico.maxBuy,
            ico.startTime,
            ico.endTime,
            ico.isActive
        );

        // ICOfactory.SocialDetails memory social = Factory.SocialInfo(icoOwner,projectName);

        // socialDetails = SocialDetails(social.website,social.facebook,social.twitter,social.telegram,social.github,social.instagram,social.discord,social.reddit);

        ICOfactory.AddInfo memory token = icoFactory.AdditionalInfo(
            icoOwner,
            projectName
        );
        tokenInfo = TokenInfo(
            IERC20Metadata(token.tokenAddress).name(),
            IERC20Metadata(token.tokenAddress).symbol(),
            IERC20Metadata(token.tokenAddress).decimals(),
            token.payoutCurrency,
            token.tokenAddress
        );

        ICOfactory.vestingInfo memory vest = icoFactory.VestInfo();
        VestingInfo = vestingInfo(
            vest.presalePercent,
            vest.vestingPeriodDays,
            vest.eachCyclePercent,
            vest.vestingRound
        );

        SoldInfo.availableToken =
            (ico.hardCap * ico.presaleRate) /
            10**IERC20Metadata(token.payoutCurrency).decimals();
    }

    //---------------------------------------------------------------------------------------------

    modifier onlyInvestor() {
        require(Invest[_msgSender()].totalAmount != 0, "Not investor");
        _;
    }

    modifier Active() {
        require(icoDetails.isActive == true, "pool already cancelled");
        _;
    }


    function isICOEnd() public view returns (bool) {
        if (
            block.timestamp > icoDetails.endTime ||
            icoDetails.hardCap == SoldInfo.amountRaised
        ) {
            return true;
        } else {
            return false;
        }
    }

    // function isHardCapReach() public view returns (bool) {
    //     if (icoDetails.hardCap == SoldInfo.amountRaised) {
    //         return true;
    //     } else {
    //         return false;
    //     }
    // }

    function isSoftCapReach() public view returns (bool) {
        if (icoDetails.softCap <= SoldInfo.amountRaised) {
            return true;
        } else {
            return false;
        }
    }

    //---------------------------------------------------------------------------------------------

    function buy(uint256 amount) public Active {
      
        require(
            IERC20(tokenInfo.tokenAddress).balanceOf(address(this)) >=
                (icoDetails.hardCap * icoDetails.presaleRate) /
                    10**IERC20Metadata(tokenInfo.payoutCurrency).decimals(),
            "No token"
        );
        require(block.timestamp >= icoDetails.startTime,"Not started Yet");
        uint256 am = Invest[msg.sender].totalAmount + amount;
        require(
            am >= icoDetails.minBuy && am <= icoDetails.maxBuy,
            "amount range"
        );
        require(isICOEnd() == false, "already end");

        uint256 token = (icoDetails.presaleRate * amount) / 10**IERC20Metadata(tokenInfo.payoutCurrency).decimals();
        require(SoldInfo.availableToken >= token, "Not enough token");

        if (Invest[msg.sender].totalAmount == 0) {
            investors.push(msg.sender);
        }

        IERC20(tokenInfo.payoutCurrency).transferFrom(
            _msgSender(),
            address(this),
            amount
        );

        Invest[msg.sender].totalToken += token;
        Invest[msg.sender].totalAmount += amount;
        SoldInfo.availableToken -= token;
        SoldInfo.soldToken += token;
        SoldInfo.amountRaised += amount;

        if (icoDetails.hardCap == SoldInfo.amountRaised) {
            ICOfactory(factorycontract).collectHardCapInfo(address(this), true);
        }
    }

    function finalizedRequest() public Active onlyOwner {
        require(isSoftCapReach() == true, "Can't Finalize");
        finalizeRequest = FinalizeRequest(true, false, false);
    }

    function ApproveRequest(bool decision) public {
        require(Admin == msg.sender && finalizeRequest.creator == true, "Not admin or finalized req");
        if (decision == true) {
            finalizeRequest = FinalizeRequest(true, true, true);
            IERC20(tokenInfo.payoutCurrency).transfer(
                owner(),
                SoldInfo.amountRaised
            );
            IERC20(tokenInfo.tokenAddress).transfer(
                owner(),
                SoldInfo.availableToken
            );
            icoDetails.endTime = block.timestamp;
            ICOfactory(factorycontract).collectEndTime(address(this),icoDetails.endTime);
        } else {
            finalizeRequest = FinalizeRequest(true, true, false);
            IERC20(tokenInfo.tokenAddress).transfer(
                owner(),
                (icoDetails.hardCap * icoDetails.presaleRate) /
                    10**IERC20Metadata(tokenInfo.tokenAddress).decimals()
            );
            icoDetails.isActive = false;
            ICOfactory(factorycontract).collectActiveInfo(address(this), false);
        }
    }

    function cancelPool() public Active onlyOwner {
        require(finalizeRequest.creator == false, "Can't cancel");
        ICOfactory(factorycontract).collectActiveInfo(address(this), false);
        
        IERC20(tokenInfo.tokenAddress).transfer(msg.sender,IERC20(tokenInfo.tokenAddress).balanceOf(address(this)));
            
        icoDetails.isActive = false;
    }

    function vesting() public Active onlyInvestor {
        require(
            finalizeRequest.decision == true,
            "Not approved"
        );

        uint256 time = icoDetails.endTime +
            Invest[_msgSender()].vestingRound *
            VestingInfo.vestingPeriodDays;

        if (Invest[_msgSender()].vestingRound == 0) {
            uint256 token = (Invest[_msgSender()].totalToken *
                VestingInfo.presalePercent) / 10000;
            IERC20(tokenInfo.tokenAddress).transfer(_msgSender(), token);
            Invest[_msgSender()].claimedToken += token;
            Invest[_msgSender()].vestingRound++;
        } else {
            require(
                Invest[_msgSender()].totalToken !=
                    Invest[_msgSender()].claimedToken && block.timestamp >= time,
                "claim tokens fully & locking period "
            );
            //require(block.timestamp >= time, "locking period ");
            uint256 token = (Invest[_msgSender()].totalToken *
                VestingInfo.eachCyclePercent) / 10000;
            IERC20(tokenInfo.tokenAddress).transfer(_msgSender(), token);
            Invest[_msgSender()].claimedToken += token;
            Invest[_msgSender()].vestingRound++;
        }
    }

    function claim() public onlyInvestor {
        if (
            icoDetails.isActive == false ||
            (finalizeRequest.creator == true &&
                finalizeRequest.admin == true &&
                finalizeRequest.decision == false) ||
            (isSoftCapReach() == false && icoDetails.endTime < block.timestamp)
        ) {
            IERC20(tokenInfo.payoutCurrency).transfer(
                _msgSender(),
                Invest[_msgSender()].totalAmount
            );

            Invest[_msgSender()] = invest(0, 0, 0, 0);
        } else {
            require(false,"Can't claim");
        }
    }

    // function retrieveStuckedERC20Token(uint amount) public onlyOwner {
    //     uint256 time = icoDetails.endTime +VestingInfo.vestingRound *VestingInfo.vestingPeriodDays;
    //     require(
    //         block.timestamp > icoDetails.endTime && isSoftCapReach() == false || block.timestamp > time,
    //         "Can't retrieve"
    //     );
    //     IERC20(tokenInfo.tokenAddress).transfer(
    //         owner(),amount
    //     );
    // }

}

// factory token 0xBC794E1FDABD56D44868545211c49359aB6FebDA
// Factory 0x90a40A1fA73b119749f62645f0dCF52ba394E431
// ICO Factory 0x1aA1B6a7D15Dc99dc57fBC09bA502a1E26E5741a
// 0xBc1933904Aca55624C644EC630C4db25B35c3959
