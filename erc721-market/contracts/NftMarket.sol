// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract NftMarket is ERC721Holder, Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    using SafeERC20 for IERC20;

    enum CollectionStatus {
        Pending,
        Open,
        Close
    }

    address public adminAddress;
    address public treasuryAddress;

    mapping(address => uint256) public pendingRevenue;

    EnumerableSet.AddressSet private _collectionAddressSet;
    mapping(address => Collection) private _collections;
    mapping(address => mapping(address => EnumerableSet.UintSet))
        private _tokenIdsOfSellerForCollection;

    mapping(address => mapping(uint256 => Auction)) private _auctionDetails;

    mapping(address => mapping(uint256 => Order)) private _orderDetails;
    mapping(address => EnumerableSet.UintSet) private _orderTokenIds;

    struct Collection {
        CollectionStatus status;
        address creator;
        uint256 marketFee; // market fee (100 = 1%, 500 = 5%, 5 = 0.05%)
        uint256 creatorFee; // creator fee (100 = 1%, 500 = 5%, 5 = 0.05%)
    }

    struct Auction {
        address highestBidder;
        uint256 startingPrice;
        uint256 highestPrice;
        uint256 endTime;
    }

    struct Order {
        address seller;
        uint256 price;
    }

    // User Event
    event ExecuteOrder(
        address indexed collection,
        address indexed seller,
        uint256 indexed tokenId,
        uint256 price
    );

    event UpdateOrder(
        address indexed collection,
        address indexed seller,
        uint256 indexed tokenId,
        uint256 price
    );

    event CancelOrder(
        address indexed collection,
        address indexed seller,
        uint256 indexed tokenId
    );

    event Trade(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        uint256 price
    );

    event RevenueClaim(address indexed claimer, uint256 amount);

    event AddAuction(
        address indexed collection,
        address indexed seller,
        uint256 indexed tokenId,
        uint256 startingPrice,
        uint256 endTime
    );

    event CancelAuction(
        address indexed collection,
        address indexed seller,
        uint256 indexed tokenId
    );

    // Admin Event
    event AddCollection(
        address collection,
        address creator,
        uint256 marketFee,
        uint256 creatorFee
    );

    event UpdateCollection(
        address collection,
        address creator,
        uint256 marketFee,
        uint256 creatorFee
    );

    event UpdateAdminAndTreasuryAddresses(
        address indexed adminAddress,
        address indexed treasuryAddress
    );

    event RecoveryNonFungibleToken(address indexed token, uint256 tokenId);

    event RecoveryFungibleToken(address indexed token, uint256 amount);

    constructor(address _adminAddress, address _treasuryAddress) {
        require(
            _adminAddress != address(0),
            "Operations: Admin address cannot be zero"
        );
        require(
            _treasuryAddress != address(0),
            "Operations: Treasury address cannot be zero"
        );

        adminAddress = _adminAddress;
        treasuryAddress = _treasuryAddress;
    }

    // User Function

    /**
     * @notice ?????? ????????? ??????.
     * @param _collection: ????????? ??????
     * @param _tokenId: ????????? ?????? ?????????
     * @param _price: ????????????
     */
    function executeOrder(
        address _collection,
        uint256 _tokenId,
        uint256 _price
    ) external nonReentrant {
        require(
            _collections[_collection].status == CollectionStatus.Open,
            "Collection: Not for listing"
        );

        IERC721(_collection).safeTransferFrom(
            address(msg.sender),
            address(this),
            _tokenId
        );

        _tokenIdsOfSellerForCollection[msg.sender][_collection].add(_tokenId);
        _orderDetails[_collection][_tokenId] = Order({
            seller: msg.sender,
            price: _price
        });

        emit ExecuteOrder(_collection, msg.sender, _tokenId, _price);
    }

    /**
     * @notice ????????? ??????????????????.
     * @param _collection: ????????? ??????
     * @param _tokenId: ?????? ?????????
     * @param _newPrice: ????????? ??????
     */
    function updateOrder(
        address _collection,
        uint256 _tokenId,
        uint256 _newPrice
    ) external nonReentrant {
        require(
            _collections[_collection].status == CollectionStatus.Open,
            "Collection: Not for listing"
        );

        _orderDetails[_collection][_tokenId].price = _newPrice;

        emit UpdateOrder(_collection, msg.sender, _tokenId, _newPrice);
    }

    /**
     * @notice ????????? ????????????.
     * @param _collection: ????????? ??????
     * @param _tokenId: ?????? ?????????
     */
    function cancelOrder(
        address _collection,
        uint256 _tokenId
    ) external nonReentrant {
        require(
            _collections[_collection].status == CollectionStatus.Open,
            "Collection: Not for listing"
        );

        _tokenIdsOfSellerForCollection[msg.sender][_collection].remove(
            _tokenId
        );
        delete _orderDetails[_collection][_tokenId];
        _orderTokenIds[_collection].remove(_tokenId);

        IERC721(_collection).transferFrom(
            address(this),
            address(msg.sender),
            _tokenId
        );

        emit CancelOrder(_collection, msg.sender, _tokenId);
    }

    /**
     * @notice ????????? ????????????.
     * @param _collection: ????????? ??????
     * @param _tokenId: ?????? ?????????
     * @param _price: ??????
     */
    function buyToken(
        address _collection,
        uint256 _tokenId,
        uint256 _price
    ) internal {
        require(
            _collections[_collection].status == CollectionStatus.Open,
            "Collection: Not for trading"
        );
        require(
            _orderTokenIds[_collection].contains(_tokenId),
            "Buy: Not for sale"
        );

        Order memory order = _orderDetails[_collection][_tokenId];

        require(_price == order.price, "Buy: Incorrect price");
        require(msg.sender != order.seller, "Buy: Buyer cannot be seller");

        (
            uint256 netPrice,
            uint256 marketFee,
            uint256 creatorFee
        ) = _calculatePriceAndFees(_collection, _price);

        _tokenIdsOfSellerForCollection[order.seller][_collection].remove(
            _tokenId
        );
        delete _orderDetails[_collection][_tokenId];
        _orderTokenIds[_collection].remove(_tokenId);

        (bool sent, ) = payable(order.seller).call{value: netPrice}("");
        require(sent, "Failed to send Ether");

        if (creatorFee != 0) {
            pendingRevenue[_collections[_collection].creator] += creatorFee;
        }

        if (marketFee != 0) {
            pendingRevenue[treasuryAddress] += marketFee;
        }

        IERC721(_collection).safeTransferFrom(
            address(this),
            address(msg.sender),
            _tokenId
        );

        emit Trade(_collection, _tokenId, order.seller, msg.sender, _price);
    }

    /**
     * @notice ?????? ?????????
     */
    function claimPendingRevenue() external nonReentrant {
        uint256 revenueToClaim = pendingRevenue[msg.sender];
        require(revenueToClaim != 0, "Claim: Nothing to claim");
        pendingRevenue[msg.sender] = 0;

        (bool sent, ) = payable(msg.sender).call{value: revenueToClaim}("");
        require(sent, "Failed to send Ether");

        emit RevenueClaim(msg.sender, revenueToClaim);
    }

    /**
     * @notice ????????? ???????????? ????????????.
     * @param _collection: ????????? ??????
     * @param _price: ??????
     * @return netPrice
     * @return marketFee
     * @return creatorFee
     */
    function _calculatePriceAndFees(
        address _collection,
        uint256 _price
    )
        internal
        view
        returns (uint256 netPrice, uint256 marketFee, uint256 creatorFee)
    {
        marketFee = (_price * _collections[_collection].marketFee) / 10000;
        creatorFee = (_price * _collections[_collection].creatorFee) / 10000;

        netPrice = _price - marketFee - creatorFee;

        return (netPrice, marketFee, creatorFee);
    }

    /**
     * @notice ????????? ????????????.
     * @param _collection: ????????? ??????
     * @param _tokenId: ?????? ?????????
     * @param _startingPrice: ?????? ?????????
     * @param _endTime: ?????? ????????????
     */
    function addAuction(
        address _collection,
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endTime
    ) external nonReentrant {
        require(
            !_collectionAddressSet.contains(_collection),
            "Operations: Collection already listed"
        );
        require(
            IERC721(_collection).supportsInterface(0x80ac58cd),
            "Operations: Not ERC721"
        );
        require(
            IERC721(_collection).ownerOf(_tokenId) == msg.sender,
            "Operations: Not Token Owner"
        );
        require(
            block.timestamp > _endTime,
            "Auction: endTime More Than block timestamp"
        );

        _auctionDetails[_collection][_tokenId] = Auction({
            highestBidder: address(0),
            startingPrice: _startingPrice,
            highestPrice: _startingPrice,
            endTime: _endTime
        });

        emit AddAuction(
            _collection,
            msg.sender,
            _tokenId,
            _startingPrice,
            _endTime
        );
    }

    /**
     * @notice ????????? ????????????.
     * @param _collection: ????????? ??????
     * @param _tokenId: ?????? ?????????
     */
    function cancelAuction(
        address _collection,
        uint256 _tokenId
    ) external nonReentrant {
        require(
            !_collectionAddressSet.contains(_collection),
            "Operations: Collection already listed"
        );
        require(
            IERC721(_collection).supportsInterface(0x80ac58cd),
            "Operations: Not ERC721"
        );
        require(
            IERC721(_collection).ownerOf(_tokenId) == msg.sender,
            "Operations: Not Token Owner"
        );

        delete _auctionDetails[_collection][_tokenId];

        emit CancelAuction(_collection, msg.sender, _tokenId);
    }

    // Admin Function
    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Management: Not admin");
        _;
    }

    /**
     * @notice ???????????? ????????????.
     * @param _collection: ????????? ??????
     * @param _creator: ?????? ??????
     * @param _marketFee: ?????? ?????????
     * @param _creatorFee: ?????? ?????????
     */
    function addCollection(
        address _collection,
        address _creator,
        uint256 _marketFee,
        uint256 _creatorFee
    ) external onlyAdmin {
        require(
            !_collectionAddressSet.contains(_collection),
            "Operations: Collection already listed"
        );
        require(
            IERC721(_collection).supportsInterface(0x80ac58cd),
            "Operations: Not ERC721"
        );
        require(
            _creator == address(0),
            "Operation: Creator parameters incorrect"
        );

        _collectionAddressSet.add(_collection);

        _collections[_collection] = Collection({
            status: CollectionStatus.Open,
            creator: _creator,
            marketFee: _marketFee,
            creatorFee: _creatorFee
        });

        emit AddCollection(_collection, _creator, _marketFee, _creatorFee);
    }

    /**
     * @notice ???????????? ????????????.
     * @param _collection: ????????? ??????
     * @param _creator: ?????? ??????
     * @param _marketFee: ?????? ?????????
     * @param _creatorFee: ?????? ?????????
     */
    function updateCollection(
        address _collection,
        address _creator,
        uint256 _marketFee,
        uint256 _creatorFee
    ) external onlyAdmin {
        require(
            !_collectionAddressSet.contains(_collection),
            "Operations: Collection already listed"
        );
        require(
            IERC721(_collection).supportsInterface(0x80ac58cd),
            "Operations: Not ERC721"
        );
        require(
            _creator == address(0),
            "Operation: Creator parameters incorrect"
        );

        _collections[_collection] = Collection({
            status: CollectionStatus.Open,
            creator: _creator,
            marketFee: _marketFee,
            creatorFee: _creatorFee
        });

        emit UpdateCollection(_collection, _creator, _marketFee, _creatorFee);
    }

    /**
     * @notice ?????????, ???????????? ????????? ????????????.
     * @param _adminAddress: ????????? ??????
     * @param _treasuryAddress: ???????????? ??????
     */
    function updateAdminAndTreasuryAddresses(
        address _adminAddress,
        address _treasuryAddress
    ) external onlyOwner {
        require(
            _adminAddress != address(0),
            "Operations: Admin address cannot be zero"
        );
        require(
            _treasuryAddress != address(0),
            "Operations: Treasury address cannot be zero"
        );

        adminAddress = _adminAddress;
        treasuryAddress = _treasuryAddress;

        emit UpdateAdminAndTreasuryAddresses(_adminAddress, _treasuryAddress);
    }

    /**
     * @notice ???????????? ????????? ????????? NFT??? ????????? ????????? ?????????.
     * @param _token: ????????????
     * @param _tokenId: ?????? ?????????
     */
    function recoveryNonFungibleToken(
        address _token,
        uint256 _tokenId
    ) external onlyOwner nonReentrant {
        IERC721(_token).safeTransferFrom(
            address(this),
            address(msg.sender),
            _tokenId
        );

        emit RecoveryNonFungibleToken(_token, _tokenId);
    }

    /**
     * @notice ???????????? ????????? ????????? ????????? ??????????????? ????????? ?????????.
     * @param _token: ????????????
     */
    function recoveryFungibleToken(address _token) external onlyOwner {
        uint256 amountToRecover = IERC20(_token).balanceOf(address(this));
        require(amountToRecover != 0, "Operations: No token to recover");

        IERC20(_token).safeTransfer(address(msg.sender), amountToRecover);

        emit RecoveryFungibleToken(_token, amountToRecover);
    }

    // Query Function

    /**
     * @notice ???????????? ?????? ??????Ids??? ????????????.
     * @param collection: ????????? ??????
     * @param tokenIds: ?????? ????????? ??????
     * @return statuses
     * @return orderInfo
     */
    function viewOrderByCollectionAndTokenIds(
        address collection,
        uint256[] calldata tokenIds
    ) external view returns (bool[] memory statuses, Order[] memory orderInfo) {
        uint256 length = tokenIds.length;

        statuses = new bool[](length);
        orderInfo = new Order[](length);

        for (uint256 i = 0; i < length; i++) {
            if (_orderTokenIds[collection].contains(tokenIds[i])) {
                statuses[i] = true;
            } else {
                statuses[i] = false;
            }

            orderInfo[i] = _orderDetails[collection][tokenIds[i]];
        }

        return (statuses, orderInfo);
    }

    /**
     * @notice ???????????? ????????? ????????????.
     * @param collection: ????????? ??????
     * @param cursor: ??????
     * @param size: ?????????
     * @return tokenIds
     * @return orderInfo
     * @return
     */
    function viewOrderByCollection(
        address collection,
        uint256 cursor,
        uint256 size
    )
        external
        view
        returns (uint256[] memory tokenIds, Order[] memory orderInfo, uint256)
    {
        uint256 length = size;

        if (length > _orderTokenIds[collection].length() - cursor) {
            length = _orderTokenIds[collection].length() - cursor;
        }

        tokenIds = new uint256[](length);
        orderInfo = new Order[](length);

        for (uint256 i = 0; i < length; i++) {
            tokenIds[i] = _orderTokenIds[collection].at(cursor + i);
            orderInfo[i] = _orderDetails[collection][tokenIds[i]];
        }

        return (tokenIds, orderInfo, cursor + length);
    }

    /**
     * @notice ?????????, ????????? ????????? ????????????.
     * @param collection: ????????? ??????
     * @param seller: ????????? ??????
     * @param cursor: ??????
     * @param size: ?????????
     * @return tokenIds
     * @return orderInfo
     * @return
     */
    function viewOrderByCollectionAndSeller(
        address collection,
        address seller,
        uint256 cursor,
        uint256 size
    )
        external
        view
        returns (uint256[] memory tokenIds, Order[] memory orderInfo, uint256)
    {
        uint256 length = size;

        if (length > _orderTokenIds[collection].length() - cursor) {
            length = _orderTokenIds[collection].length() - cursor;
        }

        tokenIds = new uint256[](length);
        orderInfo = new Order[](length);

        for (uint256 i = 0; i < length; i++) {
            tokenIds[i] = _tokenIdsOfSellerForCollection[seller][collection].at(
                cursor + i
            );
            orderInfo[i] = _orderDetails[collection][tokenIds[i]];
        }

        return (tokenIds, orderInfo, cursor + length);
    }

    /**
     * @notice ??????????????? ???????????? ??????.
     * @param cursor: ??????
     * @param size: ?????????
     * @return collectionAddresses
     * @return collectionDetails
     * @return
     */
    function viewCollections(
        uint256 cursor,
        uint256 size
    )
        external
        view
        returns (
            address[] memory collectionAddresses,
            Collection[] memory collectionDetails,
            uint256
        )
    {
        uint256 length = size;

        if (length > _collectionAddressSet.length() - cursor) {
            length = _collectionAddressSet.length() - cursor;
        }

        collectionAddresses = new address[](length);
        collectionDetails = new Collection[](length);

        for (uint256 i = 0; i < length; i++) {
            collectionAddresses[i] = _collectionAddressSet.at(cursor + i);
            collectionDetails[i] = _collections[collectionAddresses[i]];
        }

        return (collectionAddresses, collectionDetails, cursor + length);
    }
}
