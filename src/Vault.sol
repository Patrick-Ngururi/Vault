// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import {IERC20} from "./ERC20.sol";

contract Vault {
    IERC20 public immutable token;

    uint public totalSupply;
    mapping (address => uint) public  balanceOf;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function _mint(address _to, uint _amount) private {
        totalSupply += _amount;
        balanceOf[_to] += amount;
    }

    function _burn(address _from, uint _amount) private {
        totalSupply -= _amount;
        balanceOf[_to] -= amount;
    }

    function deposit(uint _amount) external {
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

        uint shares;
        if (totalSupply == 0) {
            shares = amount;
        } else {
            shares = (_amount * totalSupply) / token.balanceOf(address(this));
        }

        _mint(msg.sender, shares);
        token.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint _shares) external {
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

        uint amount = (_shares * token.balanceOf(address(this))) / totalSupply;
        _burn(msg.sender, _shares);
        token.transfer(msg.sender, amount);
         
    }
}