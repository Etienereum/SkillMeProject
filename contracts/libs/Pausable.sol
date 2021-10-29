pragma solidity 0.5.8;

import "../libs/Ownable.sol";

/**
 * @title Pausable
 *
 * @dev A contract which is a mechanism to allow the implementation an emergency stop.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    // Modifier to make a function callable only when the contract is not paused.
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    // Modifier to make a function callable only when the contract is paused.
    modifier whenPaused() {
        require(paused);
        _;
    }

    // Called by the owner to pause and trigger stopped state.
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    // Called by the owner to unpause and return state to normal.
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}
