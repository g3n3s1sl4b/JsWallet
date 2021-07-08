import { test } from '@playwright/test';
import { VelasNative } from '@velas/velas-chain-test-wrapper';
import { assert } from '../assert';
import { setupPage } from '../pw-helpers/setup-page';
import { Auth } from '../screens/auth';
import { WalletsScreen } from '../screens/wallets';
import { data, getWalletURL } from '../test-data';

let auth: Auth;
let walletsScreen: WalletsScreen;
const velasNativeChain = new VelasNative();

test.describe('Transactions', () => {
  test.describe('Sign up', () => {
    test.beforeEach(async ({ page }) => {
      setupPage(page);
      auth = new Auth(page);
      walletsScreen = new WalletsScreen(page);
      await page.goto(getWalletURL({ testnet: true }));
      await auth.loginByRestoringSeed(data.wallets.withFunds.seed);

    });

    test('Send VLX native', async ({ page }) => {
      const receiverInitialBalance = await velasNativeChain.getBalance(data.wallets.fundsReceiver.address);
      const senderInitialBalance = await velasNativeChain.getBalance(data.wallets.withFunds.address);
      const transactionAmount = 0.0001;

      await walletsScreen.selectWallet('Velas Native');
      await page.click('#wallets-send');
      await page.fill('#send-recipient', 'FJWtmzRwURdnrgn5ZFWvYNfHvXMtHK1WS7VHpbnfG73s');
      await page.type('div.amount-field input[label="Send"]', String(transactionAmount));
      await page.click('#send-confirm');
      await page.click('#confirmation-confirm');

      await page.waitForSelector('" Transaction"');
      await page.waitForSelector('"  has been sent"');
      await page.waitForSelector('"  in progress.."', { timeout: 15000 });

      await page.waitForSelector('"  has been sent"', { timeout: 30000 });
      // TODO: change previous line to the next one after fix 
      // await page.waitForSelector('"  has been confirmed"', { timeout: 20000 });

      // expand tx info
      await page.click('[datatesting="transaction"] div.more');

      const txHashElementSelector = '[datatesting="transaction"] .tx-middle .txhash a[data-original]';
      const txSignature = (await page.getAttribute(txHashElementSelector, 'data-original'))?.trim();
      if (!txSignature) throw new Error(`Cannot get transaction signature from element with selector '${txHashElementSelector}'`)

      const receiverAddress = (await page.getAttribute('[datatesting="transaction"] .address-holder a[data-original]', 'data-original'))?.trim();
      assert.equal(receiverAddress, data.wallets.fundsReceiver.address);

      const tx = await velasNativeChain.getTransaction(txSignature);
      assert.exists(tx);

      const receiverFinalBalance = await velasNativeChain.getBalance(data.wallets.fundsReceiver.address);
      assert.equal(receiverFinalBalance.VLX, receiverInitialBalance.VLX + transactionAmount);
      const senderFinalBalance = await velasNativeChain.getBalance(data.wallets.withFunds.address);
      assert.isBelow(senderFinalBalance.VLX, senderInitialBalance.VLX - transactionAmount, 'Final sender balance is not below the initial sender balance');
    });
  });
});
