import { test } from '@playwright/test';
import { assert } from '../assert';
import { setupPage } from '../pw-helpers/setup-page';
import { Auth } from '../screens/auth';
import { WalletsScreen } from '../screens/wallets';
import { data, getWalletURL } from '../test-data';
import { log } from '../tools/logger';
import { VelasNative } from '@velas/velas-chain-test-wrapper';
import velasTestnet from '../api/velas-testnet/rpc';

let auth: Auth;
let walletsScreen: WalletsScreen;
const velasNativeChain = new VelasNative();

test.describe('Swap: ', () => {
  test.beforeEach(async ({ page }) => {
    setupPage(page);
    walletsScreen = new WalletsScreen(page);
    auth = new Auth(page);
    await page.goto(getWalletURL({ testnet: true }));
    await auth.loginByRestoringSeed(data.wallets.swap.seed);
  });

  test('VLX > Native', async ({ page }) => {
    await walletsScreen.waitForWalletsDataLoaded();
    const vlxSenderInitialBalance = (await walletsScreen.getWalletsBalances())['Velas'];
    const nativeReceiverInitialBalance = await velasNativeChain.getBalance(data.wallets.swap.address);
    const transactionAmount = 0.0001;

    await walletsScreen.swapTokens('Velas', 'Velas Native', transactionAmount);
    await walletsScreen.openMenu('wallets');

    const previousTx = (await velasTestnet.getConfirmedTransactionsForAddress(data.wallets.swap.address)).signatures[0];
    let currentTx = previousTx;

    while (previousTx === currentTx){
      log.warn('No new transactions in the chain, wait and retry...');
      await page.waitForTimeout(1000);
      currentTx = (await velasTestnet.getConfirmedTransactionsForAddress(data.wallets.swap.address)).signatures[0];
    }
    log.warn(currentTx);

    await walletsScreen.waitForWalletsDataLoaded();

    const vlxSenderFinalBalance = (await walletsScreen.getWalletsBalances())['Velas'];
    assert.isBelow(Number(vlxSenderFinalBalance), Number(vlxSenderInitialBalance) - transactionAmount);
    
    const nativeReceiverFinalBalance = await velasNativeChain.getBalance(data.wallets.swap.address);
    assert.equal(Number(nativeReceiverFinalBalance.VLX).toFixed(6), Number(nativeReceiverInitialBalance.VLX + transactionAmount).toFixed(6));

  });
});
