import { test } from '@playwright/test';
import { assert } from '../assert';
import { Auth } from '../screens/auth';
import { WalletsScreen } from '../screens/wallets';
import { data, getWalletURL } from '../test-data';
import { setupPage } from '../pw-helpers/setup-page';

let walletsScreen: WalletsScreen;
let auth: Auth;

test.describe('Validation >', () => {
  test.beforeEach(async ({ page }) => {
    setupPage(page);
    auth = new Auth(page);
    walletsScreen = new WalletsScreen(page);
    await page.goto(getWalletURL({ testnet: true }));
    await auth.loginByRestoringSeed(data.wallets.txSender.seed);
    await walletsScreen.waitForWalletsDataLoaded();
  });

  test('VLX Native: Show Invalid Address error', async ({ page }) => {
    await page.click('#wallets-send');
    await page.fill('#send-recipient', 'invalid data');
    await page.waitForSelector('[title="Given address is not valid Velas address"]');

    await page.fill('#send-recipient', 'VAP73ARS1UXPr3jDHSzNZdss6dAudsg15U');
    assert.isFalse(await page.isVisible('[title="Given address is not valid Velas address"]'));
  });

  test('VLX Native: Show Not Enough Funds error', async ({ page }) => {
    await page.click('#wallets-send');
    await page.fill('#send-recipient', 'VAP73ARS1UXPr3jDHSzNZdss6dAudsg15U');

    await page.fill('div.amount-field .textfield[label="Send"]', '99999999');
    // if send button is disabled, we know balance check has been finished
    await page.waitForSelector('#send-confirm[disabled]');
    assert.isTrue(await page.isVisible('[title="Not Enough Funds"]'));

    // need to clear the field because actions are too fast and test fails
    await page.fill('div.amount-field .textfield[label="Send"]', '');
    
    await page.click('#send-max');
    await page.waitForTimeout(1000);    
    assert.isFalse(await page.isVisible('[title="Not Enough Funds"]'));
  });
});
