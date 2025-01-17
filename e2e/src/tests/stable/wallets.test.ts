import { test } from '@playwright/test';
import { assert } from '../../assert';
import { config, walletURL } from '../../config';
import { setupPage } from '../../pw-helpers/setup-page';
import { Auth } from '../../screens/auth';
import { WalletsScreen } from '../../screens/wallets';
import { data } from '../../test-data';

let auth: Auth;
let walletsScreen: WalletsScreen;

test.describe.parallel('Wallets screen >', () => {
  test.beforeEach(async ({ page }) => {
    setupPage(page);
    auth = new Auth(page);
    walletsScreen = new WalletsScreen(page);
    await page.goto(walletURL, { waitUntil: 'networkidle' });
  });

  test.describe('Transactions', () => {
    test('Transactions list is displayed', async ({ page }) => {
      // arrange
      await auth.loginByRestoringSeed(data.wallets.fundsReceiver.seed);

      await walletsScreen.selectWallet('token-vlx_native');
      await page.waitForSelector('.history-area div[datatesting="transaction"]', { timeout: 20000 });
      const transactions = await page.$$('.history-area div[datatesting="transaction"]');
      assert.isAbove(transactions.length, 10, 'Amount of transactions in the list is less than 10');

      const prodSenderAddress = '46LegTMYJ7ZYLftiCv3Ldzzud3dwajrV6S1oonF5wqFV';
      const senderAddressSelector = `.history-area div[datatesting="transaction"] .address-holder a[href*="https://native.velas.com/address/${config.network === 'mainnet' ? prodSenderAddress : data.wallets.txSender.address}"]`;
      assert.ok(await page.waitForSelector(senderAddressSelector));
    });
  });

  test.describe(' > ', () => {
    test.beforeEach(async () => {
      await auth.loginByRestoringSeed(data.wallets.login.seed);
      await walletsScreen.waitForWalletsDataLoaded();
    });

    test('Lock and unlock', async ({ page }) => {
      await page.click('.menu-item.bottom');
      assert.isTrue(await page.isVisible('input[type="password"]'));
      assert.isFalse(await page.isVisible('.menu-item.bottom'));

      await auth.pinForLoggedOutAcc.typeAndConfirm('111222');
      assert.isTrue(await auth.isLoggedIn());
    });

    test('Add and hide litecoin wallet', async () => {
      // TODO: need to scroll to launch test for mainnet
      // add litecoin
      await walletsScreen.addWalletsPopup.open();
      await walletsScreen.addWalletsPopup.add('token-ltc');
      await walletsScreen.selectWallet('token-ltc');
      assert.isTrue(await walletsScreen.isWalletInWalletsList('token-ltc'));

      // remove litecoin
      await walletsScreen.hideWallet();
      assert.isFalse(await walletsScreen.isWalletInWalletsList('token-ltc'));
    });

    test('Switch account', async ({ page }) => {
      await walletsScreen.selectWallet('token-vlx_native');
      await page.click('.switch-account');
      await page.click('" Account 2"');
      assert.equal(await walletsScreen.getWalletAddress(), 'BfGhk12f68mBGz5hZqm4bDSDaTBFfNZmegppzVcVdGDW', 'Account 2 address on UI does not equal expected');
    });

    test('Show QR', async ({ page }) => {
      await page.hover('.wallet-detailed .address-holder .copy');
      await page.waitForSelector('.qrcode');
    });

    test('Copy wallet address from "Receive" page', async ({ context, page }) => {
      await context.grantPermissions(['clipboard-read', 'clipboard-write']);
      // clear clipboard
      await page.evaluate(async () => await navigator.clipboard.writeText(''));

      await walletsScreen.selectWallet('token-vlx_native');
      await page.click('#wallets-receive');
      await page.waitForSelector('.ill-qr img');
      // qr code is displayed
      assert.isTrue(await page.isVisible('.receive-body canvas'));

      // copy to clipboard
      await page.click('.address-holder .copy');
      const copiedText = await page.evaluate(async () => await navigator.clipboard.readText());
      assert.equal(copiedText, 'G3N4212jLtDNCkfuWuUHsyG2aiwMWQLkeKDETZbo4KG');

      // back to wallets list
      await page.click('" Cancel"');
      await walletsScreen.waitForWalletsDataLoaded();
    });
  });
});
