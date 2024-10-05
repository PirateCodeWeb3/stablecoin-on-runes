// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.27;

import {IDaiOnRunes} from "./IDaiOnRunes.sol";
import {Initializable} from "../lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC165} from "../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Dai} from "../lib/dss/src/dai.sol";

/**
 * @title Bridge Ethereum Dai to Bitcoin Runes
 */
contract DaiOnRunes is IDaiOnRunes, Ownable, ERC165, Initializable, ReentrancyGuard {
    uint256 constant MAX_FEE = 10 * 1e18;
    uint256 constant DEFAULT_FEE = 2 * 1e18;

    uint256 private mintFee;
    uint256 private redeemFee;
    uint256 private fee;
    Dai private dai;

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IDaiOnRunes).interfaceId || super.supportsInterface(interfaceId);
    }

    function initialize(address daiContract_) public initializer {
        dai = Dai(daiContract_);
        mintFee = DEFAULT_FEE;
        redeemFee = DEFAULT_FEE;
    }

    function mint(string calldata bitcoinAddress, uint256 amount) external nonReentrant {
        require(amount > mintFee, "DaiOnRunes: mint amount less than mint fee");
        fee += mintFee;
        dai.transferFrom(msg.sender, address(this), amount);
        emit Minted(msg.sender, bitcoinAddress, amount, mintFee);
    }

    function redeem(string calldata bitcoinTxId, address receiver, uint256 amount) external onlyOwner nonReentrant {
        require(amount > redeemFee, "DaiOnRunes: redeem amount less than redeem fee");
        fee += redeemFee;
        dai.transferFrom(address(this), receiver, amount - redeemFee);
        emit Redeemed(bitcoinTxId, receiver, amount, redeemFee);
    }

    function withdrawFee(uint256 amount) external onlyOwner nonReentrant {
        require(amount <= fee, "DaiOnRunes: withdraw amount more than fee");
        dai.transferFrom(address(this), owner(), amount);
        fee -= amount;
        emit FeesWithdrawn(amount);
    }

    function getFee() external view returns (uint256) {
        return fee;
    }

    function setMintFee(uint256 newFee) external onlyOwner {
        require(newFee < MAX_FEE, "DaiOnRunes: mint fee over limit");
        mintFee = newFee;
        emit MintFeeUpdated(newFee);
    }

    function setRedeemFee(uint256 newFee) external onlyOwner {
        require(newFee < MAX_FEE, "DaiOnRunes: redeem fee over limit");
        redeemFee = newFee;
        emit RedeemFeeUpdated(newFee);
    }

    function getMintFee() external view returns (uint256) {
        return mintFee;
    }

    function getRedeemFee() external view returns (uint256) {
        return redeemFee;
    }
}
