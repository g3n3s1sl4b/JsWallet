import { test } from '@playwright/test';
import { assert } from '../../assert';
import { setupPage } from '../../pw-helpers/setup-page';
import { Auth } from '../../screens/auth';
import { WalletsScreen } from '../../screens/wallets';
import { data, getWalletURL } from '../../test-data';

let auth: Auth;
let walletsScreen: WalletsScreen;

test.describe('ETH transactions >', () => {
  test.beforeEach(async ({ page }) => {
    setupPage(page);
    auth = new Auth(page);
    walletsScreen = new WalletsScreen(page);
    await page.goto(getWalletURL({ testnet: true }, {env: 'testnet'}));
    await auth.loginByRestoringSeed(data.wallets.txSender.seed);
    await walletsScreen.waitForWalletsDataLoaded();
  });

  test('Send ETH', async ({ page }) => {
    await walletsScreen.addWalletsPopup.open();
    await walletsScreen.addWalletsPopup.add('Ethereum');
    await walletsScreen.waitForWalletsDataLoaded();
    
    const transactionAmount = 0.00001;

    await walletsScreen.selectWallet('Ethereum');
    await page.click('#wallets-send');
    await page.fill('#send-recipient', '0xb322f01cb6a191974e7291600a4dc1b46f00f752'); //accound with index 2
    await page.type('div.amount-field input[label="Send"]', String(transactionAmount));
    await page.click('#send-confirm');
    await page.click('#confirmation-confirm');

    const txSignatureLink = String(await page.getAttribute('.sent .text a', 'href'));
    assert.isTrue(txSignatureLink.includes('https://ropsten.etherscan.io/'));
  });
});
