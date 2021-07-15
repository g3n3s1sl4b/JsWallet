import { test } from '@playwright/test';
import { assert } from '../assert';
import { setupPage } from '../pw-helpers/setup-page';
import { Auth } from '../screens/auth';
import { WalletsScreen } from '../screens/wallets';
import { data, getWalletURL } from '../test-data';
import { log } from '../tools/logger';

let walletsScreen: WalletsScreen;
let auth: Auth;

test.describe('Settings', () => {
  test.beforeEach(async ({ page }) => {
    setupPage(page);
    walletsScreen = new WalletsScreen(page);
    auth = new Auth(page);
    await page.goto(getWalletURL({testnet: true}));
    await auth.loginByRestoringSeed(data.wallets.login.seed);
  });

  test('Copy private key', async ({ context, page }) => {
    // arrange
    await context.grantPermissions(["clipboard-read", "clipboard-write"]);
    // clear clipboard
    await page.evaluate(async () => await navigator.clipboard.writeText(''));

    await walletsScreen.openMenu('settings');
    await page.click('" Copy"');
    await page.type('[type="password"]', '111222');
    await page.click('#prompt-confirm');
    await page.click('.tokens-drop span:text(" Velas")');
    await page.click('#prompt-confirm');
    await page.click('#notification-close');

    const copiedKey = await page.evaluate(async () => await navigator.clipboard.readText());
    log.info(copiedKey);
    assert.equal(copiedKey, '0xb1d4dcae5b7666408a5f6c229f97bac6856cbc4d5e2a639d535c27411a91d7b0')
  });

  test('Switch account index', async ({ page }) => {
    await walletsScreen.openMenu('settings');
    await page.click('.button.right');
    await walletsScreen.openMenu('wallets');
    
    await walletsScreen.waitForWalletsDataLoaded();
    //await page.pause();
    assert.equal(await walletsScreen.getWalletAddress(), 'VEzaTJxJ4938MyHRDP5YSSUYAriPkvFbha', 'Account 2 address on UI does not equal expected');
  });

  test.describe.only('Switch testnet', () => {
    test('Enable/Disable', async ({ page }) => {
      await walletsScreen.waitForWalletsDataLoaded();
      await walletsScreen.selectWallet('Bitcoin');
      assert.equal(await walletsScreen.getWalletAddress(), 'n415iSKJwmoSZXTWYb6VqNSNTSA1YMwL8U', 'Mainnet BTC address on UI does not equal expected');
      await walletsScreen.openMenu('settings');
      assert.isTrue(await page.isVisible('#menu-testnet'));

      await walletsScreen.openMenu('settings');
      await page.click('.active-network');
      assert.isFalse(await page.isVisible('#menu-testnet'));
      await walletsScreen.openMenu('wallets');
      await walletsScreen.waitForWalletsDataLoaded();
      assert.equal(await walletsScreen.getWalletAddress(), '1PV8RPEL8kNBnQytq2881TE3bSZJbJazDw', 'Testnet BTC address on UI does not equal expected');
    });
  });
});
