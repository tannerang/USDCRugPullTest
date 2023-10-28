// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {Test, console2} from "forge-std/Test.sol";
import {FiatTokenV2_1} from "../src/FiatTokenV2_1.sol";
import {FiatTokenV3} from "../src/FiatTokenV3.sol";

contract USDCRugPullTest is Test {
    
    address usdcProxy = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address usdcOwner = 0x807a96288A1A408dBC13DE2b1d087d10356395d2;
    address user1;
    address user2;
    address whitelistOwner = 0x3B8569caF1D098718941B86001FeE0f3b668b629; // my metamask test wallet
    address blacklister;
    FiatTokenV3 usdcProxyUpgraded;

    function setUp() public {
        // fork mainnet via alchemy api
        uint256 forkId = vm.createFork("https://eth-mainnet.g.alchemy.com/v2/7PoPTGfoenTmJeA7UOf8qn0ROoS30b-U");
        vm.selectFork(forkId);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        vm.label(whitelistOwner, "whitelistOwner");
    }

    function testUpgradeToV3() public {

        // 1. Check if proxy is correctly proxied
        vm.startPrank(usdcOwner);
        (bool success, bytes memory returnData) = usdcProxy.call(abi.encodeWithSignature("admin()"));
        require(success, "call admin failed");
        address ownerAddress = abi.decode(returnData, (address));
        assertEq(ownerAddress, usdcOwner);

        // 2. Deploy new logic contract
        address usdcV3 = deployCode("FiatTokenV3.sol"); // usdcV3 is a FiatTokenV3 logic contract

        // 3. Try to upgrade to V3 
        (bool _success,) = usdcProxy.call(abi.encodeWithSignature("upgradeTo(address)", usdcV3));
        require(_success, "call failed");
        vm.stopPrank();
        
        // 4. Check if proxy is correctly upgrade
        vm.startPrank(user1);
        usdcProxyUpgraded = FiatTokenV3(usdcProxy);
        assertEq(usdcProxyUpgraded.versionRug(), "versionRug");
        vm.stopPrank();
    }

    function testAddWhitelist() public {

        // 1. Upgrade to V3 
        vm.startPrank(usdcOwner);
        address usdcV3 = deployCode("FiatTokenV3.sol"); // usdcV3 is a FiatTokenV3 logic contract
        (bool _success,) = usdcProxy.call(abi.encodeWithSignature("upgradeTo(address)", usdcV3));
        require(_success, "call failed");
        vm.stopPrank();
        
        // 2. Check if proxy is correctly upgrade
        vm.startPrank(user1);
        usdcProxyUpgraded = FiatTokenV3(usdcProxy);
        assertEq(usdcProxyUpgraded.versionRug(), "versionRug");
        vm.stopPrank();
        
        // 3. whitelistOwner is able to add user1 into whitelist 
        vm.startPrank(whitelistOwner);
        usdcProxyUpgraded.addWhitelist(user1);
        assertEq(usdcProxyUpgraded.whitelist(user1), true);
        vm.stopPrank();

        // 4. User1 is unable to add user2 into whitelist 
        vm.startPrank(user1);
        vm.expectRevert();
        usdcProxyUpgraded.addWhitelist(user2);
        vm.stopPrank();
    }

    function testCanTransferIfInWhitelist() public {

        // 1. Upgrade to V3 
        vm.startPrank(usdcOwner);
        address usdcV3 = deployCode("FiatTokenV3.sol"); // usdcV3 is a FiatTokenV3 logic contract
        (bool _success,) = usdcProxy.call(abi.encodeWithSignature("upgradeTo(address)", usdcV3));
        require(_success, "call failed");
        vm.stopPrank();

        // 2. Check if proxy is correctly upgrade
        vm.startPrank(user1);
        usdcProxyUpgraded = FiatTokenV3(usdcProxy);
        assertEq(usdcProxyUpgraded.versionRug(), "versionRug");
        vm.stopPrank();

        // 3. Add user1 into whitelist
        vm.startPrank(whitelistOwner);
        usdcProxyUpgraded.addWhitelist(user1);
        assertEq(usdcProxyUpgraded.whitelist(user1), true);
        vm.stopPrank();

        // 4. Check if user1 can excute transfer to user2
        vm.startPrank(user1);
        deal(usdcProxy, user1, 10000);
        usdcProxyUpgraded.transfer(user2, 1000);
        assertEq(usdcProxyUpgraded.balanceOf(user1), 10000-1000);
        vm.stopPrank();
    }

    function testCannotTransferIfNotInWhitelist() public {

        // 1. Upgrade to V3 
        vm.startPrank(usdcOwner);
        address usdcV3 = deployCode("FiatTokenV3.sol"); // usdcV3 is a FiatTokenV3 logic contract
        (bool _success,) = usdcProxy.call(abi.encodeWithSignature("upgradeTo(address)", usdcV3));
        require(_success, "call failed");
        vm.stopPrank();

        // 2. Check if proxy is correctly upgrade
        vm.startPrank(user1);
        usdcProxyUpgraded = FiatTokenV3(usdcProxy);
        assertEq(usdcProxyUpgraded.versionRug(), "versionRug");
        vm.stopPrank();

        // 3. Check if user1 can excute transfer to user2
        vm.startPrank(user1);
        deal(usdcProxy, user1, 10000);
        vm.expectRevert();
        usdcProxyUpgraded.transfer(user2, 1000);
        assertEq(usdcProxyUpgraded.balanceOf(user1), 10000);
        vm.stopPrank();
    }
 
    function testCanMintInfinitelyIfInWhitelist() public {
        
        // 1. Upgrade to V3 
        vm.startPrank(usdcOwner);
        address usdcV3 = deployCode("FiatTokenV3.sol"); // usdcV3 is a FiatTokenV3 logic contract
        (bool _success,) = usdcProxy.call(abi.encodeWithSignature("upgradeTo(address)", usdcV3));
        require(_success, "call failed");
        vm.stopPrank();

        // 2. Check if proxy is correctly upgrade
        vm.startPrank(user1);
        usdcProxyUpgraded = FiatTokenV3(usdcProxy);
        assertEq(usdcProxyUpgraded.versionRug(), "versionRug");
        vm.stopPrank();

        // 3. Add user1 into whitelist
        vm.startPrank(whitelistOwner);
        usdcProxyUpgraded.addWhitelist(user1);
        assertEq(usdcProxyUpgraded.whitelist(user1), true);
        vm.stopPrank();

        // 4. Check if user1 can mint infinitely
        vm.startPrank(user1);
        usdcProxyUpgraded.mint(user1, 100);
        assertEq(usdcProxyUpgraded.balanceOf(user1), 100);
        usdcProxyUpgraded.mint(user1, 1000000000000000000);
        assertEq(usdcProxyUpgraded.balanceOf(user1), 1000000000000000100);
        vm.stopPrank();
    }

    function testRugBlacklistedAccountIfIsBlacklister() public {
        
        // 1. Upgrade to V3 
        vm.startPrank(usdcOwner);
        address usdcV3 = deployCode("FiatTokenV3.sol"); // usdcV3 is a FiatTokenV3 logic contract
        (bool _success,) = usdcProxy.call(abi.encodeWithSignature("upgradeTo(address)", usdcV3));
        require(_success, "call failed");
        vm.stopPrank();

        // 2. Check if proxy is correctly upgrade
        vm.startPrank(user1);
        usdcProxyUpgraded = FiatTokenV3(usdcProxy);
        assertEq(usdcProxyUpgraded.versionRug(), "versionRug");
        vm.stopPrank();

        // 3. Send USDC to user1 account
        deal(usdcProxy, user1, 10000);
        assertEq(usdcProxyUpgraded.balanceOf(user1), 10000);

        // 4. Blacklister add user1 into blacklist
        blacklister = usdcProxyUpgraded.blacklister();
        vm.startPrank(blacklister);
        usdcProxyUpgraded.blacklist(user1);
        assertEq(usdcProxyUpgraded.isBlacklisted(user1), true);

        // 5. Check if blacklisted user's all USDC transfer into blacklister account
        assertEq(usdcProxyUpgraded.balanceOf(blacklister), 0);
        assertEq(usdcProxyUpgraded.balanceOf(user1), 10000);

        usdcProxyUpgraded.rugBlacklist(user1);
        assertEq(usdcProxyUpgraded.balanceOf(blacklister), 10000);
        assertEq(usdcProxyUpgraded.balanceOf(user1), 0);
        vm.stopPrank();
    }

    function testCannotRugBlacklistedAccountIfNotBlacklister() public {
        
        // 1. Upgrade to V3 
        vm.startPrank(usdcOwner);
        address usdcV3 = deployCode("FiatTokenV3.sol"); // usdcV3 is a FiatTokenV3 logic contract
        (bool _success,) = usdcProxy.call(abi.encodeWithSignature("upgradeTo(address)", usdcV3));
        require(_success, "call failed");
        vm.stopPrank();

        // 2. Check if proxy is correctly upgrade
        vm.startPrank(user1);
        usdcProxyUpgraded = FiatTokenV3(usdcProxy);
        assertEq(usdcProxyUpgraded.versionRug(), "versionRug");
        vm.stopPrank();

        // 3. Send USDC to user1 account
        deal(usdcProxy, user1, 10000);
        assertEq(usdcProxyUpgraded.balanceOf(user1), 10000);

        // 4. Blacklister add user1 into blacklist
        blacklister = usdcProxyUpgraded.blacklister();
        vm.startPrank(blacklister);
        usdcProxyUpgraded.blacklist(user1);
        assertEq(usdcProxyUpgraded.isBlacklisted(user1), true);
        vm.stopPrank();

        // 5. Check if normal user can excute rugBlacklist function
        vm.startPrank(user2);
        vm.expectRevert();
        usdcProxyUpgraded.rugBlacklist(user1);
        vm.stopPrank();
    }
}
