import { test } from '@playwright/test';
import { assert } from '../assert';
import { setupPage } from '../pw-helpers/setup-page';
import { Auth} from '../screens/auth';
import { WalletsScreen } from '../screens/wallets';
import { getWalletURL } from '../test-data';
import { log } from '../tools/logger';

let walletsScreen: WalletsScreen;
let auth: Auth;

test.describe('Links', () => {
  test.beforeEach(async ({ page }) => {
    setupPage(page);
    walletsScreen = new WalletsScreen(page);
    auth = new Auth(page);
    await page.goto(getWalletURL({testnet: true}));
  });

  test('Download links are correct', async ({ page }) => {
    //find selectors by id or class when ids added to the page
    const appleLink = await page.getAttribute('.downloadwalletlist a:nth-of-type(1)', 'href');
    const androidLink = await page.getAttribute('.downloadwalletlist a:nth-of-type(2)', 'href');
    assert.isTrue(appleLink?.includes('https://apps.apple.com/'));
    assert.isTrue(androidLink?.includes('https://play.google.com/'));
    
    //find selectors by id or class when ids added to the page
    await page.click('.downloadwalletlist :nth-child(3)');
    await page.waitForSelector('.platforms');
    
    const donwloadLinks = await page.$$('a');
    for (let i=0; i < donwloadLinks.length; i++){
      const linkElement = donwloadLinks[i];
      const downloadLink =  await linkElement.getAttribute('href');
      //delete condition after bugfix VLWA-257
      if (downloadLink !== 'undefined'){
        assert.isTrue(downloadLink?.includes('https://github.com/velas/JsWalletDesktop'), `${await linkElement.textContent()} doesn't lead to correct destination`);
      }
    }
  });
});