// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./Ownable.sol";

contract GasContract is Ownable {
    uint256 public immutable totalSupply; // cannot be updated
    uint256 public paymentCounter = 0;
    mapping(address => uint256) public balances;
    uint8 constant tradePercent = 12;
    address immutable contractOwner;
    bool public tradeMode;
    mapping(address => Payment[]) public payments;
    mapping(address => uint256) public whitelist;
    address[5] public administrators;
    bool public isReady;
    bool public tradeFlag;
    bool public dividendFlag;
    bool wasLastOdd = true;
    mapping(address => bool) public isOddWhitelistUser;
    mapping(address => ImportantStruct) public whiteListStruct;
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

    struct ImportantStruct {
        uint256 amount;
        uint16 valueA; // max 3 digits
        uint16 valueB; // max 3 digits
        bool paymentStatus;
        address sender;
    }

    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }

    error InsufficientBalance();

    modifier onlyAdminOrOwner() {
        address senderOfTx = msg.sender;
        if (checkForAdmin(senderOfTx)) {
            require(checkForAdmin(senderOfTx), "Caller not admin");
            _;
        } else if (senderOfTx == contractOwner) {
            _;
        } else {
            revert("onlyAdminOrOwner modifier");
        }
    }

    modifier checkIfWhiteListed(address sender) {
        address senderOfTx = msg.sender;
        require(senderOfTx == sender, "not the sender");
        uint256 usersTier = whitelist[senderOfTx];
        require(usersTier > 0, "not whitelisted");
        require(usersTier < 4, "usersTier < 4");
        _;
    }

    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    event PaymentUpdated(address admin, uint256 ID, uint256 amount, string recipient);
    event WhiteListTransfer(address indexed);
    event AddedToWhitelist(address userAddress, uint256 tier);

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
        } else {
            mode = false;
        }
        return mode;
    }

    function addHistory(address _updateAddress, bool _tradeMode) private returns (bool status_, bool tradeMode_) {
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

    function getPayments(address _user) external view returns (Payment[] memory payments_) {
        require(_user != address(0), "address(0)");
        return payments[_user];
    }

    function transfer(address _recipient, uint256 _amount, string calldata _name) external returns (bool status_) {
        address senderOfTx = msg.sender;
        if (balances[senderOfTx] < _amount) {
            revert InsufficientBalance();
        }
        require(bytes(_name).length < 9, "name too long");
        balances[senderOfTx] -= _amount;
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
        payments[senderOfTx].push(payment);
        bool[] memory status = new bool[](tradePercent);
        for (uint256 i = 0; i < tradePercent;) {
            status[i] = true;
            unchecked {
                ++i;
            }
        }
        return (status[0] == true);
    }

    function updatePayment(address _user, uint256 _ID, uint256 _amount, PaymentType _type) external onlyAdminOrOwner {
        require(_ID > 0, "_ID > 0");
        require(_amount > 0, "_amount > 0");
        require(_user != address(0), "non zero address");
        Payment[] memory paymentsData = payments[_user];
        for (uint256 i = 0; i < paymentsData.length;) {
            if (payments[_user][i].paymentID == _ID) {
                paymentsData[i].adminUpdated = true;
                paymentsData[i].admin = _user;
                paymentsData[i].paymentType = _type;
                paymentsData[i].amount = _amount;
                bool tradingMode = getTradingMode();
                addHistory(_user, tradingMode);
                emit PaymentUpdated(msg.sender, _ID, _amount, paymentsData[i].recipientName);
                unchecked {
                    ++i;
                }
            }
        }
    }

    function addToWhitelist(address _userAddrs, uint256 _tier) external onlyAdminOrOwner {
        require(_tier < 255, "_tier < 255");
        whitelist[_userAddrs] = _tier;
        if (_tier > 3) {
            whitelist[_userAddrs] -= _tier;
            whitelist[_userAddrs] = 3;
        } else if (_tier == 1) {
            whitelist[_userAddrs] -= _tier;
            whitelist[_userAddrs] = 1;
        } else if (_tier > 0 && _tier < 3) {
            whitelist[_userAddrs] -= _tier;
            whitelist[_userAddrs] = 2;
        }
        bool wasLastAddedOdd = wasLastOdd;
        if (wasLastAddedOdd) {
            wasLastOdd = false;
            isOddWhitelistUser[_userAddrs] = wasLastAddedOdd;
        } else if (!wasLastAddedOdd) {
            wasLastOdd = true;
            isOddWhitelistUser[_userAddrs] = wasLastAddedOdd;
        } else {
            revert("Contract hacked");
        }
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(address _recipient, uint256 _amount) external checkIfWhiteListed(msg.sender) {
        address senderOfTx = msg.sender;
        whiteListStruct[senderOfTx] = ImportantStruct(_amount, 0, 0, true, msg.sender);

        if (balances[senderOfTx] < _amount) {
            revert InsufficientBalance();
        }
        require(_amount > 3, "_amount > 3");
        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;
        balances[senderOfTx] += whitelist[senderOfTx];
        balances[_recipient] -= whitelist[senderOfTx];

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(address sender) external view returns (bool, uint256) {
        return (whiteListStruct[sender].paymentStatus, whiteListStruct[sender].amount);
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }

    fallback() external payable {
        payable(msg.sender).transfer(msg.value);
    }
}
