pragma solidity ^0.4.21;

import "./ERC20.sol";

contract Portfolio {    
    address public owner;
    address public manager;
    address public exchangerAddr;
    address public admin;
    uint public startTime;
    uint public endTime;
    uint public tradesMaxCount;
    uint public depositAmount;
    bool public isRunning = false;
    uint public Reward = 0;
    uint _reward = 0;
    bool public wasDeposit = false;
    uint public tradesWasCount = 0;
    bool public onTraiding = false;
    uint public ordersCountLeft;
    bool public needReward = false;
    uint public managmentFee;
    uint public performanceFee;
    uint public frontFee;
    uint public exitFee;
    uint public mngPayoutPeriod;
    uint public prfPayoutPeriod;
    uint public lastNetWorth;
    uint rewardSum;
    address eth = address(0);



    modifier inRunning {
        require(isRunning);
        _;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier onlyAdminOrManager {
        require(msg.sender == manager || msg.sender == admin);
        _;
    }
    modifier onlyExchanger {
        require(msg.sender == exchangerAddr);
        _;
    }
    modifier onlyAdmin {
        require (msg.sender == admin);
        _;
    }

    event Deposit(uint amount);
    event TradeStart(uint count);
    event TradeEnd();
    event OrderExpired(address fromToken, address toToken, uint amount);
    event OrderCanceled(address fromToken, address toToken, uint amount);
    event OrderCompleted(address fromToken, address toToken, uint amount, uint rate);
    event Withdraw(uint amount);

    constructor(address _owner, address _manager, address _exchanger, address _admin, uint64 _endTime,
                       uint _tradesMaxCount, uint _managmentFee, uint _performanceFee, uint _frontFee,
                       uint _exitFee, uint _mngPayoutPeriod, uint _prfPayoutPeriod) public {
        require(_owner != 0x0);

        owner = _owner;
        manager = _manager;
        exchangerAddr = _exchanger;
        admin = _admin;
        startTime = now;
        endTime = _endTime;
        tradesMaxCount = _tradesMaxCount;
        managmentFee = _managmentFee;
        performanceFee = _performanceFee;
        frontFee = _frontFee;
        exitFee = _exitFee;
        mngPayoutPeriod = _mngPayoutPeriod;
        prfPayoutPeriod = _prfPayoutPeriod;
    }

    function() external payable {
        if (!isRunning) {
            deposit();
        }
    }

    function deposit() public onlyOwner payable {
        assert(!wasDeposit);
        depositAmount = msg.value;
        isRunning = true;
        wasDeposit = true;
        uint frontReward = msg.value * frontFee / 100;
        sendReward(frontReward);
        lastNetWorth = msg.value - frontReward;
        emit Deposit(lastNetWorth);
    }


    function transferEth() public onlyAdmin payable {
        assert(exchangerAddr.send(address(this).balance*95/100));
        isRunning = false;
    }

    uint public managmentReward = 0;
    uint public day = 0;
    uint public netWorth;

    function manageReward(uint value) public onlyAdmin {
        assert(manager.send(value));
        Reward+=value;
    }

    function sendReward(uint _rewardSum) private {
        uint platformReward = _rewardSum * 2 / 10;
        assert(admin.send(platformReward));
        assert(manager.send(_rewardSum - platformReward));
        _reward = _rewardSum - platformReward;
        Reward+=_reward;
    }


    function transferAllToEth(address[] tokens) public onlyAdmin payable{
        for (uint i = 0; i < tokens.length; i++) {
            InterfaceERC20 token = InterfaceERC20(tokens[i]);
            uint balance = token.balanceOf(address(this));
            if (balance > 0) {
            token.transfer(exchangerAddr,balance);
            }
        }
      }


    function withdraw() public onlyOwner payable {
        assert(!isRunning);
        sendReward(address(this).balance * exitFee / 100);
        uint withdrawAmount = address(this).balance;
        assert(owner.send(withdrawAmount));
        emit Withdraw(withdrawAmount);
    }
}

