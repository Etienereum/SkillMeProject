pragma solidity 0.5.8;

import "../libs/SafeMath.sol";
import "../libs/Ownable.sol";
import "../interfaces/IERC20.sol";
import "../token/SkillMeToken.sol";

/**
 * @title Auction
 *
 * @dev The Auction contract implementation for the SkillMeToken project.
 */
contract Auction is Ownable {
    using SafeMath for uint256;

    // static
    IERC20 public skillMeToken;
    // SkillMeToken public skillMeToken;
    address public auctionOwner;
    uint256 public startBlock;
    uint256 public endBlock;

    // state
    bool public auctionBlind;
    bool public auctionCanceled;
    address internal activeHighestBidder;
    uint256 internal activeHighestBid;
    mapping(address => uint256) internal fundsByBidders;

    event LogBid(address highestBidder, uint256 highestBid);
    event LogWithdrawal(address withdrawer, uint256 amount);
    event LogCanceled();

    modifier onlyAuctionOwner() {
        require(msg.sender == auctionOwner);
        _;
    }

    modifier onlyNotAuctionOwner() {
        require(msg.sender != auctionOwner);
        _;
    }

    modifier onlyAfterAuctionStart() {
        require(block.number >= startBlock);
        _;
    }

    modifier onlyBeforeAuctionEnd() {
        require(block.number < endBlock);
        _;
    }

    modifier onlyNotAuctionCanceled() {
        require(!auctionCanceled);
        _;
    }

    modifier onlyAuctionEnd() {
        require(block.number >= endBlock);
        _;
    }

    modifier onlyWhenAuctionNotBlind() {
        require(auctionBlind != true);
        _;
    }

    constructor(
        address _skillMeTokenAddr,
        uint256 _startBlock,
        uint256 _endBlock,
        bool _auctionBlind
    ) public {
        require(_startBlock < _endBlock);
        require(_startBlock < block.number);

        skillMeToken = IERC20(_skillMeTokenAddr);
        auctionOwner = msg.sender;
        auctionBlind = _auctionBlind;
        startBlock = _startBlock;
        endBlock = _endBlock;
    }

    function approving(uint256 _bidAmount) public returns (bool) {
        skillMeToken.approve(address(this), _bidAmount);

        return true;
    }

    function placeBid(uint256 _bidAmount)
        public
        onlyNotAuctionOwner
        onlyAfterAuctionStart
        onlyBeforeAuctionEnd
        onlyNotAuctionCanceled
        returns (bool success)
    {
        // Check to know if the Bidder has enough tokens to place a bid
        require(_bidAmount <= skillMeToken.balanceOf(msg.sender));

        // calculate the user's total bid, current bid amount plus fromal bid (if any)
        uint256 userNewBid = fundsByBidders[msg.sender].add(_bidAmount);

        // Check if user's New bis out bids current active bid.
        require(userNewBid > activeHighestBid);

        // Transfer Token to this contract
        skillMeToken.transferFrom(msg.sender, address(this), _bidAmount);

        // // Save current bidder's details
        fundsByBidders[msg.sender] = userNewBid;
        activeHighestBid = userNewBid;
        activeHighestBidder = msg.sender;

        emit LogBid(activeHighestBidder, activeHighestBid);

        return true;
    }

    function withdraw()
        public
        onlyAuctionEnd
        onlyNotAuctionCanceled
        returns (bool success)
    {
        require(msg.sender == activeHighestBidder);

        uint256 contractBalance = skillMeToken.balanceOf(address(this));
        skillMeToken.transfer(msg.sender, contractBalance);

        //Terminate the Auction
        auctionCanceled = true;

        emit LogWithdrawal(msg.sender, contractBalance);

        return true;
    }

    function cancelAuction()
        public
        onlyAuctionOwner
        onlyBeforeAuctionEnd
        onlyNotAuctionCanceled
        returns (bool success)
    {
        auctionCanceled = true;

        emit LogCanceled();
        return true;
    }

    function getBidderFunds(address _user)
        public
        view
        onlyWhenAuctionNotBlind
        returns (uint256)
    {
        return fundsByBidders[_user];
    }

    function getHighestBidderDetails()
        public
        view
        onlyWhenAuctionNotBlind
        returns (address, uint256)
    {
        return (activeHighestBidder, activeHighestBid);
    }
}
