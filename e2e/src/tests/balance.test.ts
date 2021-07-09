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

test.describe('Balance', () => {
  test.beforeEach(async ({ page }) => {
    setupPage(page);
    auth = new Auth(page);
    walletsScreen = new WalletsScreen(page);
    await page.goto(getWalletURL({ testnet: true }));
    await auth.loginByRestoringSeed(data.wallets.withFunds.seed);
    await walletsScreen.waitForWalletsDataLoaded();
  });

  test('Check VLX, VLX Native and Bitcoin balances', async ({ page }) => {
    const walletElements = await page.$$('.wallet-item');

    for (let i = 0; i < walletElements.length; i++) {
      const walletElement = walletElements[i];
      const amountOfTokens = await walletsScreen.getAmountOfTokensFromOfWalletItemElement(walletElement);
      const tokenName = await walletsScreen.getTokenNameOfWalletItemElement(walletElement);
      const VLXNativeBalanceOnBlockchain = (await velasNativeChain.getBalance(data.wallets.withFunds.address)).VLX;
      const balanceUpdateAmount = 0.001;
      
      switch (tokenName) {
        case 'Velas':
          assert.equal(amountOfTokens, '1');
          break;
        case 'Velas Native':
          assert.equal(amountOfTokens, String(VLXNativeBalanceOnBlockchain));
          const tx = await velasNativeChain.transfer({
            payerSeed: data.wallets.payer.seed,
            toAddress: data.wallets.withFunds.address,
            lamports: balanceUpdateAmount * 10 ** 9,
          });
          await velasNativeChain.waitForConfirmedTransaction(tx);
          await walletsScreen.updateBalances();
          const newAmountOfTokens = Number(await (await walletElement.$('.info .token.price'))?.getAttribute('title')).toFixed(6);
          assert.equal(newAmountOfTokens, (VLXNativeBalanceOnBlockchain + balanceUpdateAmount).toFixed(6), 'Velas Native wallet balance was not updated after funding it');
          break;
        case 'Bitcoin':
          assert.equal(amountOfTokens, '0.03484302');
          break;
        case 'Velas EVM':
          assert.equal(amountOfTokens, '0.13');
          break;
      }

    }
  });
});

