// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract GasContract {
    uint256 private totalSupply = 0; // cannot be updated
    uint256 private paymentCounter = 0;
    mapping(address => uint256) public balances;
    mapping(address => Payment[]) private payments;
    mapping(address => uint256) public whitelist;
    address[5] public administrators;
    mapping(address => bool) private administrator_map;
    
    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }
    
    History[] private paymentHistory; // when a payment was updated

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
    
    mapping(address => uint256) private whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);

    modifier onlyAdminOrOwner() {
        require(checkForAdmin(msg.sender),"");
        _;
    }

    modifier checkIfWhiteListed() {
        require(whitelist[msg.sender] > 0,"");
        _;
    }
    
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        totalSupply = _totalSupply;
        balances[msg.sender] = _totalSupply;
        for (uint8 i = 0; i < _admins.length; i++) {
            administrator_map[_admins[i]] = true;
            administrators[i] = _admins[i];
        }
    }

    function checkForAdmin(address _user) private view returns (bool admin_) {
        return administrator_map[_user];
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        return balances[_user]; // do we even need this function? 
    }

    function addHistory(address _updateAddress) private {
        paymentHistory.push(History(block.timestamp, _updateAddress, block.number));
    }

    function getPayments(address _user) public view returns (Payment[] memory payments_) {
        return payments[_user];
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public returns (bool status_) {
        require(balances[msg.sender] >= _amount,"");
        require(bytes(_name).length < 9,"");
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        Payment memory payment = Payment(PaymentType.BasicPayment, ++paymentCounter, false, _name, _recipient, address(0), _amount);
        payments[msg.sender].push(payment);
        return true;
    }

    function updatePayment(
        address _user,
        uint256 _ID,
        uint256 _amount,
        PaymentType _type
    ) public onlyAdminOrOwner {
        require(_ID > 0, "");
        require(_amount > 0, "");

        for (uint256 ii = 0; ii < payments[_user].length; ii++) {
            if (payments[_user][ii].paymentID == _ID) {
                payments[_user][ii].adminUpdated = true;
                payments[_user][ii].admin = _user;
                payments[_user][ii].paymentType = _type;
                payments[_user][ii].amount = _amount;
                addHistory(_user);
            }
        }
    }

    function addToWhitelist(address _userAddrs, uint256 _tier)
        public
        onlyAdminOrOwner
    {
        require(_tier < 255,"");
        whitelist[_userAddrs] = _tier > 3 ? 3 : _tier;
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) public checkIfWhiteListed {
        whiteListStruct[msg.sender] = _amount;
        require(balances[msg.sender] >= _amount, "");
        require(_amount > 3, "");
        balances[msg.sender] -= _amount - whitelist[msg.sender];
        balances[_recipient] += _amount - whitelist[msg.sender];
        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(address sender) public view returns (bool, uint256) {        
        return (true, whiteListStruct[sender]);
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }

    fallback() external payable {
         payable(msg.sender).transfer(msg.value);
    }
}