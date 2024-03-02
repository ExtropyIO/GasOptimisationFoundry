// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0; 

import "forge-std/Test.sol";
import "../src/Gas.sol";

contract GasTest is Test {
    GasContract public gas;
    uint256 public totalSupply = 1000000000;
    address owner = address(0x1234);
    address addr1 = address(0x5678);
    address addr2 = address(0x9101);
    address addr3 = address(0x1213);

    address[] admins = [
        address(0x3243Ed9fdCDE2345890DDEAf6b083CA4cF0F68f2),
        address(0x2b263f55Bf2125159Ce8Ec2Bb575C649f822ab46),
        address(0x0eD94Bc8435F3189966a49Ca1358a55d871FC3Bf),
        address(0xeadb3d065f8d15cc05e92594523516aD36d1c834), 
        owner
    ];

    function setUp() public {
        vm.startPrank(owner);
        gas = new GasContract(admins, totalSupply);
        vm.stopPrank();
    }

    function test_admins() public {
        for (uint8 i = 0; i < admins.length; ++i) {
            assertEq(admins[i], gas.administrators(i));
        }
    } 

    // addToWhitelist Tests
    

    function test_onlyOwner(address _userAddrs, uint256 _tier) public {
        vm.assume(_userAddrs != address(gas));
        _tier = bound( _tier, 1, 244);
        vm.expectRevert();
        gas.addToWhitelist(_userAddrs, _tier);
    }

    function test_tiers(address _userAddrs, uint256 _tier) public {
        vm.assume(_userAddrs != address(gas));
        _tier = bound( _tier, 1, 244);
        vm.prank(owner);
        gas.addToWhitelist(_userAddrs, _tier);
    }

    // Expect Event --> 
    event AddedToWhitelist(address userAddress, uint256 tier);
    function test_whitelistEvents(address _userAddrs, uint256 _tier) public {
        vm.startPrank(owner);
        vm.assume(_userAddrs != address(gas));
        _tier = bound( _tier, 1, 244);
        vm.expectEmit(true, true, false, true);
        emit AddedToWhitelist(_userAddrs, _tier);
        gas.addToWhitelist(_userAddrs, _tier);
        vm.stopPrank();
    }


    //----------------------------------------------------//
    //------------- Test whitelist Transfers -------------//
    //----------------------------------------------------//

    function test_whitelistTransfer(
        address _recipient,
        address _sender,
        uint256 _amount, 
        string calldata _name,
        uint256 _tier
    ) public {
        _amount = bound(_amount,0 , gas.balanceOf(owner));
        vm.assume(_amount > 3);
        vm.assume(bytes(_name).length < 9 );
        _tier = bound( _tier, 1, 244);
        vm.startPrank(owner);
        gas.transfer(_sender, _amount, _name);
        gas.addToWhitelist(_sender, _tier);
        vm.stopPrank();
        vm.prank(_sender);
        gas.whiteTransfer(_recipient, _amount);
        (bool a, uint256 b) = gas.getPaymentStatus(address(_sender));
        console.log(a);
        assertEq(a, true);
        assertEq(b, _amount);
    }

    // Reverts if teirs out of bounds
    function test_tiersReverts(address _userAddrs, uint256 _tier) public {
        vm.assume(_userAddrs != address(gas));
        vm.assume(_tier > 254);
        vm.prank(owner);
        vm.expectRevert();
        gas.addToWhitelist(_userAddrs, _tier);
    }

    // Expect Event --> 
    event WhiteListTransfer(address indexed);
    function test_whitelistEvents(
        address _recipient,
        address _sender,
        uint256 _amount, 
        string calldata _name,
        uint256 _tier
    ) public {

        _amount = bound(_amount,0 , gas.balanceOf(owner));
        vm.assume(_amount > 3);
        vm.assume(bytes(_name).length < 9 );
        _tier = bound( _tier, 1, 244);
        vm.startPrank(owner);
        gas.transfer(_sender, _amount, _name);
        gas.addToWhitelist(_sender, _tier);
        vm.stopPrank();
        vm.startPrank(_sender);
        vm.expectEmit(true, false, false, true);
        emit WhiteListTransfer(_recipient);
        gas.whiteTransfer(_recipient, _amount);
        vm.stopPrank();
    }

        /* whiteTranfer balance logic. 
        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;
        balances[senderOfTx] += whitelist[senderOfTx];
        balances[_recipient] -= whitelist[senderOfTx]; 
        */

    // check balances update 
    function testWhiteTranferAmountUpdate(
        address _recipient,
        address _sender,
        uint256 _amount, 
        string calldata _name,
        uint256 _tier
    ) public {
        uint256 _preRecipientAmount = gas.balances(_recipient) + 0;
        vm.assume(_recipient != address(0));
        vm.assume(_sender != address(0));
         _amount = bound(_amount,0 , gas.balanceOf(owner));
        _tier = bound( _tier, 1, 244);
        vm.assume(_amount > 3);
        vm.assume(bytes(_name).length < 9 && bytes(_name).length >0);
        vm.startPrank(owner);
        gas.transfer(_sender, _amount, _name);
        uint256 _preSenderAmount = gas.balances(_sender);
        gas.addToWhitelist(_sender, _tier);
        vm.stopPrank();
        vm.prank(_sender);
        gas.whiteTransfer(_recipient, _amount);
        assertEq(gas.balances(_sender), (_preSenderAmount - _amount) + gas.whitelist(_sender));
        assertEq(gas.balances(_recipient),(_preRecipientAmount + _amount) - gas.whitelist(_sender));
    }

    function testBalanceOf() public {
        uint256 bal = gas.balanceOf(owner);
        assertEq(bal, totalSupply);
    }

    function testCheckForAdmin() public {
        bool isAdmin = gas.checkForAdmin(owner);
        assertEq(isAdmin, true);
    }

    // TODO: No Specification
    function testGetPaymentHistory() public {}

    // TODO: No Specification
    function testGetTradingMode() public {}

    // TODO: No Specification
    function testAddHistory() public {}

    function testTransfer(uint256 _amount, address _recipient) public {
        vm.assume(_amount <= totalSupply);
        vm.startPrank(owner);

        uint256 ownerBal = gas.balanceOf(owner);
        uint256 balBefore = gas.balanceOf(_recipient);
        gas.transfer(_recipient, _amount, "name");
        uint256 balAfter = gas.balanceOf(_recipient);

        assertEq(balAfter, balBefore + _amount);
        assertEq(gas.balanceOf(owner), ownerBal - _amount);
    }

    function testAddToWhitelist(address user, uint256 tier) public {
        vm.expectRevert();
        vm.startPrank(user);
        vm.assume(user != owner);
        gas.addToWhitelist(user, tier);
        vm.stopPrank();
    }

    function testGetPaymentStatus(address sender) public {}
}
