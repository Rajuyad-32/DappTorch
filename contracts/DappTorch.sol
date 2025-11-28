// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title DappTorch
 * @dev Registry and rating system for dApps
 * @notice Developers register dApps; users can rate them 1–5; contract keeps aggregate stats
 */
contract DappTorch {
    address public owner;

    struct Dapp {
        uint256 id;
        address developer;
        string  name;
        string  url;
        string  category;      // e.g. "defi", "nft", "game"
        uint256 createdAt;
        bool    isActive;
    }

    struct RatingStats {
        uint256 ratingCount;
        uint256 ratingSum;     // sum of all ratings (1–5)
    }

    uint256 public nextDappId;

    // dappId => Dapp
    mapping(uint256 => Dapp) public dapps;

    // dappId => stats
    mapping(uint256 => RatingStats) public ratings;

    // user => dappId => rating given (0 = none)
    mapping(address => mapping(uint256 => uint8)) public userRating;

    // developer => dappIds[]
    mapping(address => uint256[]) public dappsOf;

    event DappRegistered(
        uint256 indexed id,
        address indexed developer,
        string name,
        string url,
        string category,
        uint256 timestamp
    );

    event DappStatusUpdated(
        uint256 indexed id,
        bool isActive,
        uint256 timestamp
    );

    event DappRated(
        uint256 indexed id,
        address indexed rater,
        uint8 rating,
        uint256 ratingCount,
        uint256 ratingSum
    );

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier dappExists(uint256 id) {
        require(dapps[id].developer != address(0), "Dapp not found");
        _;
    }

    modifier onlyDeveloper(uint256 id) {
        require(dapps[id].developer == msg.sender, "Not developer");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Register a new dApp
     */
    function registerDapp(
        string calldata name,
        string calldata url,
        string calldata category
    ) external returns (uint256 id) {
        id = nextDappId++;

        dapps[id] = Dapp({
            id: id,
            developer: msg.sender,
            name: name,
            url: url,
            category: category,
            createdAt: block.timestamp,
            isActive: true
        });

        dappsOf[msg.sender].push(id);

        emit DappRegistered(id, msg.sender, name, url, category, block.timestamp);
    }

    /**
     * @dev Activate / deactivate a dApp
     */
    function setDappActive(uint256 id, bool active)
        external
        dappExists(id)
        onlyDeveloper(id)
    {
        dapps[id].isActive = active;
        emit DappStatusUpdated(id, active, block.timestamp);
    }

    /**
     * @dev Rate a dApp with score in [1,5]. Re-rating overwrites previous rating.
     */
    function rateDapp(uint256 id, uint8 rating)
        external
        dappExists(id)
    {
        require(dapps[id].isActive, "Inactive dApp");
        require(rating >= 1 && rating <= 5, "Rating 1-5");

        RatingStats storage stats = ratings[id];
        uint8 prev = userRating[msg.sender][id];

        if (prev == 0) {
            // first rating
            stats.ratingCount += 1;
            stats.ratingSum += rating;
        } else {
            // update rating
            stats.ratingSum = stats.ratingSum - prev + rating;
        }

        userRating[msg.sender][id] = rating;

        emit DappRated(id, msg.sender, rating, stats.ratingCount, stats.ratingSum);
    }

    /**
     * @dev View: average rating *scaled* by 1e2 (2 decimals) to avoid floating point
     */
    function getAverageRating(uint256 id)
        external
        view
        dappExists(id)
        returns (uint256 avgTimes100)
    {
        RatingStats memory s = ratings[id];
        if (s.ratingCount == 0) return 0;
        avgTimes100 = (s.ratingSum * 100) / s.ratingCount;
    }

    /**
     * @dev Get all dApp IDs by a developer
     */
    function getDappsOf(address developer) external view returns (uint256[] memory) {
        return dappsOf[developer];
    }

    /**
     * @dev Transfer contract ownership
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        address prev = owner;
        owner = newOwner;
        emit OwnershipTransferred(prev, newOwner);
    }
}
