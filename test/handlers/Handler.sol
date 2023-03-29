/*

pragma solidity 0.8.19; //You can change version

import "../../src/Gas.sol";
import  "forge-std/Base.sol";
import "forge-std/StdCheats.sol";
import "forge-std/StdUtils.sol";
import "forge-std/console.sol";
import {AddressSet, LibAddressSet} from "../helpers/AddressSet.sol";


contract Handler is CommonBase, StdCheats, StdUtils {
    using LibAddressSet for AddressSet;

    AddressSet internal _actors;
    address internal currentActor;
    
    GasContract public gas;
    uint256 public totalSupply = 1000000000;
    mapping(address => bool) public GhostWhiteList;
    uint256 public totalTransfers;
    address public owner = address(0x1234);

    modifier createActor() {
        currentActor = msg.sender;
        _actors.add(msg.sender);
        _;
    }

    modifier useActor(uint256 actorIndexSeed) {
        currentActor = _actors.rand(actorIndexSeed);
        _;
    }
    
    constructor(GasContract _gas) {
        gas = _gas;
    }

    function ownerBalance() external returns(uint256) {
        return gas.balances(owner);
    }

    function actors() external returns (address[] memory) {
      return _actors.addrs;
    }

    function addToWhitelist(uint256 _tier) public createActor {
        _tier = bound( _tier, 1, 244);
        vm.startPrank(owner);
        gas.addToWhitelist(currentActor, _tier);
        console.log(currentActor);
        vm.stopPrank();
     }

    function whiteTransfer(uint256 actorSeed, uint256 _amount) public useActor(actorSeed) {
        _amount = bound(_amount,0, gas.balanceOf(currentActor));
        vm.assume(_amount > 3);
        vm.prank(currentActor);
        gas.whiteTransfer(currentActor, _amount);
        totalTransfers += _amount;
    }

    function transfer(uint256 actorSeed, uint256 _amount,  string calldata name) public useActor(actorSeed) {
        _amount = bound(_amount,0 , gas.balanceOf(owner));
        vm.assume(_amount > 3);
        vm.assume(bytes(name).length < 9 );
        vm.prank(owner);
        gas.transfer(currentActor, _amount, name);
        totalTransfers += _amount;
    }

}*/
