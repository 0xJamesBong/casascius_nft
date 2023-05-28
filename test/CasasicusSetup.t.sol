// pragma solidity >=0.8.19 <0.9.0;

// import {PRBTest} from "@prb/test/PRBTest.sol";
// import {console2} from "forge-std/console2.sol";
// import {StdCheats} from "forge-std/StdCheats.sol";
// import {Casascius} from "../src/Casascius.sol";
// import {console} from "forge-std/console.sol";
// import {ERC20Mock} from "./mocks/ERC20Mock.sol";

// interface IERC20 {
//     function balanceOf(address account) external view returns (uint256);
// }

// contract Casascius_Setup_Test is PRBTest, StdCheats {
//     Casascius ca;
//     ERC20Mock wbtc;
//     ERC20Mock sfrxeth;
//     address alice = address(0xAA); // alice is designated the owner of the pizza contract
//     address bob = address(0xBB);
//     address carol = address(0xCC);
//     address dominic = address(0xDD);

//     function setUp() public {
//         vm.prank(alice);
//         wbtc = new ERC20Mock("Wrapped Bitcoin", "WBTC");
//         // vm.prank(alice);
//         wbtc.mint(alice, 21 * 10 ** 6);

//         vm.prank(alice);
//         sfrxeth = new ERC20Mock("Staked Frax Eth", "SFRXETH");
//         vm.prank(alice);
//         sfrxeth.mint(alice, 10 ** 9);

//         ca = new Casascius(address(wbtc), address(sfrxeth));
//     }

//     function test_ok() public {
//         assertEq(wbtc.balanceOf(alice), 21 * 10 ** 6);
//         assertEq(sfrxeth.balanceOf(alice), 10 ** 9);
//     }
// }
