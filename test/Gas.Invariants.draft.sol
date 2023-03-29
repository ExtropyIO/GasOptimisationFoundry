// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19; //You can change version

import "forge-std/Test.sol";
import "../../src/Gas.sol";
import {Handler} from "./handlers/Handler.sol";

contract GasTest is Test {
    GasContract public gas;
    Handler public handler;
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
        handler = new Handler(gas);

        targetContract(address(handler));
        vm.stopPrank();
    }

    function invariant_totalSupply() public {
        assertEq(totalSupply, gas.totalSupply());
    }

    /*function invariant_sumOfBalances() public {
        console.log(handler.ownerBalance());
        console.log(handler.totalTransfers());
        assertEq(totalSupply, handler.ownerBalance() + handler.totalTransfers());
    }*/

    function invariant_1() public {
        assertEq( handler.ownerBalance(), totalSupply);
    }

        function invariant_2() public {
        assertEq( handler.totalTransfers(), 0);
    }

}

