pragma solidity >=0.8.0;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IPromise} from "./IPromise.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IUniswapV2Router02} from "../lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {SafeMath} from "../lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

// lib/prb-math/src/SD59x18.sol
contract Casascius is ERC721, Ownable {
    using SafeMath for uint256;

    constructor(address _wbtc, address _sfrxeth) ERC721("Casascius", "CASA") {
        wbtc = _wbtc;
        sfrxeth = _sfrxeth;
    }

    uint256 totalSupply = 10000;
    // address public UniswapV2Router02 =
    //     0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public ut;
    IPromise public utilityToken = IPromise(ut);
    address public sfrxeth;
    // = 0xac3E018457B222d93114458476f3E3416Abbe38F;
    address public wbtc;
    //  wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public eth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    mapping(address => bool) public assetEnabled;
    mapping(address => mapping(uint256 => uint256)) asset_to_facevalue_to_supply;
    mapping(uint256 => Metadata) public tokenId_to_metadata;

    function enableAsset(
        address asset
    ) public onlyOwner returns (bool success) {
        assetEnabled[asset] = true;
        return (assetEnabled[asset]);
    }

    function disableAsset(
        address asset
    ) public onlyOwner returns (bool success) {
        assetEnabled[asset] = false;
        return (!assetEnabled[asset]);
    }

    modifier whenAssetEnabled(address asset) {
        require(assetEnabled[asset], "Asset not enabled!");
        _;
    }

    function supplyUtilityTokenAddress(address _ut) public onlyOwner {
        ut = _ut;
    }

    mapping(address => uint256) assets_to_reserves;

    struct Metadata {
        uint256 mintTime;
        uint256 facevalue;
        address asset;
        uint256 jackpotClaims;
    }

    function totalWeightedLockedTime(
        uint256 time,
        address asset
    ) public view returns (uint256) {
        uint256 twlt;
        for (uint256 i = 0; i <= 10000; i++) {
            if (tokenId_to_metadata[i].asset == asset) {
                twlt +=
                    tokenId_to_metadata[i].facevalue *
                    (time - tokenId_to_metadata[i].mintTime);
            }
        }
        return twlt;
    }

    function totalJackpot(address _asset) public view returns (uint256 total) {
        uint256 total;
        for (uint256 i = 0; i <= 10000; i++) {
            if (tokenId_to_metadata[i].asset == _asset) {
                total += tokenId_to_metadata[i].jackpotClaims;
            }
        }
        return total;
    }

    function distributeAssets(
        uint256 _toBeDistributed,
        address _asset
    ) internal {
        uint256 time = block.timestamp;
        uint256 twlt = totalWeightedLockedTime(time, _asset);
        for (uint256 i = 0; i <= 10000; i++) {
            if (tokenId_to_metadata[i].asset == _asset) {
                tokenId_to_metadata[i].jackpotClaims += assetDistributable(
                    _toBeDistributed,
                    _asset,
                    i,
                    time,
                    twlt
                );
            }
        }
    }

    function assetDistributable(
        uint256 _toBeDistributed,
        address _asset,
        uint256 _tokenId,
        uint256 _time,
        uint256 _twlt
    ) internal view returns (uint256 distributable) {
        address asset = tokenId_to_metadata[_tokenId].asset;
        uint256 facevalue = tokenId_to_metadata[_tokenId].facevalue;
        if (asset != _asset) {
            return 0;
        } else {
            distributable = (
                (facevalue.mul(_time - tokenId_to_metadata[_tokenId].mintTime))
                    .div(_twlt)
            ).mul(_toBeDistributed);
            return (distributable);
        }
    }

    modifier notYetRedeemed(uint256 _tokenId) {
        require(
            tokenId_to_metadata[_tokenId].facevalue > 0,
            "Token has already been redeemed"
        );
        _;
    }
    modifier onlyTokenHolder(uint256 tokenId) {
        require(msg.sender == ownerOf(tokenId), "not owner of token!");
        _;
    }

    // facevalues stored are moved by 2 decimals to enable better handling;

    // 10000    = 1000000
    // 1000     = 100000
    // 100      = 10000
    // 50       = 5000
    // 20       = 2000
    // 10       = 1000
    // 5        = 500
    // 2        = 200
    // 1        = 100
    // 0.5      = 50
    // 0.2      = 20
    // 0.1      = 10
    // 0.05     = 5

    function getDecimalsByAsset(
        address asset
    ) public returns (uint256 decimals) {
        if (asset == eth || asset == sfrxeth) {
            decimals = 18;
        }
        if (asset == wbtc) {
            decimals = 8;
        }
    }

    function isValidFacevalue(uint256 _facevalue) private pure returns (bool) {
        uint256[13] memory validValues = [
            uint256(1000000),
            uint256(100000),
            uint256(10000),
            uint256(5000),
            uint256(2000),
            uint256(1000),
            uint256(500),
            uint256(200),
            uint256(100),
            uint256(50),
            uint256(20),
            uint256(10),
            uint256(5)
        ];

        for (uint256 i = 0; i < validValues.length; i++) {
            if (_facevalue == validValues[i]) {
                return true;
            }
        }
        return false;
    }

    // function convertFaceValue(
    //     uint256 _facevalue,
    //     address _asset
    // ) internal view returns (uint256 convertedFacevalue) {
    //     uint256 decimals = getDecimalsByAsset(_asset);
    //     _facevalue *10**
    // }

    function mint(
        address _to,
        uint256 _tokenId,
        uint256 _facevalue,
        address _asset
    ) private returns (bool) {
        require(
            tokenId_to_metadata[_tokenId].facevalue == 0,
            "Metadata already exists for the given tokenId"
        );
        require(isValidFacevalue(_facevalue), "Invalid value");
        require(_tokenId <= totalSupply, "too high");
        uint256 _decimals = getDecimalsByAsset(_asset);
        uint256 facevalue_adjusted_by_asset_decimals = _facevalue *
            uint256(10) ** _decimals;

        bool success = false;
        if (_asset == eth) {
            _asset = eth;

            (bool _success, ) = payable(address(this)).call{
                value: facevalue_adjusted_by_asset_decimals
            }("");
            success = _success;
        } else if (_asset == wbtc) {
            _asset = wbtc;

            bool _success = IERC20(_asset).transferFrom(
                _to,
                address(this),
                facevalue_adjusted_by_asset_decimals
            );
            success = _success;
        } else if (_asset == sfrxeth) {
            _asset = sfrxeth;

            bool _success = IERC20(_asset).transferFrom(
                _to,
                address(this),
                facevalue_adjusted_by_asset_decimals
            );
            success = _success;
        }
        require(success, "transaction didn't go through");
        if (success) {
            tokenId_to_metadata[_tokenId] = Metadata(
                block.timestamp,
                _facevalue,
                _asset,
                0
            );
            asset_to_facevalue_to_supply[_asset][_facevalue] += 1;

            if (ownerOf(_tokenId) == address(0)) {
                _mint(_to, _tokenId);
            } else if (ownerOf(_tokenId) == address(this)) {
                safeTransferFrom(address(this), _to, _tokenId);
            }
            emit Minted(block.timestamp, _tokenId, _facevalue, _asset);
            return success;
        } else {
            return false;
        }
    }

    uint256 lockTime = 4 * 365 days;

    function rewardsPending(
        uint256 tokenId
    ) public view returns (uint256 rewards) {
        uint256 bip = utilityToken.oneBipOfTotalSupply();
        uint256 facevalue = tokenId_to_metadata[tokenId].facevalue;
        address asset = tokenId_to_metadata[tokenId].asset;
        uint256 base = rewardsDistributable(facevalue, asset).div(totalSupply);
        uint256 supply = asset_to_facevalue_to_supply[asset][facevalue];
        uint256 bonus = ((totalSupply - supply).div((supply + 1) ** 2)).mul(
            base
        );
        uint256 lastClaimTime = tokenId_to_rewardsLastClaimed[tokenId];
        rewards = (base + bonus).mul(block.timestamp - lastClaimTime).div(
            lockTime
        );
        return (rewards);
    }

    mapping(uint256 => uint256) tokenId_to_rewardsLastClaimed;

    function rewardsDistributable(
        uint256 facevalue,
        address asset
    ) public view returns (uint256 distributable) {
        uint256 bip = utilityToken.oneBipOfTotalSupply();
        uint256 totalRewardsToBeDistributed;
        if (facevalue == 1000000) {
            totalRewardsToBeDistributed = 10000000 * bip;
        } else if (facevalue == 100000) {
            totalRewardsToBeDistributed = 1000000 * bip;
        } else if (facevalue == 10000) {
            totalRewardsToBeDistributed = 100000 * bip;
        } else if (facevalue == 5000) {
            totalRewardsToBeDistributed = 50000 * bip;
        } else if (facevalue == 2000) {
            totalRewardsToBeDistributed = 20000 * bip;
        } else if (facevalue == 1000) {
            totalRewardsToBeDistributed = 10000 * bip;
        } else if (facevalue == 500) {
            totalRewardsToBeDistributed = 5000 * bip;
        } else if (facevalue == 200) {
            totalRewardsToBeDistributed = 2000 * bip;
        } else if (facevalue == 100) {
            totalRewardsToBeDistributed = 1000 * bip;
        } else if (facevalue == 50) {
            totalRewardsToBeDistributed = 500 * bip;
        } else if (facevalue == 20) {
            totalRewardsToBeDistributed = 200 * bip;
        } else if (facevalue == 10) {
            totalRewardsToBeDistributed = 100 * bip;
        } else if (facevalue == 5) {
            totalRewardsToBeDistributed = 50 * bip;
        }

        if (asset == wbtc) {
            distributable = totalRewardsToBeDistributed;
        } else if (asset == eth) {
            distributable = totalRewardsToBeDistributed.mul(5).div(6);
        } else if (asset == sfrxeth) {
            distributable = totalRewardsToBeDistributed.mul(3).div(4);
        }
    }

    function redeem(
        uint256 tokenId
    ) public onlyOwner notYetRedeemed(tokenId) returns (bool) {
        require(
            block.timestamp - tokenId_to_metadata[tokenId].mintTime >= lockTime,
            "Ecclesiastes 3:4"
        );
        address asset = tokenId_to_metadata[tokenId].asset;
        uint256 facevalue = tokenId_to_metadata[tokenId].facevalue;
        uint256 _decimals = getDecimalsByAsset(asset);
        uint256 facevalue_adjusted_by_asset_decimals = facevalue *
            uint256(10) ** _decimals;

        bool success;

        if (asset == eth) {
            (bool _success, ) = payable(address(msg.sender)).call{
                value: facevalue_adjusted_by_asset_decimals
            }("");
            success = _success;
        } else {
            asset = tokenId_to_metadata[tokenId].asset;
            bool _success = IERC20(asset).transferFrom(
                address(this),
                msg.sender,
                facevalue_adjusted_by_asset_decimals
            );
            success = _success;
        }

        uint256 rewards = rewardsPending(tokenId);
        require(success, "withdrawal didn't go through");
        if (success) {
            safeTransferFrom(msg.sender, address(this), tokenId);
            utilityToken.mint(msg.sender, rewards);
            asset_to_facevalue_to_supply[asset][facevalue] -= 1;

            emit Redeemed(facevalue, block.timestamp, tokenId, rewards, asset);
            return success;
        } else {
            return false;
        }
    }

    event Minted(
        uint256 mintTime,
        uint256 tokenId,
        uint256 facevalue,
        address asset
    );
    event Redeemed(
        uint256 mintTime,
        uint256 tokenId,
        uint256 facevalue,
        uint256 rewards,
        address asset
    );

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);

        return ("");
    }

    address public utilityToken_eth_pool;
    address public utilityToken_sfrxEth_pool;
    address public utilityToken_wbtc_pool;
    uint256 public protocol_owned_liquidity;

    function emergencyRedeem(
        uint256 tokenId,
        uint256 payment
    ) public notYetRedeemed(tokenId) {
        require(
            payment >= utilityToken.oneBipOfTotalSupply().mul(5),
            "insufficient payment"
        );

        bool success;
        uint256 tributeToLPDesired = payment.div(3);
        address asset = tokenId_to_metadata[tokenId].asset;
        uint256 facevalue = tokenId_to_metadata[tokenId].facevalue;

        uint256 _decimals = getDecimalsByAsset(asset);
        uint256 facevalue_adjusted_by_asset_decimals = facevalue *
            uint256(10) ** _decimals;
        uint256 retained = facevalue_adjusted_by_asset_decimals.div(100);
        uint256 amountMin = retained.div(2);
        uint256 intact = facevalue_adjusted_by_asset_decimals - retained;
        uint256 toBeDistributed = retained - amountMin;
        uint256 toBeBurned;
        uint256 toBeRedeemed;

        if (asset == eth) {
            (
                uint256 amountUt,
                uint256 amountETH,
                uint256 _liquidity
            ) = IUniswapV2Router02(utilityToken_eth_pool).addLiquidityETH{
                    value: amountMin
                }(
                    ut,
                    tributeToLPDesired,
                    1,
                    amountMin,
                    address(this),
                    block.timestamp + 24
                );
            toBeBurned = payment.sub(tributeToLPDesired).add(amountUt);
            distributeAssets(toBeDistributed, asset);
            toBeRedeemed = intact.add(amountETH).add(
                tokenId_to_metadata[tokenId].jackpotClaims
            );
            (bool _success, ) = payable(msg.sender).call{value: toBeRedeemed}(
                ""
            );
            success = _success;
            protocol_owned_liquidity += _liquidity;
        } else {
            address pool = asset == wbtc
                ? utilityToken_wbtc_pool
                : utilityToken_sfrxEth_pool;
            (
                uint256 amountUt,
                uint256 amountAsset,
                uint256 _liquidity
            ) = IUniswapV2Router02(pool).addLiquidity(
                    ut,
                    asset,
                    tributeToLPDesired,
                    amountMin,
                    1,
                    amountMin,
                    address(this),
                    block.timestamp + 24
                );
            toBeBurned = payment.sub(tributeToLPDesired).add(amountUt);
            distributeAssets(toBeDistributed, asset);
            toBeRedeemed = intact.add(amountAsset).add(
                tokenId_to_metadata[tokenId].jackpotClaims
            );
            bool _success = IERC20(asset).transferFrom(
                address(this),
                msg.sender,
                toBeRedeemed
            );
            success = _success;
            protocol_owned_liquidity += _liquidity;
        }

        utilityToken.burn(msg.sender, toBeBurned);

        require(ownerOf(tokenId) == address(0), "token not burned");

        if (success && ownerOf(tokenId) == address(0)) {
            asset_to_facevalue_to_supply[asset][facevalue] -= 1;
            tokenId_to_metadata[tokenId].facevalue = 0;
            require(
                tokenId_to_metadata[tokenId].facevalue == 0,
                "metadata not wiped"
            );
        }

        require(success, "withdrawal not successful");
    }
}
