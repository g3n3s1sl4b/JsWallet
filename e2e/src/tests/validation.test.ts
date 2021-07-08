import { test } from '@playwright/test';
import { assert } from '../assert';
import { Auth } from '../screens/auth';
import { WalletsScreen } from '../screens/wallets';
import { data, getWalletURL } from '../test-data';
import { setupPage } from '../pw-helpers/setup-page';

let walletsScreen: WalletsScreen;
let auth: Auth;

test.describe('Settings', () => {
  test.beforeEach(async ({ page }) => {
    setupPage(page);
    auth = new Auth(page);
    walletsScreen = new WalletsScreen(page);
    await page.goto(getWalletURL({ testnet: true }));
    await auth.loginByRestoringSeed(data.wallets.withFunds.seed);
  });

  test('Show Invalid Address error', async ({ page }) => {
    await page.waitForSelector('#wallets-send', {timeout: 10000});
    await page.click('#wallets-send');
    await page.fill('#send-recipient', 'invalid data');
    assert.isTrue(await page.isVisible('[title="Given address is not valid Velas address"]'));

    await page.fill('#send-recipient', 'VAP73ARS1UXPr3jDHSzNZdss6dAudsg15U');
    assert.isFalse(await page.isVisible('[title="Given address is not valid Velas address"]'));
  });

  test.only('Show Not Enough Funds error', async ({ page }) => {
    await page.click('#wallets-send');
    await page.fill('#send-recipient', 'VAP73ARS1UXPr3jDHSzNZdss6dAudsg15U');

    await page.fill('div.amount-field .textfield[label="Send"]', '99999999');
    //wait for balance to be compared with amount by checking if send button got blocked 
    await page.waitForSelector('#send-confirm[disabled]');
    assert.isTrue(await page.isVisible('[title="Not Enough Funds"]'));

    //remove step after bug fix
    //keeps showing error after clicking use-max if the field was not cleared
    await page.fill('div.amount-field .textfield[label="Send"]', '');

    await page.click('#send-max');
    await page.waitForTimeout(1000);
    assert.isFalse(await page.isVisible('[title="Not Enough Funds"]'));
  });
});
