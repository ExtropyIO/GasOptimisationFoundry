// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

contract GasContract {
    uint256 public immutable totalSupply; // cannot be updated
    uint256 public paymentCounter = 0;
    mapping(address => uint256) public balances;
    
    
    uint256 public tradePercent = 12;
    address public contractOwner;
    uint256 public tradeMode = 0;
    mapping(address => Payment[]) public payments;
    mapping(address => uint256) public whitelist;
    
    bool public isReady = false;

    
    bool public tradeFlag;
    bool public dividendFlag;

    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }
    PaymentType constant defaultPayment = PaymentType.Unknown;

    History[] public paymentHistory; // when a payment was updated

    struct Payment {
        PaymentType paymentType;
        uint256 paymentID;
        bool adminUpdated;
        string recipientName; // max 8 characters
        address recipient;
        address admin; // administrators address
        uint256 amount;
    }

    struct History {
        uint256 lastUpdate;
        address updatedBy;
        uint256 blockNumber;
    }
    
    uint256 wasLastOdd = 1;
    mapping(address => uint256) public isOddWhitelistUser;
    
    struct ImportantStruct {
        uint256 amount;
        uint256 valueA; // max 3 digits
        uint256 bigValue;
        uint256 valueB; // max 3 digits
        bool paymentStatus;
        address sender;
    }
    mapping(address => ImportantStruct) public whiteListStruct;

    address[5] public administrators;

    event AddedToWhitelist(address userAddress, uint256 tier);

    error notAllowed();
    modifier onlyAdminOrOwner() {
        address senderOfTx = msg.sender;
        if (checkForAdmin(msg.sender) || contractOwner == msg.sender) {
            _;
        } else {
            revert notAllowed();
        }
    }

    modifier checkIfWhiteListed(address sender) {
        
        require( sender == msg.sender, "Not the sender");
        
        uint256 usersTier = whitelist[msg.sender];
        require(usersTier > 0 || usersTier < 4, "not whitelisted");
        _;
    }

    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    event PaymentUpdated(address admin, uint256 ID, uint256 amount, string recipient);
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        totalSupply = _totalSupply;

        for (uint256 ii = 0; ii < administrators.length; ii++) {
            if (_admins[ii] != address(0)) {
                administrators[ii] = _admins[ii];
                if (_admins[ii] == contractOwner) {
                    balances[contractOwner] = totalSupply;
                } else {
                    balances[_admins[ii]] = 0;
                }
                if (_admins[ii] == contractOwner) {
                    emit supplyChanged(_admins[ii], totalSupply);
                } else if (_admins[ii] != contractOwner) {
                    emit supplyChanged(_admins[ii], 0);
                }
            }
        }
    }

    function getPaymentHistory() public payable returns (History[] memory paymentHistory_){
        return paymentHistory;
    }

    function checkForAdmin(address _user) public view returns (bool admin_) {
        bool admin = false;
        for (uint256 ii = 0; ii < administrators.length; ii++) {
            if (administrators[ii] == _user) {
                admin = true;
            }
        }
        return admin;
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        uint256 balance = balances[_user];
        return balance;
    }

    function getTradingMode() public view returns (bool mode_) {
        bool mode = false;
        if (tradeFlag || dividendFlag) {
            mode = true;
        } 
        return mode;
    }


    function addHistory(address _updateAddress, bool _tradeMode) public returns (bool status_, bool tradeMode_){
        History memory history;
        history.blockNumber = block.number;
        history.lastUpdate = block.timestamp;
        history.updatedBy = _updateAddress;
        paymentHistory.push(history);
        bool[] memory status = new bool[](tradePercent);
        for (uint256 i = 0; i < tradePercent; i++) {
            status[i] = true;
        }
        return ((status[0] == true), _tradeMode);
    }

    function getPayments(address _user) public view returns (Payment[] memory payments_){
        require(_user != address(0), "Address is a zero address");
        return payments[_user];
    }

    function transfer(address _recipient, uint256 _amount, string calldata _name) public returns (bool status_) {

        require(balances[msg.sender] >= _amount, "Insufficient Balance");
        require(bytes(_name).length < 9,"Name is too long");

        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_recipient, _amount);
        
        Payment memory payment;
        payment.admin = address(0);
        payment.adminUpdated = false;
        payment.paymentType = PaymentType.BasicPayment;
        payment.recipient = _recipient;
        payment.amount = _amount;
        payment.recipientName = _name;
        payment.paymentID = ++paymentCounter;
        payments[msg.sender].push(payment);
        bool[] memory status = new bool[](tradePercent);
        for (uint256 i = 0; i < tradePercent; i++) {
            status[i] = true;
        }
        return (status[0] == true);
    }

    function updatePayment(address _user, uint256 _ID, uint256 _amount, PaymentType _type) public onlyAdminOrOwner {
        require(_ID > 0 && _amount > 0 && _user != address(0), "ID < 0 or amount < 0 or user == 0");

        for (uint256 ii = 0; ii < payments[_user].length; ii++) {
            if (payments[_user][ii].paymentID == _ID) {
                payments[_user][ii].adminUpdated = true;
                payments[_user][ii].admin = _user;
                payments[_user][ii].paymentType = _type;
                payments[_user][ii].amount = _amount;
                bool tradingMode = getTradingMode();
                addHistory(_user, tradingMode);
                emit PaymentUpdated(msg.sender, _ID, _amount, payments[_user][ii].recipientName);
            }
        }
    }

    function addToWhitelist(address _userAddrs, uint256 _tier) public onlyAdminOrOwner{
        require(_tier < 255, "Tier is < 255");
        whitelist[_userAddrs] = (_tier == 1) ? 1 : (_tier == 2) ? 2 : (_tier > 3) ? 3 : _tier;
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(address _recipient, uint256 _amount) public checkIfWhiteListed(msg.sender) {
                
        require(balances[msg.sender] >= _amount &&  _amount > 3,"Insufficient Balance or amount < 3");
        
        whiteListStruct[msg.sender] = ImportantStruct(_amount, 0, 0, 0, true, msg.sender);
        
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        balances[msg.sender] += whitelist[msg.sender];
        balances[_recipient] -= whitelist[msg.sender];
        
        emit WhiteListTransfer(_recipient);
    }

     
    function getPaymentStatus(address sender) public view returns (bool, uint256) {        
        return (whiteListStruct[sender].paymentStatus, whiteListStruct[sender].amount);
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }

}