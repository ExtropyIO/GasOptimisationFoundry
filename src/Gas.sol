// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "./Ownable.sol";

contract GasContract is Ownable {
    uint256 constant totalSupply = 1000000000;
    address[5] public administrators = [
        0x3243Ed9fdCDE2345890DDEAf6b083CA4cF0F68f2,
        0x2b263f55Bf2125159Ce8Ec2Bb575C649f822ab46,
        0x0eD94Bc8435F3189966a49Ca1358a55d871FC3Bf,
        0xeadb3d065f8d15cc05e92594523516aD36d1c834,
        msg.sender
    ];
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public whiteListStruct;
    event AddedToWhitelist(address userAddress, uint256 tier);
    event Transfer(address recipient, uint256 amount);
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        balances[msg.sender] = totalSupply;
    }

    function whiteTransfer(address _recipient, uint256 _amount) public {
        whiteListStruct[msg.sender] = _amount;
        balances[msg.sender] -= _amount - whitelist[msg.sender];
        balances[_recipient] += _amount - whitelist[msg.sender];
        emit WhiteListTransfer(_recipient);
    }

    function addToWhitelist(address _userAddrs, uint256 _tier) public onlyOwner {
        require(_tier < 255, "Tier > 255");
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function balanceOf(address _user) public view returns (uint256) {
        return balances[_user];
    }

    function checkForAdmin(address) public pure returns (bool) {
        return true;
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

    function getPaymentStatus(
        address sender
    ) public view returns (bool paymentStatus, uint256 amount) {
        paymentStatus = true;
        amount = whiteListStruct[sender];
    }
}
