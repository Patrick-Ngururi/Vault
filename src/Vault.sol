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

    function _mint(address _to, uint256 _shares) private {
        totalSupply += _shares;
        balanceOf[_to] += _shares;
    }

    function _burn(address _from, uint256 _shares) private {
        totalSupply -= _shares;
        balanceOf[_from] -= _shares;
    }

    // Inflation attack //
    // 1. User 0 deposits 1
    // 2. User 0 donates 100 * 1e18
    // 3. User 1 deposits 100 * 1e18 -> 0 shares minted
    // 4. User 0 withdraws 200 * 1e18 + 1
    //
    // user 1 shares = 100 * 1e18 * 1 / (100 * 1e18 + 1)
    //               = 0
    //
    //    | balance        | user 0 shares | user 1 shares | total supply |
    // 1. |              1 |             1 |             0 |            1 |
    // 2. | 100 * 1e18 + 1 |             1 |             0 |            1 |
    // 3. | 200 * 1e18 + 1 |             1 |             0 |            1 |
    // 4. |              0 |             0 |             0 |            0 |

    // Protections //
    // - Min shares -> protection from front running
    // - Internal balance -> protection from donation
    // - Dead shares -> contract is first depositor
    // - Decimal offset (OpenZeppelin ERC4626)

    function deposit(uint256 amount) external {
        uint256 shares;
        if (totalSupply == 0) {
            shares = amount;
        } else {
            shares = (amount * totalSupply) / token.balanceOf(address(this));
        }

        _mint(msg.sender, shares);
        token.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 shares) external returns (uint256) {
        uint256 amount = (shares * token.balanceOf(address(this))) / totalSupply;
        _burn(msg.sender, shares);
        token.transfer(msg.sender, amount);
        return amount;
    }

    function previewRedeem(uint256 shares) external view returns (uint256) {
        if (totalSupply == 0) {
            return 0;
        }
        return (shares * token.balanceOf(address(this))) / totalSupply;
    }
}
