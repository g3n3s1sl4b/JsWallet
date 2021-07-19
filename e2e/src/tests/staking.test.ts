import { test } from '@playwright/test';
import { assert } from '../assert';
import { setupPage } from '../pw-helpers/setup-page';
import { Auth } from '../screens/auth';
import { StakingScreen } from '../screens/staking';
import { WalletsScreen } from '../screens/wallets';
import { data, getWalletURL } from '../test-data';
import { VelasNative } from '@velas/velas-chain-test-wrapper';

let auth: Auth;
let walletsScreen: WalletsScreen;
let stakingScreen: StakingScreen;
const velasNative = new VelasNative();

test.describe('Staking', () => {
  test.beforeEach(async ({ page }) => {
    setupPage(page);
    auth = new Auth(page);
    walletsScreen = new WalletsScreen(page);
    stakingScreen = new StakingScreen(page);
    await page.goto(getWalletURL({ testnet: true }));
    await auth.loginByRestoringSeed(data.wallets.staking.staker.seed);
    await walletsScreen.openMenu('staking');
  });

  test.describe('Actions', () => {
    const stakingAmount = 1;

    test('Create staking account', async ({ page }) => {
      const VLXNativeAddress = '59vpQgPoDEhux1G84jk6dbbARQqfUwYtohLU4fgdxFKG';

      const initialAmountOfStakingAccounts = await stakingScreen.getAmountOfStakes('to_delegate');
      const stakingAccountAddresses = await stakingScreen.getStakingAccountsAddresses();
      const initialWalletBalance = Number((await velasNative.getBalance(VLXNativeAddress)).VLX.toFixed(0));

      await page.click('" Create Account"');
      await page.fill('.input-area input', String(stakingAmount));
      await page.click('#prompt-confirm');
      await page.waitForSelector('" Account created and funds deposited"', { timeout: 10000 });
      await page.click('#notification-close');

      // for some reason new stake does not appear in the list immediately
      const finalAmountOfStakingAccounts = await stakingScreen.waitForStakesAmountUpdated(initialAmountOfStakingAccounts, 'to_delegate');
      assert.equal(finalAmountOfStakingAccounts, initialAmountOfStakingAccounts + stakingAmount);

      const newlyAddedStakingAccountAddress = (await stakingScreen.getStakingAccountsUpdate(stakingAccountAddresses))?.added;
      if (!newlyAddedStakingAccountAddress) throw new Error('No new staking account appears in the list');

      // assert VLXNative balance decreases on staking amount
      const finalWalletBalance = Number((await velasNative.getBalance(VLXNativeAddress)).VLX.toFixed(0));
      assert.equal(finalWalletBalance, initialWalletBalance - stakingAmount);

      // check newly created staking account on blockchain
      await stakingScreen.makeSureStakingAccIsCreatedAndNotDelegated(newlyAddedStakingAccountAddress);
      assert.equal((await velasNative.getBalance(newlyAddedStakingAccountAddress)).VLX.toFixed(0), String(stakingAmount));
    });

    test('Delegate stake', async ({ page }) => {
      const initialAmountOfDelegatedStakes = await stakingScreen.getAmountOfStakes('to_undelegate');
      const stakeAccountAddress = await stakingScreen.getFirstStakingAccountAddressFromTheList('to_delegate');

      await stakingScreen.clickDelegate();
      assert.isFalse(await page.isVisible('#choosen-pull'));
      await page.click('.staking-content.delegate button');
      await page.click('#choosen-pull button span:text(" Apply")');
      const alertText = await (await page.waitForSelector('.confirmation .text', { timeout: 10000 })).textContent();
      assert.include(alertText, 'Funds delegated to');
      await page.click('" Ok"');
      const finalAmountOfDelegatedStakes = await stakingScreen.waitForStakesAmountUpdated(initialAmountOfDelegatedStakes, 'to_undelegate');
      assert.equal(finalAmountOfDelegatedStakes, initialAmountOfDelegatedStakes + 1);

      const stakeAccOnBlockchain = await velasNative.getStakeAccount(stakeAccountAddress);
      assert.equal(stakeAccOnBlockchain.active, 0);
      assert.equal(stakeAccOnBlockchain.inactive, stakingAmount * 10 ** 9);
      assert.equal(stakeAccOnBlockchain.state, 'activating');
    });

    test('Undelegate stake', async ({ page }) => {
      const initialToUndelegateStakesAmount = await stakingScreen.getAmountOfStakes('to_undelegate');
      const initialToDelegateStakesAmount = await stakingScreen.getAmountOfStakes('to_delegate');
      const stakeAccountAddress = await stakingScreen.getFirstStakingAccountAddressFromTheList('to_delegate');

      await stakingScreen.clickUndelegate();
      await page.click('" Confirm"');
      await page.waitForSelector('" Funds undelegated successfully"');
      await page.click('" Ok"');
      const finalToUndelegateStakesAmount = await stakingScreen.waitForStakesAmountUpdated(initialToUndelegateStakesAmount, 'to_undelegate');
      assert.equal(finalToUndelegateStakesAmount, initialToUndelegateStakesAmount - 1, 'Amount of stakes to undelegate has not changed after undelegation');
      assert.equal(await stakingScreen.getAmountOfStakes('to_delegate'), initialToDelegateStakesAmount + 1, 'Amount of stakes to withdraw has not changed after undelegation');

      const stakeAccOnBlockchain = await velasNative.getStakeAccount(stakeAccountAddress);
      assert.equal(stakeAccOnBlockchain.active, 0);
      assert.equal(stakeAccOnBlockchain.inactive, stakingAmount * 10 ** 9);
      assert.equal(stakeAccOnBlockchain.state, 'inactive');
    });

    test('Withdraw stake', async ({ page }) => {
      const stakingAccountAddresses = await stakingScreen.getStakingAccountsAddresses();
      const initialAmountOfStakingAccounts = await stakingScreen.getAmountOfStakes('all');
      const stakeAccountAddress = await stakingScreen.getFirstStakingAccountAddressFromTheList('to_delegate');

      await stakingScreen.selectAccount('to_delegate');
      await page.click('button span:text(" Withdraw")');
      await page.click('" Confirm"');
      await page.waitForSelector('" Funds withdrawn successfully"');
      await page.click('" Ok"');
      const finalAmountOfStakingAccounts = await stakingScreen.waitForStakesAmountUpdated(initialAmountOfStakingAccounts, 'all');

      assert.equal(finalAmountOfStakingAccounts, initialAmountOfStakingAccounts - 1);

      await stakingScreen.makeSureStakingAccountDoesNotExist(stakeAccountAddress);
      const withdrawedStakeAccountAddress = (await stakingScreen.getStakingAccountsUpdate(stakingAccountAddresses))?.removed;
      assert.equal(withdrawedStakeAccountAddress, stakeAccountAddress);
    });

    // test('Split stake', async ({ page }) => {
    //   await page.waitForTimeout(1);
    // });
  });

  // test.describe('Validators', () => {
  //   test('1', async ({ page }) => {
  //     '.validator-item'
  //   });
  // });

  // test.describe('Delegate, withdrap, split', () => {
  //   test('1', async ({ page }) => {
  //   });
  // });

  // test.describe('Swap', () => {
  //   test('1', async ({ page }) => {
  //   });
  // });
});

// page.on('response', async (response) => {
//   console.log('<<', response.status(), response.url());
//   promisesList.push(response.body());
//   const body = (await response.body()).toString();
//   log.info(body);
//   log.warn('-----------------------');
// });
