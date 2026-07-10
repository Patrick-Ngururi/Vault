// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import {IERC20} from "./ERC20.sol";

contract Vault {
    IERC20 public immutable token;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function _mint(address _to, uint256 _amount) private {
        totalSupply += _amount;
        balanceOf[_to] += _amount;
    }

    function _burn(address _from, uint256 _amount) private {
        totalSupply -= _amount;
        balanceOf[_from] += _amount;
    }

    /**
     * Inflation attack
     *
     * 1. User 0 deposits 1
     * 2. User 0 donates 100 * 1e18
     * 3. User 1 deposits 100 * 1e18 -> 0 shares minted
     * 4. User 0 withdraws 200 * 1e18 + 1
     *
     *    | balance        | User 0 shares | user 1 shares | total supply |
     * 1. |              1 |             1 |             0 |            1 |
     * 2. | 100 * 1e18 + 1 |             1 |             0 |            1 |
     * 3. | 200 * 1e18 + 1 |             1 |             0 |            1 |
     * 4. |              0 |             0 |             0 |            0 |
     *
     *  User 1 shares = 100 * 1e18 * 1 / (100 * 1e18 + 1) = 0
     */

    function deposit(uint256 _amount) external {
        /**
         * a = amount
         * B = balance of token before deposit
         * T = Total supply
         * s = shares to mint
         *
         * (T + s) / T = (a + B) / B
         *
         * s = aT / B
         */

        uint256 shares;
        if (totalSupply == 0) {
            shares = _amount;
        } else {
            shares = (_amount * totalSupply) / token.balanceOf(address(this));
        }

        _mint(msg.sender, shares);
        token.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint256 _shares) external returns (uint256) {
        /**
         * a = amount
         * B = balance of token before deposit
         * T = Total supply
         * s = shares to mint
         *
         * (T - s) / T = (B - a) / B
         *
         * a = sB / T
         */

        uint256 amount = (_shares * token.balanceOf(address(this))) / totalSupply;
        _burn(msg.sender, _shares);
        token.transfer(msg.sender, amount);
        return amount;
    }
}
