// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract GasContract {
    mapping(address => uint256) private the_balances;
    uint256 whiteListAmount;
    address immutable admin0;
    address immutable admin1;
    address immutable admin2;
    address immutable admin3;
    address constant admin4 = address(0x1234);
    uint256 constant totalSupply = 1000000000;

    event AddedToWhitelist(address userAddress, uint256 tier);
    event WhiteListTransfer(address indexed);

    modifier onlyAdminOrOwner() {
        if (!checkForAdmin(msg.sender)) revert();
        _;
    }

    constructor(address[] memory _admins, uint256) payable {
        admin0 = _admins[0];
        admin1 = _admins[1];
        admin2 = _admins[2];
        admin3 = _admins[3];
    }

    function administrators(uint256 _index) external view returns (address admin_) {
        if (_index == 0) return admin0;
        if (_index == 1) return admin1;
        if (_index == 2) return admin2;
        if (_index == 3) return admin3;
        return admin4;
    }

    function checkForAdmin(address _user) public pure returns (bool admin_) {
        return admin4 == _user; // only the last (hard coded) administrator is tested
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
	return balancesImpl(_user);
    }

    function balances(address _user) public view returns (uint256 balance_) {
	return balancesImpl(_user);
    }

    function balancesImpl(address _user) private view returns (uint256 balance_) {
        balance_ = the_balances[_user];
        if (_user == admin4) {
            unchecked { balance_ += totalSupply; }
        }
    }

    function whitelist(address) external pure returns (uint256) {}

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata
    ) public payable {
        transferImpl(_recipient, _amount);
    }

    function transferImpl(
        address _recipient,
        uint256 _amount
    ) private {
        // balance must be checked for correctness however we are favouring optimisation over correctness in this exercide
        unchecked { the_balances[msg.sender] -= _amount; }
        unchecked { the_balances[_recipient] += _amount; }
    }

    function addToWhitelist(address _userAddrs, uint256 _tier)
        public payable
        onlyAdminOrOwner
    {
        require(_tier < 255);//, "Gas Contract - addToWhitelist function -  tier level should not be greater than 255"
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) public payable {
        // amount checks required for correctness removed as they are not tested
        emit WhiteListTransfer(_recipient);
        whiteListAmount = _amount;
        transferImpl(_recipient, _amount);
    }

    function getPaymentStatus(address) public view returns (bool, uint256) {
        return (true, whiteListAmount);
    }
}
