pragma solidity 0.8.11;
// SPDX-License-Identifier: MIT
interface IBEP20 {

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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Duskycoin Presale
 */
contract Dusky_Presale {
  address public owner;
  mapping(address => uint256) private _purchasedTokens;
  // The token being sold
  IBEP20 public token;
  uint256 public totalSold;
  // Address where funds are collected
  address public wallet;

  bool public PresaleStatus = true;
  // How many token units a buyer gets per wei
  uint256 private rate; 
  // Amount of wei raised
  uint256 public weiRaised;

  uint256 public Min = 0.05 ether; // 0.05 BNB
  uint256 public Max = 5 ether; // 5 BNB
  uint256 private Period = 18 days;
  uint256 public Stage1 = 1644523200; // 10 Feb 22
  uint256 public Stage2 = Stage1 + Period;
  uint256 public Stage3 = Stage2 + Period;
  uint256 public Stage4 = Stage3 + Period;
  uint256 public Stage5 = Stage4 + Period;
  uint256 public endTime = Stage5 + Period; // 11 May 22 (22:00 UTC) You can Claim After

  uint256 private Stage1_Rate = 4e28;
  uint256 private Stage2_Rate = 35e27;
  uint256 private Stage3_Rate = 3e28;
  uint256 private Stage4_Rate = 25e27;
  uint256 private Stage5_Rate = 2e28;

  address public Dead = 0x000000000000000000000000000000000000dEaD;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  /**
   * Event for token claim logging
   * @param purchaser claim the tokens
   * @param amount amount of tokens claimed
   */

  event TokenClaimed(
    address indexed purchaser,
    uint256 amount
  );

  /**
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor(address _wallet, IBEP20 _token)  {
    wallet = _wallet;
    owner = msg.sender;
    token = _token;
  }
  /**
   * @dev Throws if called by any account other than the owner.
  */
    modifier onlyOwner {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }



    function getRate() private returns (uint256) {

        if (block.timestamp >= Stage1 && block.timestamp <= Stage2){
            rate = Stage1_Rate;
        }else if (block.timestamp >= Stage2 && block.timestamp <= Stage3){
            rate = Stage2_Rate;
        }else if (block.timestamp >= Stage3 && block.timestamp <= Stage4){
            rate = Stage3_Rate;
        }else if (block.timestamp >= Stage4 && block.timestamp <= Stage5){
            rate = Stage4_Rate;
        }else if (block.timestamp >= Stage5 && block.timestamp <= endTime){
            rate = Stage5_Rate;
        }else{
          revert("Dusky_Presale: Presale Time is Over");
        }

         return rate;

    }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
    
 fallback () external payable {
  }
 receive () external payable {
    buyTokens();
  }

  function buyTokens() public payable {
    require(PresaleStatus == true , "Dusky_Presale: Presale Stopped !");
    address _beneficiary = msg.sender;
    uint256 weiAmount = msg.value;
    require(weiAmount >= Min , "Dusky_Presale: Amount is Lower Than The Minimum Amount To Buy");
    require(weiAmount <= Max , "Dusky_Presale: Amount is Higher Than The Maximum Amount To Buy");
    uint256 tokens = 0;
    tokens = weiAmount * getRate() / 1 ether;
    weiRaised += weiAmount;
    _purchasedTokens[_beneficiary] += tokens;
    totalSold += tokens;
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );
    
    _forwardFunds();  }
 
   function FinalizePresale() public onlyOwner {
     require(PresaleStatus = true , "Dusky_Presale: Presale is unactive");
       uint256 balance = token.balanceOf(address(this));
       uint256 forOwner = balance * 2 / 100 ;
       uint256 forBurn = balance - forOwner;
       token.transfer(owner, forOwner);
       token.transfer(Dead, forBurn);
       PresaleStatus = false;
   }
   
   function SetPresaleStatus(bool _enabled) public onlyOwner {
       PresaleStatus = _enabled;
   }
   
   function SetRates(uint256 _sRate1,uint256 _sRate2,uint256 _sRate3,uint256 _sRate4,uint256 _sRate5) public onlyOwner {
       Stage1_Rate = _sRate1;
       Stage2_Rate = _sRate2;
       Stage3_Rate = _sRate3;
       Stage4_Rate = _sRate4;
       Stage5_Rate = _sRate5;
   }
   
   function SetMinMax(uint256 _Min , uint256 _Max) public onlyOwner {
       Min = _Min;
       Max = _Max;
   }

    // available tokens to claim after presale
   function PurchasedTokens(address _Buyer) public view returns (uint256) {
       return _purchasedTokens[_Buyer];
   }

   function claim() public {
       require(block.timestamp >= endTime , "Please Wait For Presale To Finish");
       address account = msg.sender;
       uint256 tokens = _purchasedTokens[account];
       require(tokens != 0 , "No Tokens To Claim");
       _purchasedTokens[account] = 0;
       token.transfer(account, tokens);
       emit TokenClaimed(account , tokens);
   } 


  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount * rate;
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    payable(wallet).transfer(msg.value);
  }
}