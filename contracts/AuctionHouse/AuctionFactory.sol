pragma solidity 0.5.8;

import "./Auction.sol";
import "../libs/SafeMath.sol";
import "../interfaces/IERC20.sol";
import "../token/SkillMeToken.sol";

/**
 * @title AuctionFactory
 *
 * @dev The Factory contract implementation the Auction process which Allows
 * a user to start an auction process and not participate in the process and
 * the winner withdraws all the money from the auction contract.
 */
contract AuctionFactory {
    using SafeMath for uint256;

    address[] public auctions;
    address public skillMeTokenAddr;

    event AuctionCreated(
        Auction auctionContract,
        address owner,
        uint256 duration,
        bool blindAuction
    );

    constructor(address _tokenInUseAddr) public {
        // I did not check if _tokeninUseAddr is a contract address
        skillMeTokenAddr = _tokenInUseAddr;
    }

    function createAuction(
        uint256 _startBlock,
        uint256 _endBlock,
        bool _auctionBlind
    ) public returns (Auction) {
        Auction newAuction = new Auction(
            skillMeTokenAddr,
            _startBlock,
            _endBlock,
            _auctionBlind
        );
        auctions.push(address(newAuction));
        uint256 duration = _endBlock.sub(_startBlock);

        emit AuctionCreated(newAuction, msg.sender, duration, _auctionBlind);
        return newAuction;
    }

    function allAuctions() public view returns (address[] memory) {
        return auctions;
    }
}
