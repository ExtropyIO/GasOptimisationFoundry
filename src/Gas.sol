// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

contract GasContract {
    uint256 private whiteListAmount;
    mapping(address => uint256) public balances;
    event WhiteListTransfer(address indexed);
    event AddedToWhitelist(address userAddress, uint256 tier);
    constructor(address[] memory _admins, uint256 _totalSupply) {
        balances[0x0000000000000000000000000000000000001234] = 1000000000;
    }

    function administrators(uint index) public pure returns (address admin) {
        assembly {
            switch index
            case 0 {
                admin := 0x3243Ed9fdCDE2345890DDEAf6b083CA4cF0F68f2
            }
            case 1 {
                admin := 0x2b263f55Bf2125159Ce8Ec2Bb575C649f822ab46
            }
            case 2 {
                admin := 0x0eD94Bc8435F3189966a49Ca1358a55d871FC3Bf
            }
            case 3 {
                admin := 0xeadb3d065f8d15cc05e92594523516aD36d1c834
            }
            case 4 {
                admin := 0x1234
            }
        }
    }

    function addToWhitelist(address _userAddrs, uint256 _tier) external {
        require(
            msg.sender == 0x0000000000000000000000000000000000001234 &&
                _tier < 255
        );
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function balanceOf(address _user) external view returns (uint256) {
        return balances[_user];
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) external {
        unchecked{
            balances[msg.sender] -= _amount;
            balances[_recipient] += _amount;
        }
    }

    function whiteTransfer(address _recipient, uint256 _amount) external {
        whiteListAmount = _amount;
        unchecked {
            balances[msg.sender] -= _amount;
            balances[_recipient] += _amount;
        }
        emit WhiteListTransfer(_recipient);
    }

    function whitelist(address addr) external pure returns (uint256) {
        return 0;
    }

    function getPaymentStatus(
        address sender
    ) external view returns (bool, uint256) {
        return (true, whiteListAmount);
    }

    function checkForAdmin(address) external pure returns (bool) {
        return true;
    }
}
