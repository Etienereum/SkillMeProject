pragma solidity 0.5.8;

import "../libs/SafeMath.sol";
import "../libs/Ownable.sol";
import "../interfaces/IERC20.sol";

/**
 * @title StandardToken
 *
 * @dev Implementation of the Interface of the ERC20 standard token.
 */
contract StandardToken is Ownable, IERC20 {
    using SafeMath for uint256;

    uint256 internal _totalSupply;
    uint256 public constant MAX_UINT = 2**256 - 1;
    // Variables for setting transaction fees if it ever becames necessary
    uint256 public basisPointsRate = 0;
    uint256 public maximumFee = 0;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) public allowed;

    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function _transfer(address _to, uint256 _value) internal returns (bool) {
        uint256 fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        uint256 sendAmount = _value.sub(fee);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
            emit Transfer(msg.sender, owner, fee);
        }
        emit Transfer(msg.sender, _to, sendAmount);

        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint the amount of tokens to be transferred
     */
    function _transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) internal returns (bool) {
        uint256 _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // if (_value > _allowance) throw;

        uint256 fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        if (_allowance < MAX_UINT) {
            allowed[_from][msg.sender] = _allowance.sub(_value);
        }
        uint256 sendAmount = _value.sub(fee);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
            emit Transfer(_from, owner, fee);
        }
        emit Transfer(_from, _to, sendAmount);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function _approve(address _spender, uint256 _value)
        internal
        returns (bool)
    {
        // To change the approve amount you first have to reduce the addresses`
        // allowance to zero by calling `approve(_spender, 0)` if it is not
        // already 0
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return An uint representing the amount owned by the passed address.
     */
    function _balanceOf(address _owner)
        internal
        view
        returns (uint256 balance)
    {
        return balances[_owner];
    }

    /**
     * @dev Function to check the amount of tokens than an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint specifying the amount of tokens still available for the spender.
     */
    function _allowance(address _owner, address _spender)
        internal
        view
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }
}
