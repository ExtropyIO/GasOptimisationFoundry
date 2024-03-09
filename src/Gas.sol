// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "./Ownable.sol";

contract GasContract is Ownable {
    uint256 totalSupply;
    mapping(address => uint256) public balances;
    address contractOwner;
    mapping(address => uint256) public whitelist;
    address[5] public administrators;

    mapping(address => uint256) isOddWhitelistUser;
    struct ImportantStruct {
        uint256 amount;
        address sender;
    }
    mapping(address => ImportantStruct) whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);

    modifier onlyAdminOrOwner() {
        address senderOfTx = msg.sender;
        if (senderOfTx == contractOwner) {
            _;
        } else {
            revert("Caller not admin or owner");
        }
    }

    event Transfer(address recipient, uint256 amount);
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        totalSupply = _totalSupply;

        for (uint256 ii = 0; ii < 5; ii++) {
            administrators[ii] = _admins[ii];
            balances[_admins[ii]] = (_admins[ii] == contractOwner)
                ? totalSupply
                : 0;
        }
    }

    function addToWhitelist(
        address _userAddrs,
        uint256 _tier
    ) public onlyAdminOrOwner {
        require(_tier < 255, "Tier > 255");
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function balanceOf(address _user) public view returns (uint256) {
        return balances[_user];
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

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public {
        address senderOfTx = msg.sender;
        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_recipient, _amount);
    }

    function whiteTransfer(address _recipient, uint256 _amount) public {
        whiteListStruct[msg.sender] = ImportantStruct(_amount, msg.sender);
        uint256 adjustedAmount = _amount - whitelist[msg.sender];
        balances[msg.sender] -= adjustedAmount;
        balances[_recipient] += adjustedAmount;
        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(
        address sender
    ) public view returns (bool paymentStatus, uint256 amount) {
        paymentStatus = true;
        amount = whiteListStruct[sender].amount;
    }
}
