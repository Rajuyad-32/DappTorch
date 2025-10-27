// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title DappTorch
 * @dev A decentralized knowledge sharing platform where users can create, share, and reward educational content
 */
contract DappTorch {
    
    struct Content {
        uint256 id;
        address creator;
        string title;
        string contentHash; // IPFS hash or content identifier
        uint256 timestamp;
        uint256 upvotes;
        uint256 rewards;
        bool isActive;
    }
    
    struct User {
        address userAddress;
        uint256 reputation;
        uint256 totalContributions;
        bool isRegistered;
    }
    
    mapping(uint256 => Content) public contents;
    mapping(address => User) public users;
    mapping(uint256 => mapping(address => bool)) public hasUpvoted;
    
    uint256 public contentCounter;
    uint256 public constant UPVOTE_REWARD = 1;
    uint256 public constant CONTENT_CREATION_REWARD = 10;
    
    event UserRegistered(address indexed user, uint256 timestamp);
    event ContentCreated(uint256 indexed contentId, address indexed creator, string title, uint256 timestamp);
    event ContentUpvoted(uint256 indexed contentId, address indexed voter, uint256 timestamp);
    event RewardSent(uint256 indexed contentId, address indexed creator, uint256 amount);
    
    modifier onlyRegistered() {
        require(users[msg.sender].isRegistered, "User not registered");
        _;
    }
    
    modifier contentExists(uint256 _contentId) {
        require(_contentId > 0 && _contentId <= contentCounter, "Content does not exist");
        require(contents[_contentId].isActive, "Content is not active");
        _;
    }
    
    /**
     * @dev Register a new user to the platform
     */
    function registerUser() external {
        require(!users[msg.sender].isRegistered, "User already registered");
        
        users[msg.sender] = User({
            userAddress: msg.sender,
            reputation: 0,
            totalContributions: 0,
            isRegistered: true
        });
        
        emit UserRegistered(msg.sender, block.timestamp);
    }
    
    /**
     * @dev Create new educational content
     * @param _title Title of the content
     * @param _contentHash IPFS hash or identifier of the content
     */
    function createContent(string memory _title, string memory _contentHash) external onlyRegistered {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_contentHash).length > 0, "Content hash cannot be empty");
        
        contentCounter++;
        
        contents[contentCounter] = Content({
            id: contentCounter,
            creator: msg.sender,
            title: _title,
            contentHash: _contentHash,
            timestamp: block.timestamp,
            upvotes: 0,
            rewards: 0,
            isActive: true
        });
        
        users[msg.sender].totalContributions++;
        users[msg.sender].reputation += CONTENT_CREATION_REWARD;
        
        emit ContentCreated(contentCounter, msg.sender, _title, block.timestamp);
    }
    
    /**
     * @dev Upvote a content and reward the creator
     * @param _contentId ID of the content to upvote
     */
    function upvoteContent(uint256 _contentId) external payable onlyRegistered contentExists(_contentId) {
        require(!hasUpvoted[_contentId][msg.sender], "Already upvoted this content");
        require(contents[_contentId].creator != msg.sender, "Cannot upvote own content");
        require(msg.value > 0, "Must send reward with upvote");
        
        contents[_contentId].upvotes++;
        contents[_contentId].rewards += msg.value;
        hasUpvoted[_contentId][msg.sender] = true;
        
        users[contents[_contentId].creator].reputation += UPVOTE_REWARD;
        
        payable(contents[_contentId].creator).transfer(msg.value);
        
        emit ContentUpvoted(_contentId, msg.sender, block.timestamp);
        emit RewardSent(_contentId, contents[_contentId].creator, msg.value);
    }
    
    /**
     * @dev Get content details
     * @param _contentId ID of the content
     */
    function getContent(uint256 _contentId) external view contentExists(_contentId) returns (
        uint256 id,
        address creator,
        string memory title,
        string memory contentHash,
        uint256 timestamp,
        uint256 upvotes,
        uint256 rewards
    ) {
        Content memory content = contents[_contentId];
        return (
            content.id,
            content.creator,
            content.title,
            content.contentHash,
            content.timestamp,
            content.upvotes,
            content.rewards
        );
    }
    
    /**
     * @dev Get user details
     * @param _user Address of the user
     */
    function getUser(address _user) external view returns (
        address userAddress,
        uint256 reputation,
        uint256 totalContributions,
        bool isRegistered
    ) {
        User memory user = users[_user];
        return (
            user.userAddress,
            user.reputation,
            user.totalContributions,
            user.isRegistered
        );
    }
}