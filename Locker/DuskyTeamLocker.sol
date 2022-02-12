// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract DuskyTeamLocker {
    // BEP20 basic token contract being held
    IBEP20 private immutable _token;

    // where the released tokens will be sent
    address private immutable _teamWallet =
        0x963521340c3082a7EfE88435322024C0D6595830;

    uint256 private Period = 30 days;

    uint256 private releaseAmount; // will be 10% every month for 10 Months

    uint256 private nextReleaseTime;

    uint256 private _releaseTime; // time when All tokens will be released

    /**
     * @dev Deploys a timelock instance that is able to hold the token specified, and will only release it to
     * `beneficiary_` when {release} is invoked after `releaseTime_`. The release time is specified as a Unix timestamp
     * (in seconds).
     */
    constructor(IBEP20 token_) {
        _token = token_;
    }

    modifier onlyTeamWallet() {
        require(
            teamWallet() == msg.sender,
            "Ownable: caller is not the team wallet"
        );
        _;
    }

    /**
     * @dev Returns the token being held.
     */
    function token() public view virtual returns (IBEP20) {
        return _token;
    }

    /**
     * @dev Returns the team wallet that will receive the tokens.
     */
    function teamWallet() public view virtual returns (address) {
        return _teamWallet;
    }

    /**
     * @dev Returns the time when the tokens are released in seconds since Unix epoch (i.e. Unix timestamp).
     */
    function releaseTime() public view virtual returns (uint256) {
        return _releaseTime;
    }

    function lock() public onlyTeamWallet {
        require(_token.balanceOf(address(this)) != 0, "No Tokens To Lock");
        nextReleaseTime = block.timestamp + Period;
        releaseAmount = token().balanceOf(address(this)) / 10;
        _releaseTime = block.timestamp + Period * 10;
    }

    /**
     * Will Release 10% Every Month for 10 Months
     */
    function release() public onlyTeamWallet {
        require(
            block.timestamp >= nextReleaseTime,
            "TokenTimelock: current time is before release time"
        );
        token().transfer(teamWallet(), releaseAmount);
        nextReleaseTime = nextReleaseTime + Period;
    }
}
