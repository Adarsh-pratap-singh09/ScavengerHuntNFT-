// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 ScavengerHuntNFT
 - No imports, no constructor.
 - Owner must call initialize() once to register themselves.
 - Owner can create hunts with a clue and answerHash (keccak256 of correct answer).
 - Players submitAnswer(string memory answer): if keccak256(answer) == answerHash and they haven't claimed this hunt,
   an NFT is minted to msg.sender and they are marked as winner for that hunt.
 - Minimal ERC-721 functionality included: ownerOf, balanceOf, tokenURI (optional), approvals for transfer.
 - For simplicity metadata is a string per token (tokenURI). Admin can set tokenURI template.
*/

contract ScavengerHuntNFT {
    // --- State ---
    address public owner;
    bool private initialized;

    uint256 private _tokenIdCounter;

    // Minimal ERC721 storage
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => string) private _tokenURIs;

    // Re-entrancy guard (simple)
    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    // Hunt struct
    struct Hunt {
        string clue;           // public clue text
        bytes32 answerHash;    // keccak256 hash of correct answer (owner supplies)
        bool active;           // if hunt is active
        uint256 rewardCount;   // how many NFTs minted for this hunt
        uint256 maxRewards;    // 0 = unlimited
    }

    // hunts by id
    mapping(uint256 => Hunt) public hunts;
    uint256 public huntsCount;

    // track if address already claimed a specific hunt
    mapping(uint256 => mapping(address => bool)) public claimed;

    // --- Events ---
    event Initialized(address owner);
    event HuntCreated(uint256 huntId, string clue, uint256 maxRewards);
    event HuntClosed(uint256 huntId);
    event AnswerSubmitted(address indexed player, uint256 huntId, uint256 tokenId);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner_, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner_, address indexed operator, bool approved);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "reentrant");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    modifier huntExists(uint256 huntId) {
        require(huntId < huntsCount, "hunt not found");
        _;
    }

    // --- Initialization (replaces constructor) ---
    // Note: no constructor; deployer must call initialize() only once.
    function initialize() external {
        require(!initialized, "already initialized");
        owner = msg.sender;
        initialized = true;
        _status = _NOT_ENTERED;
        _tokenIdCounter = 1; // start token ids at 1
        emit Initialized(owner);
    }

    // --- Owner functions: create and manage hunts ---
    /// @notice Create a new hunt. answerHash = keccak256(abi.encodePacked(correctAnswer))
    /// @param clueText public clue shown to players
    /// @param answerHash keccak256 hash of correct answer
    /// @param maxRewards maximum number of winners (0 = unlimited)
    function createHunt(string memory clueText, bytes32 answerHash, uint256 maxRewards) external onlyOwner {
        Hunt storage h = hunts[huntsCount];
        h.clue = clueText;
        h.answerHash = answerHash;
        h.active = true;
        h.rewardCount = 0;
        h.maxRewards = maxRewards;
        emit HuntCreated(huntsCount, clueText, maxRewards);
        huntsCount++;
    }

    /// @notice Close a hunt (no more claims)
    function closeHunt(uint256 huntId) external onlyOwner huntExists(huntId) {
        hunts[huntId].active = false;
        emit HuntClosed(huntId);
    }

    /// @notice Owner can update the tokenURI for a token (admin metadata control)
    function setTokenURI(uint256 tokenId, string memory uri) external onlyOwner {
        require(_owners[tokenId] != address(0), "token not minted");
        _tokenURIs[tokenId] = uri;
    }

    // --- Player action: submit answer to claim reward ---
    /// @notice Submit answer for hunt. If correct and not already claimed, mints an NFT to sender.
    /// @param huntId id of the hunt
    /// @param answer plain-text answer string (owner must have stored hash of correct answer using keccak256(abi.encodePacked(answer)))
    function submitAnswer(uint256 huntId, string memory answer) external nonReentrant huntExists(huntId) returns (uint256) {
        Hunt storage h = hunts[huntId];
        require(h.active, "hunt inactive");
        require(!claimed[huntId][msg.sender], "already claimed");
        if (h.maxRewards != 0) {
            require(h.rewardCount < h.maxRewards, "max rewards reached");
        }
        bytes32 provided = keccak256(abi.encodePacked(answer));
        require(provided == h.answerHash, "wrong answer");

        // mark claimed first for safety
        claimed[huntId][msg.sender] = true;
        h.rewardCount++;

        // mint NFT to msg.sender
        uint256 tokenId = _mint(msg.sender);

        // optionally set tokenURI to include hunt id info (owner can later customize)
        // Here we set a basic placeholder tokenURI.
        _tokenURIs[tokenId] = string(abi.encodePacked("scavenger://hunt/", _uint2str(huntId), "/token/", _uint2str(tokenId)));

        emit AnswerSubmitted(msg.sender, huntId, tokenId);
        return tokenId;
    }

    // --- Minimal ERC721-like implementation ---
    function balanceOf(address owner_) public view returns (uint256) {
        require(owner_ != address(0), "zero address");
        return _balances[owner_];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address o = _owners[tokenId];
        require(o != address(0), "token does not exist");
        return o;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_owners[tokenId] != address(0), "token does not exist");
        return _tokenURIs[tokenId];
    }

    function approve(address to, uint256 tokenId) public {
        address tokenOwner = ownerOf(tokenId);
        require(to != tokenOwner, "approve to owner");
        require(msg.sender == tokenOwner || isApprovedForAll(tokenOwner, msg.sender), "not authorized");
        _tokenApprovals[tokenId] = to;
        emit Approval(tokenOwner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_owners[tokenId] != address(0), "token does not exist");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "self approval");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner_, address operator) public view returns (bool) {
        return _operatorApprovals[owner_][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "not authorized");
        _transfer(from, to, tokenId);
    }

    // internal helpers
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address tokenOwner = ownerOf(tokenId);
        return (spender == tokenOwner || getApproved(tokenId) == spender || isApprovedForAll(tokenOwner, spender));
    }

    function _mint(address to) internal returns (uint256) {
        require(to != address(0), "mint to zero");
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;

        _owners[tokenId] = to;
        _balances[to] += 1;

        emit Transfer(address(0), to, tokenId);
        return tokenId;
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "not owner");
        require(to != address(0), "transfer to zero");

        // clear approvals
        _tokenApprovals[tokenId] = address(0);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    // --- Utilities ---
    // simple uint -> string (for tokenURI placeholder)
    function _uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) { return "0"; }
        uint256 j = _i;
        uint256 len;
        while (j != 0) { len++; j /= 10; }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        j = _i;
        while (j != 0) {
            k = k - 1;
            uint8 temp = uint8(48 + j % 10);
            bstr[k] = bytes1(temp);
            j /= 10;
        }
        str = string(bstr);
    }

    // --- Admin emergency: recover tokens (if owner wants to withdraw an NFT to themselves) ---
    function adminRecoverToken(uint256 tokenId, address to) external onlyOwner {
        address currentOwner = ownerOf(tokenId);
        _transfer(currentOwner, to, tokenId);
    }

    // --- View helpers for hunts ---
    function getHuntClue(uint256 huntId) external view huntExists(huntId) returns (string memory) {
        return hunts[huntId].clue;
    }

    function getHuntInfo(uint256 huntId) external view huntExists(huntId) returns (string memory clue, bool active, uint256 rewardCount, uint256 maxRewards) {
        Hunt storage h = hunts[huntId];
        return (h.clue, h.active, h.rewardCount, h.maxRewards);
    }
}

