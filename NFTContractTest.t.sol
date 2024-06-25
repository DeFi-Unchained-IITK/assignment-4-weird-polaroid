// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/NFTContract.sol";

contract NFTContractTest is Test {
    NFTContract nft;
    address owner = address(1);
    address user1 = address(2);
    address user2 = address(3);

    function setUp() public {
        vm.prank(owner);
        nft = new NFTContract();
    }

    function testInitialState() public {
        assertEq(nft.name(), "NFTContract");
        assertEq(nft.symbol(), "NFTC");
        assertEq(nft.publicMintOpen(), false);
        assertEq(nft.allowListMintOpen(), false);
        assertEq(nft.totalSupply(), 0);
    }

    function testEditMintWindows() public {
        vm.prank(owner);
        nft.editMintWindows(true, true);
        assertEq(nft.publicMintOpen(), true);
        assertEq(nft.allowListMintOpen(), true);
    }

    function testFailEditMintWindowsNotOwner() public {
        vm.prank(user1);
        nft.editMintWindows(true, true);
    }

    function testAllowListMint() public {
        address[] memory allowList = new address[](1);
        allowList[0] = user1;

        vm.startPrank(owner);
        nft.setAllowList(allowList);
        nft.editMintWindows(false, true);
        vm.stopPrank();

        vm.prank(user1);
        vm.deal(user1, 1 ether);
        nft.allowListMint{value: 0.001 ether}();

        assertEq(nft.balanceOf(user1), 1);
        assertEq(nft.ownerOf(0), user1);
    }

    function testFailAllowListMintNotOnList() public {
        vm.prank(owner);
        nft.editMintWindows(false, true);

        vm.prank(user2);
        vm.deal(user2, 1 ether);
        nft.allowListMint{value: 0.001 ether}();
    }

    function testPublicMint() public {
        vm.prank(owner);
        nft.editMintWindows(true, false);

        vm.prank(user1);
        vm.deal(user1, 1 ether);
        nft.publicMint{value: 0.01 ether}();

        assertEq(nft.balanceOf(user1), 1);
        assertEq(nft.ownerOf(0), user1);
    }

    function testFailPublicMintClosed() public {
        vm.prank(user1);
        vm.deal(user1, 1 ether);
        nft.publicMint{value: 0.01 ether}();
    }

    function testWithdraw() public {
        vm.prank(owner);
        nft.editMintWindows(true, false);

        vm.prank(user1);
        vm.deal(user1, 1 ether);
        nft.publicMint{value: 0.01 ether}();

        uint256 initialBalance = address(owner).balance;
        
        vm.prank(owner);
        nft.withdraw(owner);

        assertEq(address(owner).balance, initialBalance + 0.01 ether);
        assertEq(address(nft).balance, 0);
    }

    function testFailWithdrawNotOwner() public {
        vm.prank(user1);
        nft.withdraw(user1);
    }

    function testPause() public {
        vm.prank(owner);
        nft.pause();

        vm.expectRevert("Pausable: paused");
        vm.prank(owner);
        nft.editMintWindows(true, true);
    }

    function testUnpause() public {
        vm.startPrank(owner);
        nft.pause();
        nft.unpause();
        vm.stopPrank();

        vm.prank(owner);
        nft.editMintWindows(true, true);
        assertEq(nft.publicMintOpen(), true);
        assertEq(nft.allowListMintOpen(), true);
    }
}