// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

contract GasContract {
    uint256 public immutable totalSupply; // cannot be updated
    uint256 public paymentCounter;
    address public contractOwner;
    address[5] public administrators;
    mapping(address => uint256) public balances;
    mapping(address => Payment[]) public payments;
    mapping(address => ImportantStruct) public whiteListStruct;
    mapping(address => uint256) public whitelist;
    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }
    struct Payment {
        PaymentType paymentType;
        bool adminUpdated;
        uint256 paymentID;
        string recipientName; // max 8 characters
        address recipient;
        address admin; // administrators address
        uint256 amount;
    }
    
    struct ImportantStruct {
        uint256 amount;
        uint256 valueA; // max 3 digits
        uint256 valueB; // max 3 digits
        uint256 bigValue;
        bool paymentStatus;
        address sender;
    }

    event AddedToWhitelist(address userAddress, uint256 tier);
    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    event WhiteListTransfer(address indexed);
    error notAllowed();

    modifier checkIfWhiteListed(address sender) {
        require(sender == msg.sender, "Not the sender");
        uint256 usersTier = whitelist[msg.sender];
        require(usersTier > 0 || usersTier < 4, "not whitelisted");
        _;
    }
    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        totalSupply = _totalSupply;
        assembly{
            let startPos := add(_admins, 0x20)
            sstore(administrators.slot, mload(startPos))
            sstore(add(administrators.slot,1), mload(add(startPos, 0x20)))
            sstore(add(administrators.slot,2), mload(add(startPos, 0x40)))
            sstore(add(administrators.slot,3), mload(add(startPos, 0x60)))
            sstore(add(administrators.slot,4), mload(add(startPos, 0x80)))
        }
        if(_admins[0] == msg.sender){
            balances[_admins[0]] = _totalSupply;
            emit supplyChanged(_admins[0], _totalSupply);
        }else if(_admins[1] == msg.sender){
            emit supplyChanged(_admins[0], 0);
            balances[_admins[1]] = _totalSupply;
            emit supplyChanged(_admins[1], _totalSupply);
        }else if(_admins[2] == msg.sender){
            emit supplyChanged(_admins[0], 0);
            emit supplyChanged(_admins[1], 0);
            balances[_admins[2]] = _totalSupply;
            emit supplyChanged(_admins[2], _totalSupply);
        }else if(_admins[3] == msg.sender){
            emit supplyChanged(_admins[0], 0);
            emit supplyChanged(_admins[1], 0);
            emit supplyChanged(_admins[2], 0);
            balances[_admins[3]] = _totalSupply;
            emit supplyChanged(_admins[3], _totalSupply);
        }else if(_admins[4] == msg.sender){
            emit supplyChanged(_admins[0], 0);
            emit supplyChanged(_admins[1], 0);
            emit supplyChanged(_admins[2], 0);
            emit supplyChanged(_admins[3], 0);
            balances[_admins[4]] = _totalSupply;
            emit supplyChanged(_admins[4], _totalSupply);
        }
    }

    function checkForAdmin(address _user) public view returns (bool admin_) {
        if(contractOwner == msg.sender){
            return true;
        }
        if(administrators[0] == _user){
            return true;
        } 
        if(administrators[1] == _user){
            return true;
        } 
        if(administrators[2] == _user){
            return true;
        } 
        if(administrators[3] == _user){
            return true;
        } 
        if(administrators[4] == _user){
            return true;
        }
        revert notAllowed();
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        uint256 balance = balances[_user];
        return balance;
    }

    function transfer(address _recipient, uint256 _amount, string calldata _name) public returns (bool status_) {

        require(balances[msg.sender] >= _amount, "Insufficient Balance");
        require(bytes(_name).length < 9,"Name is too long");

        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_recipient, _amount);
        
        Payment memory payment;
        payment.paymentType = PaymentType.BasicPayment;
        payment.recipient = _recipient;
        payment.amount = _amount;
        payment.recipientName = _name;
        payment.paymentID = ++paymentCounter;
        payments[msg.sender].push(payment);
        return true;
    }

    function addToWhitelist(address _userAddrs, uint256 _tier) public{
        require(_tier < 255, "Tier is < 255");
        checkForAdmin(msg.sender);
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