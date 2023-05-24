pragma solidity >=0.8.0;
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IPromise is IERC20 {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function oneBipOfTotalSupply() external view returns (uint256);
}
