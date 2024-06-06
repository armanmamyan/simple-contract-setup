// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SimpleNFTContract is ERC721A, ReentrancyGuard, Ownable {
    event SetMaximumAllowedTokens(uint256 _count);
    event SetMaximumSupply(uint256 _count);
    event SetMaximumAllowedTokensPerWallet(uint256 _count);
    event SetMaxTokenForPresale(uint256 _count);
    event SetRoot(bytes32 _root);
    event SetPrice(uint256 _price);
    event SetPresalePrice(uint256 _price);
    event SetBaseUri(string baseURI);
    event Mint(address userAddress, uint256 _count);

    uint256 public mintPrice = 0.03 ether;
    uint256 public presalePrice = 0.01 ether;
    
    bytes32 public merkleRoot;

    uint256 private reserveAtATime = 67;
    uint256 private reservedCount = 0;
    uint256 private maxReserveCount = 268;

    string _baseTokenURI;

    bool public isActive = false;
    bool public isPresaleActive = false;

    uint256 public MAX_SUPPLY = 8888;
    uint256 public maximumAllowedTokensPerPurchase = 5;
    uint256 public maximumAllowedTokensPerWallet = 5;
    uint256 public presaleWalletLimitation = 5;

    constructor(
        string memory baseURI,
        bytes32 _merkleRoot
    ) ERC721A("NAME_WITH_SPACING", "CONTRACT_SHORT_NAME") {
        setBaseURI(baseURI);
        setMerkleRootHash(_merkleRoot);
    }

    modifier saleIsOpen(uint256 _mintAmount) {
        uint256 currentSupply = totalSupply();

        require(currentSupply <= MAX_SUPPLY, "Sale has ended.");
        require(currentSupply + _mintAmount <= MAX_SUPPLY, "All CNR minted.");
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof) {
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            tx.origin == msg.sender,
            "Calling from other contract is not allowed."
        );
        require(
            _mintAmount > 0 &&
                numberMinted(msg.sender) + _mintAmount <=
                maximumAllowedTokensPerWallet,
            "Invalid mint amount or minted max amount already."
        );
        _;
    }

    modifier presaleMintCompliance(uint256 _mintAmount) {
        require(
            tx.origin == msg.sender,
            "Calling from other contract is not allowed."
        );
        require(
            _mintAmount > 0 &&
                numberMinted(msg.sender) + _mintAmount <=
                presaleWalletLimitation,
            "Invalid mint amount or minted max amount already."
        );
        _;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setMerkleRootHash(bytes32 _rootHash) public onlyOwner {
        merkleRoot = _rootHash;
        emit SetRoot(_rootHash);
    }

    function setMaxReserve(uint256 val) public onlyOwner {
        maxReserveCount = val;
    }

    function setReserveAtATime(uint256 val) public onlyOwner {
        reserveAtATime = val;
    }

    function getReserveAtATime() external view returns (uint256) {
        return reserveAtATime;
    }

    function setMaximumAllowedTokens(uint256 _count) public onlyOwner {
        maximumAllowedTokensPerPurchase = _count;
        emit SetMaximumAllowedTokens(_count);
    }

    function setMaximumAllowedTokensPerWallet(uint256 _count) public onlyOwner {
        maximumAllowedTokensPerWallet = _count;
        emit SetMaximumAllowedTokensPerWallet(_count);
    }

    function setMaxMintSupply(uint256 maxMintSupply) external onlyOwner {
        MAX_SUPPLY = maxMintSupply;
        emit SetMaximumSupply(maxMintSupply);
    }

    function setPrice(uint256 _price) public onlyOwner {
        mintPrice = _price;
        emit SetPrice(_price);
    }

    function setPresalePrice(uint256 _presalePrice) public onlyOwner {
        presalePrice = _presalePrice;
        emit SetPresalePrice(_presalePrice);
    }

    function toggleSaleStatus() public onlyOwner {
        isActive = !isActive;
    }

    function togglePresaleActive() external onlyOwner {
        isPresaleActive = !isPresaleActive;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
        emit SetBaseUri(baseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function airdrop(uint256 _count, address _address) external onlyOwner {
        uint256 supply = totalSupply();

        require(supply <= MAX_SUPPLY, "Total supply spent.");
        require(supply + _count <= MAX_SUPPLY, "Total supply exceeded.");

        _safeMint(_address, _count);
    }

    function mint(
        uint256 _count
    ) public payable mintCompliance(_count) saleIsOpen(_count) nonReentrant {
        if (msg.sender != owner()) {
            require(isActive, "Sale is not active currently.");
        }

        require(
            _count <= maximumAllowedTokensPerPurchase,
            "Exceeds maximum allowed tokens"
        );
        require(
            msg.value >= (mintPrice * _count),
            "Insufficient ETH amount sent."
        );

        _safeMint(msg.sender, _count);
        emit Mint(msg.sender, _count);
    }

    function preSaleMint(
        bytes32[] calldata _merkleProof,
        uint256 _count
    )
        public
        payable
        isValidMerkleProof(_merkleProof)
        presaleMintCompliance(_count)
        saleIsOpen(_count)
    {
        uint256 mintIndex = totalSupply();

        require(isPresaleActive, "Presale is not active");
        require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
        require(
            msg.value >= presalePrice * _count,
            "Insuffient ETH amount sent."
        );

        _safeMint(msg.sender, _count);
        emit Mint(msg.sender, _count);
    }

    function withdraw() external onlyOwner nonReentrant {
        uint balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }
}
