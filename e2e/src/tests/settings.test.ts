import { assert } from '../mocha-wrapper/assert';
import { PW } from '../playwright-helpers';
import { Auth } from '../screens/auth';
import { MainScreen } from '../screens/wallets';
import { data, walletURL } from '../test-data';
import { log } from '../tools/logger';
import { Browser, BrowserContext, Page } from '../types';

describe('Settings', function () {
  let browser: Browser;
  let context: BrowserContext;
  let page: Page;
  let auth: Auth;
  let pw: PW;
  let mainScreen: MainScreen;

  async function clearClipboard() {
    await page.evaluate(async () => await navigator.clipboard.writeText(''));
  }

  before(async function () {
    pw = new PW();
    ({ browser, context, page } = await pw.init());
    auth = new Auth(page);
    mainScreen = new MainScreen(page);
  });

  after(async function () {
    await browser.close();
  });

  it('Copy private key', async function () {
    // arrange
    await page.goto(walletURL);
    await auth.loginByRestoringSeed(data.seedPhrase);
    await context.grantPermissions(["clipboard-read", "clipboard-write"]);
    await clearClipboard();

    await mainScreen.openMenu('settings');
    await page.click('" Copy"');
    await page.type('[type="password"]', '111222');
    await page.click('#prompt-confirm');
    await page.click('.tokens-drop li:nth-of-type(1)');
    await page.click('#prompt-confirm');
    await page.click('#notification-close');

    const copiedKey = await page.evaluate(async () => await navigator.clipboard.readText());
    log.info(copiedKey);
    assert.equal(copiedKey, '0xb1d4dcae5b7666408a5f6c229f97bac6856cbc4d5e2a639d535c27411a91d7b0');
  });

  describe('Switch testnet', function () {
    before(async function () {
      page = await pw.getPage();
      mainScreen = new MainScreen(page);
      auth = new Auth(page);
      await page.goto(walletURL);
      await auth.loginByRestoringSeed(data.seedPhrase);
    });
    
    it('Enable', async function () {
      await mainScreen.waitForWalletsDataLoaded();
      await mainScreen.selectWallet('Bitcoin');
      await mainScreen.openMenu('settings');
      await page.click('.active-network');
      await mainScreen.openMenu('wallets');

      assert.equal(await mainScreen.getWalletAddress(), 'n415iSKJwmoSZXTWYb6VqNSNTSA1YMwL8U', 'Testnet BTC address on UI does not equal expected');
      await mainScreen.openMenu('settings');
      assert.isTrue(await page.isVisible('#menu-testnet'));
    });

    it('Disable', async function () {
      await page.click('.active-network');
      await mainScreen.openMenu('wallets');

      assert.equal(await mainScreen.getWalletAddress(), '1PV8RPEL8kNBnQytq2881TE3bSZJbJazDw', 'Mainnet BTC address on UI does not equal expected');
      await mainScreen.openMenu('settings');
      assert.isFalse(await page.isVisible('#menu-testnet'));
    });
  });
});
