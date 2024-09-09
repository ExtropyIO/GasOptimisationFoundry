// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract GasContract is Ownable {
    uint256 public immutable totalSupply; // cannot be updated
    address public immutable contractOwner;

    uint private constant _administratorsLength = 5;
    address[_administratorsLength] public administrators;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    mapping(address => uint) public whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);
    event WhiteListTransfer(address indexed);

    modifier onlyAdminOrOwner() {
        require(msg.sender == contractOwner);
        _;
    }

    constructor(address[] memory _admins, uint256 _totalSupply) {
        unchecked {
            contractOwner = msg.sender;
            balances[msg.sender] = _totalSupply;
            totalSupply = _totalSupply;

            for (uint256 i = 0; i < _administratorsLength; i++) {
                administrators[i] = _admins[i];
            }
        }
    }

    function checkForAdmin(address _user) public view returns (bool admin_) {
        unchecked {
            bool admin = false;
            for (uint256 i = 0; i < _administratorsLength; i++) {
                if (administrators[i] == _user) {
                    admin = true;
                }
            }
            return admin;
        }
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        unchecked {
            return balances[_user];
        }
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata /*_name*/
    ) public returns (bool status_) {
        unchecked {
            balances[msg.sender] -= _amount;
            balances[_recipient] += _amount;
            return true;
        }
    }

    function addToWhitelist(address _userAddress, uint256 _tier)
        public
        onlyAdminOrOwner
    {
        unchecked {
            require(_tier < 255);
            whitelist[_userAddress] = _tier > 3 ? 3 : _tier;
            emit AddedToWhitelist(_userAddress, _tier);
        }
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) public {
        unchecked {
            whiteListStruct[msg.sender] = _amount;

            require(balances[msg.sender] >= _amount);
            uint whitelistAmount = whitelist[msg.sender];
            balances[msg.sender] = balances[msg.sender] - _amount + whitelistAmount;
            balances[_recipient] = balances[_recipient] + _amount - whitelistAmount;

            emit WhiteListTransfer(_recipient);
        }
    }

    function getPaymentStatus(address sender) public view returns (bool, uint256) {
        unchecked {
            return (true, whiteListStruct[sender]);
        }
    }

}
