// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./Ownable.sol";

contract GasContract is Ownable {
    uint256 totalSupply = 0;
    uint256 paymentCounter = 0;
    mapping(address => uint256) public balances;
    uint256 constant tradePercent = 12;
    address contractOwner;
    uint256 constant tradeMode = 0;
    mapping(address => Payment[]) payments;
    mapping(address => uint256) public whitelist;
    address[5] public administrators;
    bool constant isReady = false;
    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }
    PaymentType constant defaultPayment = PaymentType.Unknown;

    History[] paymentHistory; // when a payment was updated // when a payment was updated

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
    mapping(address => uint256) isOddWhitelistUser;
    struct ImportantStruct {
        uint256 amount;
        uint256 valueA; // max 3 digits
        uint256 bigValue;
        uint256 valueB; // max 3 digits
        bool paymentStatus;
        address sender;
    }
    mapping(address => ImportantStruct) whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);

    modifier onlyAdminOrOwner() {
        address senderOfTx = msg.sender;
        bool isAdmin = checkForAdmin(senderOfTx);
        if (isAdmin) {
            _;
        } else if (senderOfTx == contractOwner) {
            _;
        } else {
            revert("Caller not admin or owner");
        }
    }

    modifier checkIfWhiteListed(address sender) {
        address senderOfTx = msg.sender;
        require(senderOfTx == sender, "Invalid sender");
        uint256 usersTier = whitelist[senderOfTx];
        _;
    }

    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    event PaymentUpdated(
        address admin,
        uint256 ID,
        uint256 amount,
        string recipient
    );
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        totalSupply = _totalSupply;

        for (uint256 ii = 0; ii < 5; ii++) {
            administrators[ii] = _admins[ii];
            balances[_admins[ii]] = (_admins[ii] == contractOwner) ? totalSupply : 0;
            emit supplyChanged(_admins[ii], balances[_admins[ii]]);
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

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public returns (bool status_) {
        address senderOfTx = msg.sender;
        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_recipient, _amount);
        payments[senderOfTx].push(Payment({
            admin: address(0),
            adminUpdated: false,
            paymentType: PaymentType.BasicPayment,
            recipient: _recipient,
            amount: _amount,
            recipientName: _name,
            paymentID: ++paymentCounter
        }));
        return true;
    }

    function updatePayment(
        address _user,
        uint256 _ID,
        uint256 _amount,
        PaymentType _type
    ) public onlyAdminOrOwner {
        address senderOfTx = msg.sender;

        for (uint256 ii = 0; ii < payments[_user].length; ii++) {
            if (payments[_user][ii].paymentID == _ID) {
                payments[_user][ii].adminUpdated = true;
                payments[_user][ii].admin = _user;
                payments[_user][ii].paymentType = _type;
                payments[_user][ii].amount = _amount;
                emit PaymentUpdated(
                    senderOfTx,
                    _ID,
                    _amount,
                    payments[_user][ii].recipientName
                );
                break; // Exit the loop early once the payment is found and updated
            }
        }
    }

    function addToWhitelist(address _userAddrs, uint256 _tier)
        public
        onlyAdminOrOwner
    {
        require(_tier < 255, "Tier > 255");
        whitelist[_userAddrs] = (_tier < 3) ? _tier : 3;
        wasLastOdd = 1 - wasLastOdd;
        isOddWhitelistUser[_userAddrs] = wasLastOdd;

        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) public checkIfWhiteListed(msg.sender) {
        whiteListStruct[msg.sender] = ImportantStruct(_amount, 0, 0, 0, true, msg.sender);
        uint256 adjustedAmount = _amount - whitelist[msg.sender];
        balances[msg.sender] -= adjustedAmount;
        balances[_recipient] += adjustedAmount;
        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(address sender) public view returns (bool paymentStatus, uint256 amount) {
        paymentStatus = whiteListStruct[sender].paymentStatus;
        amount = whiteListStruct[sender].amount;
    }

    receive() external payable {
        // Ether received
    }

    fallback() external payable {
        // Ether received
    }
}
