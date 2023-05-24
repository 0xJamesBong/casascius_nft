pragma solidity >=0.8.0;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Context} from "../lib/openzeppelin-contracts/contracts/utils/Context.sol";
import {SafeMath} from "../lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

contract Zi is Context, ERC20, Ownable {
    using SafeMath for uint256;

    constructor() ERC20("Zi", "ZI") {
        uint256 initialSupply = 10 ** 7;
        _mint(_msgSender(), initialSupply);
    }

    address public minter;

    function setMinter(address _minter) public onlyOwner {
        minter = _minter;
    }

    modifier onlyMinter() {
        require(_msgSender() == minter, "Not minter!");
        _;
    }

    function mint(address account, uint256 amount) public onlyMinter {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }

    function oneBipOfTotalSupply() public view returns (uint256) {
        return totalSupply().div(10000);
    }
}
