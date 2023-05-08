pragma solidity 0.8.19;


contract GasContract {
    uint256 totalSupply; // cannot be updated
    uint256  paymentCounter;
    mapping(address => uint256) public balances;
    address  contractOwner;
   // mapping(address => Payment[]) public payments;
    mapping(address => uint256) public whitelist;
    address[5] public administrators;
    bool  isReady ;
/** 
    enum PaymentType {
        Unknown,
        BasicPayment
    }
    
*/
   // History[] paymentHistory; // when a payment was updated

    struct ImportantStruct {
        uint256 amount;
        bool paymentStatus;
    }

    struct Payment {
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
    


    
    mapping(address => ImportantStruct) public whiteListStruct;

    error SthWrong();

    event AddedToWhitelist(address userAddress, uint256 tier);



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

        unchecked {
            
        for (uint256 ii = 0; ii < 5; ++ii) {
            if (_admins[ii] != address(0)) {
                administrators[ii] = _admins[ii];
                if (_admins[ii] == contractOwner) {
                    balances[contractOwner] = totalSupply;
                    emit supplyChanged(_admins[ii], totalSupply);
                } else {
                    balances[_admins[ii]];
                    emit supplyChanged(_admins[ii], 0);
                }
            }
        }
        }
    }

    function onlyAdminOrOwner(address sndr) internal {
            if (contractOwner != sndr || !checkForAdmin(sndr)) {
                revert SthWrong();
            }
            
        
    }

/** 
    function getPaymentHistory()
        external
        payable
        returns (History[] memory paymentHistory_)
    {
        return paymentHistory;
    }

*/

    function checkForAdmin(address _user) internal view returns (bool admin_) {
        unchecked {
        for (uint256 ii = 0; ii < 5; ++ii) {
            if (administrators[ii] == _user) {
                return true;
            }
        }
        }
        return false;
    }

    function balanceOf(address _user) external view returns (uint256 balance_) {
        return balances[_user];
        
    }



/**
    function getPayments(address _user)
        internal
        view
        returns (Payment[] memory payments_)
    {
        return payments[_user];
    }
*/
    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) external payable returns (bool status_) {

        if(bytes(_name).length > 8){
            revert SthWrong();
        }
     
        balances[msg.sender] -= _amount;
        unchecked {
        balances[_recipient] += _amount;
        }
        emit Transfer(_recipient, _amount);
        return (true);
    }
/** 
    function updatePayment(
        address _user,
        uint256 _ID,
        uint256 _amount,
        PaymentType _type
    ) external payable {


        onlyAdminOrOwner(msg.sender);
        if (_ID < 0 || _amount < 0 || _user == address(0)){
            revert SthWrong();
        }

        unchecked {
            
        for (uint256 ii = 0; ii < payments[_user].length; ++ii) {
            if (payments[_user][ii].paymentID == _ID) {
                payments[_user][ii].adminUpdated = true;
                payments[_user][ii].admin = _user;
                payments[_user][ii].paymentType = _type;
                payments[_user][ii].amount = _amount;
                emit PaymentUpdated(
                    msg.sender,
                    _ID,
                    _amount,
                    payments[_user][ii].recipientName
                );
            }
        }
        }
    }
*/

    function addToWhitelist(address _userAddrs, uint256 _tier)
        external
        payable
    
    {
        onlyAdminOrOwner(msg.sender);
        if (_tier > 255){
            revert SthWrong();
        }
        whitelist[_userAddrs] = _tier;
        if (_tier > 3) {
            whitelist[_userAddrs] = 3;
        } else {
            whitelist[_userAddrs] = _tier;
        }
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) external payable {
 
        whiteListStruct[msg.sender] = ImportantStruct(_amount, true);
        if(_amount < 3 ){
            revert SthWrong();
        }
        if (_amount > balances[msg.sender]){
            revert SthWrong();
        }

        balances[msg.sender] -= _amount;
        unchecked { 
        balances[_recipient] += _amount;
        balances[msg.sender] += whitelist[msg.sender];
        }
        balances[_recipient] -= whitelist[msg.sender];
        
        emit WhiteListTransfer(_recipient);
    }


    function getPaymentStatus(address sender) external view returns (bool, uint256) {        
        return (whiteListStruct[sender].paymentStatus, whiteListStruct[sender].amount);
    }

    fallback() external payable {
         payable(msg.sender).transfer(msg.value);
    }
}