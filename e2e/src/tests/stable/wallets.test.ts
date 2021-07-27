import { test } from '@playwright/test';
import { VelasNative } from '@velas/velas-chain-test-wrapper';
import { assert } from '../../assert';
import { setupPage } from '../../pw-helpers/setup-page';
import { Auth } from '../../screens/auth';
import { Currency, WalletsScreen } from '../../screens/wallets';
import { data, getWalletURL } from '../../test-data';

let auth: Auth;
const velasNativeChain = new VelasNative();
let walletsScreen: WalletsScreen;

test.describe('Wallets screen >', () => {
  test.beforeEach(async ({ page }) => {
    setupPage(page);
    auth = new Auth(page);
    walletsScreen = new WalletsScreen(page);
    await page.goto(getWalletURL({ testnet: true }));
  });

  test.describe('Transactions >', () => {
    test('Transactions list is displayed', async ({ page }) => {
      // arrange
      await auth.loginByRestoringSeed(data.wallets.fundsReceiver.seed);

      await walletsScreen.selectWallet('Velas Native');
      await page.waitForSelector('.history-area div[datatesting="transaction"]', { timeout: 20000 });
      const transactions = await page.$$('.history-area div[datatesting="transaction"]');
      assert.isAbove(transactions.length, 10, 'Amount of transactions in the list is less than 10');

      const senderAddressSelector = `.history-area div[datatesting="transaction"] .address-holder a[href="https://native.velas.com/address/${data.wallets.txSender.address}?cluster=testnet"]`;
      assert.ok(await page.waitForSelector(senderAddressSelector));
    });
  });

  test('Lock and unlock', async ({ page }) => {
    await auth.loginByRestoringSeed(data.wallets.login.seed);
    await page.click('.menu-item.bottom');
    assert.isTrue(await page.isVisible('input[type="password"]'));
    assert.isFalse(await page.isVisible('.menu-item.bottom'));

    await auth.pinForLoggedOutAcc.typeAndConfirm('111222');
    assert.isTrue(await auth.isLoggedIn());
  });

  test('Add and hide litecoin wallet', async () => {
    await auth.loginByRestoringSeed(data.wallets.login.seed);

    // add litecoin
    await walletsScreen.addWalletsPopup.open();
    await walletsScreen.addWalletsPopup.add('Litecoin');
    await walletsScreen.selectWallet('Litecoin');
    assert.isTrue(await walletsScreen.isWalletInWalletsList('Litecoin'));

    // remove litecoin
    await walletsScreen.hideWallet();
    assert.isFalse(await walletsScreen.isWalletInWalletsList('Litecoin'));
  });

  test('Switch account', async ({ page }) => {
    await auth.loginByRestoringSeed(data.wallets.login.seed);
    await walletsScreen.waitForWalletsDataLoaded();

    await page.click('.switch-account');
    await page.click('" Account 2"');
    assert.equal(await walletsScreen.getWalletAddress(), 'VEzaTJxJ4938MyHRDP5YSSUYAriPkvFbha', 'Account 2 address on UI does not equal expected');
  });

  test('Show QR', async ({ page }) => {
    await auth.loginByRestoringSeed(data.wallets.login.seed);
    await walletsScreen.waitForWalletsDataLoaded();

    await page.hover('.wallet-detailed .address-holder .copy');
    await page.waitForSelector('.qrcode');
  });

  test.describe('Balance >', () => {
    test.beforeEach(async () => {
      await auth.loginByRestoringSeed(data.wallets.withFunds.seed);
      await walletsScreen.waitForWalletsDataLoaded();
    });

    // extract "VLX Native balance update" to separate test
    test('Check VLX, VLX Native and Bitcoin balances', async () => {
      const balances = await walletsScreen.getWalletsBalances();

      const wallets = Object.keys(balances) as Currency[];

      for (let i = 0; i < wallets.length; i++) {
        const currency = wallets[i];
        const VLXNativeBalanceOnBlockchain = (await velasNativeChain.getBalance(data.wallets.withFunds.address)).VLX;
        const balanceUpdateAmount = 0.001;
        const amountOfTokens = balances[currency];

        // if no balance – skip currency
        if (amountOfTokens === null) continue;

        switch (wallets[i]) {
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
            // const newAmountOfTokens = Number(await (await walletElement.$('.info .token.price'))?.getAttribute('title')).toFixed(6);
            const newAmountOfTokens = Number((await walletsScreen.getWalletsBalances())['Velas Native'])?.toFixed(6);
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
});
