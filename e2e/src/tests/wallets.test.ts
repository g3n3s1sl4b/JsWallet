import { test } from '@playwright/test';
import { assert } from '../assert';
import { setupPage } from '../pw-helpers/setup-page';
import { Auth } from '../screens/auth';
import { WalletsScreen } from '../screens/wallets';
import { data, getWalletURL } from '../test-data';

let auth: Auth;
let walletsScreen: WalletsScreen;

test.describe('Wallets screen', () => {
  test.beforeEach(async ({ page }) => {
    setupPage(page);
    auth = new Auth(page);
    walletsScreen = new WalletsScreen(page);
    await page.goto(getWalletURL({ testnet: true }));
  });

  test.describe('Transactions', () => {
    test('Transactions list is displayed', async ({ page }) => {
      // arrange
      await auth.loginByRestoringSeed(data.wallets.fundsReceiver.seed);

      await walletsScreen.selectWallet('Velas Native');
      await page.waitForSelector('.history-area div[datatesting="transaction"]', { timeout: 15000 });
      const transactions = await page.$$('.history-area div[datatesting="transaction"]');
      assert.isAbove(transactions.length, 10, 'Amount of transactions in the list is less than 10');
      const senderAddressSelector = '.history-area div[datatesting="transaction"] .address-holder a:text(" Dawj15q13fqzh4baHqmD2kbrRCyiFfkE6gkPcUZ21KUS")';
      assert.isTrue(await page.isVisible(senderAddressSelector));
    });
  });

  test('Lock and unlock', async ({ page }) => {
    await auth.loginByRestoringSeed(data.wallets.login.seed);
    await page.click('.menu-item.bottom');
    assert.isTrue(await page.isVisible('input[type="password"]'));
    assert.isFalse(await page.isVisible('.menu-item.bottom'));

    await auth.pinForLoggedOutAcc.typeAndConfirm('111222');
    assert.isTrue(await auth.isLoggedIn());
  });

  test('Add and hide wallet', async () => {
    await auth.loginByRestoringSeed(data.wallets.login.seed);

    // add litecoin
    await walletsScreen.addWalletsPopup.open();
    await walletsScreen.addWalletsPopup.add('Litecoin');
    await walletsScreen.selectWallet('Litecoin');
    assert.isTrue(await walletsScreen.isWalletInWalletsList('Litecoin'));

    // remove litecoin
    await walletsScreen.hideWallet();
    assert.isFalse(await walletsScreen.isWalletInWalletsList('Litecoin'));
  });

  test('Switch account', async ({ page }) => {
    await auth.loginByRestoringSeed(data.wallets.login.seed);
    await walletsScreen.waitForWalletsDataLoaded();

    await page.click('.switch-account');
    await page.click('" Account 2"');
    assert.equal(await walletsScreen.getWalletAddress(), 'VEzaTJxJ4938MyHRDP5YSSUYAriPkvFbha', 'Account 2 address on UI does not equal expected');
    
  });
});
