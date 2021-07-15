import { test } from '@playwright/test';
import { assert } from '../assert';
import { setupPage } from '../pw-helpers/setup-page';
import { Auth } from '../screens/auth';
import { StakingScreen } from '../screens/staking';
import { WalletsScreen } from '../screens/wallets';
import { data, getWalletURL } from '../test-data';

let auth: Auth;
let walletsScreen: WalletsScreen;
let stakingScreen: StakingScreen;

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
    test('Create staking account', async ({ page }) => {
      const initialAmountOfStakingAccounts = await stakingScreen.getAmountOfStakes('to_delegate');
      await page.click('" Create Account"');
      await page.fill('.input-area input', '1');
      await page.click('#prompt-confirm');
      await page.waitForSelector('" Account created and funds deposited"', { timeout: 10000 });
      await page.click('#notification-close');

      // for some reason new stake does not appear in the list immediately
      const finalAmountOfStakingAccounts = await stakingScreen.waitForStakesAmountUpdated(initialAmountOfStakingAccounts, 'to_delegate');
      assert.equal(finalAmountOfStakingAccounts, initialAmountOfStakingAccounts + 1);
    });

    test('Delegate stake', async ({ page }) => {
      const initialAmountOfDelegatedStakes = await stakingScreen.getAmountOfStakes('to_undelegate');
      await stakingScreen.clickDelegate();
      assert.isFalse(await page.isVisible('#choosen-pull'));
      await page.click('.staking-content.delegate button');
      await page.click('#choosen-pull button span:text(" Apply")');
      const alertText = await (await page.waitForSelector('.confirmation .text', { timeout: 10000 })).textContent();
      assert.include(alertText, 'Funds delegated to');
      await page.click('" Ok"');
      const finalAmountOfDelegatedStakes = await stakingScreen.waitForStakesAmountUpdated(initialAmountOfDelegatedStakes, 'to_undelegate');
      assert.equal(finalAmountOfDelegatedStakes, initialAmountOfDelegatedStakes + 1);
    });

    test('Undelegate stake', async ({ page }) => {
      const initialToUndelegateStakesAmount = await stakingScreen.getAmountOfStakes('to_undelegate');
      const initialToDelegateStakesAmount = await stakingScreen.getAmountOfStakes('to_delegate');
      await stakingScreen.clickUndelegate();
      await page.click('" Confirm"');
      await page.waitForSelector('" Funds undelegated successfully"');
      await page.click('" Ok"');
      const finalToUndelegateStakesAmount = await stakingScreen.waitForStakesAmountUpdated(initialToUndelegateStakesAmount, 'to_undelegate');
      assert.equal(finalToUndelegateStakesAmount, initialToUndelegateStakesAmount - 1, 'Amount of stakes to undelegate has not changed after undelegation');
      assert.equal(await stakingScreen.getAmountOfStakes('to_delegate'), initialToDelegateStakesAmount + 1, 'Amount of stakes to withdraw has not changed after undelegation');
    });

    test('Withdraw stake', async ({ page }) => {
      const initialAmountOfStakingAccounts = await stakingScreen.getAmountOfStakes('all');
      await stakingScreen.selectAccount('to_delegate');
      await page.click('button span:text(" Withdraw")');
      await page.click('" Confirm"');
      await page.waitForSelector('" Funds withdrawn successfully"');
      await page.click('" Ok"');
      const finalAmountOfStakingAccounts = await stakingScreen.waitForStakesAmountUpdated(initialAmountOfStakingAccounts, 'all');

      assert.equal(finalAmountOfStakingAccounts, initialAmountOfStakingAccounts - 1);
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