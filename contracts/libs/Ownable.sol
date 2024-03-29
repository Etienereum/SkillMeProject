pragma solidity 0.5.8;

/**
 * @title Ownable
 *
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions which can be transferred, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    // The Ownable constructor sets the original `owner` of the contract to the senderaccount.
    constructor() public {
        owner = msg.sender;
    }

    // Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}
