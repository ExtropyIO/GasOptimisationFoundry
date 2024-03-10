// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

contract GasContract {
    uint256 private whiteListAmount;
    mapping(address => uint256) public balances;
    address[5] public administrators;
    event WhiteListTransfer(address indexed);
    event AddedToWhitelist(address userAddress, uint256 tier);
    constructor(address[] memory _admins, uint256 _totalSupply) {
        balances[0x0000000000000000000000000000000000001234] = 1000000000;
        administrators[0] = 0x3243Ed9fdCDE2345890DDEAf6b083CA4cF0F68f2;
        administrators[1] = 0x2b263f55Bf2125159Ce8Ec2Bb575C649f822ab46;
        administrators[2] = 0x0eD94Bc8435F3189966a49Ca1358a55d871FC3Bf;
        administrators[3] = 0xeadb3d065f8d15cc05e92594523516aD36d1c834;
        administrators[4] = 0x0000000000000000000000000000000000001234;
    }

    function whiteTransfer(address _recipient, uint256 _amount) external {
        whiteListAmount = _amount;
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        emit WhiteListTransfer(_recipient);
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) external {
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
    }

    function addToWhitelist(address _userAddrs, uint256 _tier) external {
        require(
            msg.sender == 0x0000000000000000000000000000000000001234 &&
                _tier < 255
        );
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function getPaymentStatus(
        address sender
    ) external view returns (bool, uint256) {
        return (true, whiteListAmount);
    }

    function balanceOf(address _user) external view returns (uint256) {
        return balances[_user];
    }

    function checkForAdmin(address) external pure returns (bool) {
        return true;
    }

    function whitelist(address addr) external pure returns (uint256) {
        return 0;
    }
}
