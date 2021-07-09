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
    await auth.loginByRestoringSeed(data.wallets.fundsReceiver.seed);
  });

  test('Transactions', async ({ page }) => {
    await walletsScreen.selectWallet('Velas Native');
    await page.waitForSelector('.history-area div[datatesting="transaction"]', { timeout: 10000 });
    const transactions = await page.$$('.history-area div[datatesting="transaction"]');
    assert.isAbove(transactions.length, 10, 'Amount of transactions in the list is less than 10');
    const senderAddressSelector = '.history-area div[datatesting="transaction"] .address-holder a:text(" Dawj15q13fqzh4baHqmD2kbrRCyiFfkE6gkPcUZ21KUS")';
    assert.isTrue(await page.isVisible(senderAddressSelector));
  });
});

