pragma solidity 0.5.8;

import "../libs/SafeMath.sol";
import "../token/StandardToken.sol";

/**
 * @title BlackList
 *
 * @dev A contract which is a mechanism to allow the implementation of BlackListing bad addresses.
 */
contract BlackList is Ownable, StandardToken {
    mapping(address => bool) public isBlackListed;

    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);
    event DestroyedBlackFunds(address _blackListedUser, uint256 _balance);

    function getOwner() external view returns (address) {
        return owner;
    }

    // Getters to allow the same blacklist to be used also by other contracts
    function getBlackListStatus(address _checkUser)
        external
        view
        returns (bool)
    {
        return isBlackListed[_checkUser];
    }

    function addBlackList(address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList(address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    function destroyBlackFunds(address _blackListedUser) public onlyOwner {
        require(isBlackListed[_blackListedUser]);
        uint256 dirtyFunds = _balanceOf(_blackListedUser);
        balances[_blackListedUser] = 0;
        _totalSupply -= dirtyFunds;
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }
}
