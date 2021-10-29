pragma solidity 0.5.8;

import "../libs/Pausable.sol";
import "../libs/BlackList.sol";
import "../token/StandardToken.sol";

/**
 * @title SkillMeToken
 *
 * @dev The main contract implementation of the ERC20 Standard Stablecoin
 * for the SkillMeToken project.
 */
contract SkillMeToken is StandardToken, Pausable, BlackList {
    // name         - Name of the Token
    // symbol       - Symblo of the Token
    // decimals     - Token decimals
    string public name = "SkillMeToken";
    string public symbol = "SMT";
    uint256 public decimals = 18;

    event Issue(uint256 amount);
    event Redeem(uint256 amount);
    event Params(uint256 feeBasisPoints, uint256 maxFee);

    /** The contract can be initialized with a number of tokens.
     *  The initialized and issued tokens are deposited to the owner address.
     *
     *  @param _initialSupply    - balance Initial supply of the contract
     */
    constructor(uint256 _initialSupply) public {
        _totalSupply = _initialSupply;
        balances[owner] = _initialSupply;
    }

    function transfer(address _to, uint256 _value)
        public
        whenNotPaused
        returns (bool)
    {
        require(!isBlackListed[msg.sender]);
        return super._transfer(_to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public whenNotPaused returns (bool) {
        require(!isBlackListed[_from]);
        return super._transferFrom(_from, _to, _value);
    }

    function balanceOf(address who) public view returns (uint256) {
        return super._balanceOf(who);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        return super._approve(_spender, _value);
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return super._allowance(_owner, _spender);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /** issue - Issue more tokens which are deposited into the owner address
     *
     * @param _amount - Number of tokens to be issued
     */
    function issue(uint256 _amount) public onlyOwner {
        require(_totalSupply + _amount > _totalSupply);
        require(balances[owner] + _amount > balances[owner]);

        balances[owner] += _amount;
        _totalSupply += _amount;
        emit Issue(_amount);
    }

    /** redeem - Redeem tokens are withdrawn from the owner address and
     *  the balance must be enough to cover the redeem or the call will fail.
     *
     *  @param _amount Number of tokens to be issued
     */
    function redeem(uint256 _amount) public onlyOwner {
        require(_totalSupply >= _amount);
        require(balances[owner] >= _amount);

        _totalSupply -= _amount;
        balances[owner] -= _amount;
        emit Redeem(_amount);
    }

    /** setParams - SetParams allow the Owner to set parameters for fees
     *  It ensures transparency by hardcoding limit beyond which fees can never be added
     *
     *  @param newBasisPoints - for a new BasicPoints
     *  @param newMaxFee - to set a new maxFee
     */
    function setParams(uint256 newBasisPoints, uint256 newMaxFee)
        public
        onlyOwner
    {
        require(newBasisPoints < 20);
        require(newMaxFee < 50);

        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee.mul(10**decimals);

        emit Params(basisPointsRate, maximumFee);
    }
}
