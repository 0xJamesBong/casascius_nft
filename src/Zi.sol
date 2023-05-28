pragma solidity >=0.8.0;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Context} from "../lib/openzeppelin-contracts/contracts/utils/Context.sol";
import {SafeMath} from "../lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import {MinterControl} from "./MinterControl.sol";

contract Zi is Context, ERC20, MinterControl {
    using SafeMath for uint256;
    uint256 public initialSupply;

    constructor() ERC20("Zi", "ZI") {
        initialSupply = uint256(10 ** 4);
        _mint(_msgSender(), initialSupply);
    }

    function mint(address account, uint256 amount) public onlyMinters {
        uint256 newTotalSupply = super.totalSupply() + amount;

        require(
            newTotalSupply <= uint256(10 ** 6),
            "Hitting total supply of 1 million"
        );
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyMinters {
        require(account == _msgSender(), "Burning other people's tokens!");
        uint256 newTotalSupply = super.totalSupply() - amount;
        require(newTotalSupply > 0, "You cannot burn the entire supply");
        _burn(account, amount);
    }

    function oneBipOfTotalSupply() public view returns (uint256) {
        return totalSupply().div(uint256(10000));
    }
}
