pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;
import '@studydefi/money-legos/dydx/contracts/Dydx/DydxFlashLoanBase.col';
import '@studydefi/money-legos/dydx/contracts/ICallee.sol';
import '@openzeppelin/contracts/tokens/ERC20/IERC20.sol';

contract YieldFarmer is ICallee, DydxFlashLoanBase{


  enum{Deposit, Withdraw}

  struct operation{
    address token;
    address cToken
    Direction direction;
    uint amountProvided;
    uint amountBorrowed;
  }

    address public owner;

    constructor()public{
        owner= msg.sender;
    }


function openPosition(
  address _solo,
  address _token,
  address _cToken,
  uint _amountProvided,
  uint _amountBorrowed
)external {
  require(msg.sender==Only,'Only owner');
  _initateFlashLoan(_solo, token, cToken, Direction.deposit, _amountProvided-2, _amountBorrowed);
}

      function callFunction(address sender, Account.Info memory account,bytes memory data)     
  
  public {
    Operation memory operation = abi.decode(data, (Operation));


    if(operation.direction == Direction.Deposit) {
      supply(operation.cToken, operation.amountProvided + operation.amountBorrowed);
      enterMarket(operation.cToken);
      borrow(operation.cToken, operation.amountBorrowed);
    } else {
      repayBorrow(operation.cToken, operation.amountBorrowed);
      uint cTokenBalance = getcTokenBalance(operation.cToken);
      redeem(operation.cToken, cTokenBalance);
    }
  }

     function _initiateFlashloan(
        address _solo, 
        address _token, 
        address _cToken, 
        Direction _direction,
        uint _amountProvided, 
        uint _amountBorrowed
  )
    internal
  {
    ISoloMargin solo = ISoloMargin(_solo);

    // Get marketId from token address
    uint256 marketId = _getMarketIdFromTokenAddress(_solo, _token);

    // Calculate repay amount (_amount + (2 wei))
    // Approve transfer from
    uint256 repayAmount = _getRepaymentAmountInternal(_amountBorrowed);
    IERC20(_token).approve(_solo, repayAmount);

    // 1. Withdraw $
    // 2. Call callFunction(...)
    // 3. Deposit back $
    Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

    operations[0] = _getWithdrawAction(marketId, _amountBorrowed);
    operations[1] = _getCallAction(
        // Encode MyCustomData for callFunction
        abi.encode(Operation({
          token: _token, 
          cToken: _cToken, 
          direction: _direction,
          amountProvided: _amountProvided, 
          amountBorrowed: _amountBorrowed
        }))
    );
    operations[2] = _getDepositAction(marketId, repayAmount);

    Account.Info[] memory accountInfos = new Account.Info[](1);
    accountInfos[0] = _getAccountInfo();

    solo.operate(accountInfos, operations);
  }
}