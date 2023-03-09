// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Token.sol";
import "./UpgradableFile.sol";

contract FactoryToken is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 public tokenCreationFee;
    address[] public TokensAddress;

    // struct TokenInfo {
    //     string name;
    //     string symbol;
    //     uint256 decimal;
    // }
    // mapping(address => mapping(address => TokenInfo)) public tokenInfo;

    event Created(
        string name,
        string symbol,
        uint256 totalSupply,
        address TokenCreator,
        address TokenAddr
    );

    constructor() {
        _disableInitializers();
    }

    function initialize(uint _tokenCreationFee) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        tokenCreationFee = _tokenCreationFee;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function updateTokenCreationFee(uint256 _tokenCreationFee)
        public
        onlyOwner
        returns (bool)
    {
        tokenCreationFee = _tokenCreationFee;
        return true;
    }

    function createToken(
        string memory name,
        string memory symbol,
        uint256 supply,
        uint256 _decimal
    ) public payable returns (bool) {
        require(msg.value == tokenCreationFee, "Check fees");
        Token token = new Token(name, symbol, supply, _decimal, msg.sender);
        TokensAddress.push(address(token));
        payable(owner()).call{value: tokenCreationFee};
        emit Created(name, symbol, supply, msg.sender, address(token));
        return true;
    }

    function tokenContracts()
        public
        view
        returns (address[] memory _TokensAddress)
    {
        return TokensAddress;
    }

    // function updateTokenFee(uint _tokenCreationFee) public onlyOwner{
    //     tokenCreationFee = _tokenCreationFee;
    // }

    // function TokInfo(address icoOwner, address tokenAddress) public view returns(TokenInfo memory){
    //     return tokenInfo[icoOwner][tokenAddress];
    // }
}
//token address  0x8E3e403bD64100dcb62b421f115578C86E0eb8Cc
