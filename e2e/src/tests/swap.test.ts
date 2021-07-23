import { test } from '@playwright/test';
import { assert } from '../assert';
import { setupPage } from '../pw-helpers/setup-page';
import { Auth } from '../screens/auth';
import { WalletsScreen } from '../screens/wallets';
import { data, getWalletURL } from '../test-data';
import { log } from '../tools/logger';
import { VelasNative } from '@velas/velas-chain-test-wrapper';
import velasTestnet from "../api/rpc";

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
    const nativeReceiverInitialBalance = await velasNativeChain.getBalance(data.wallets.swap.nativeAddress);
    const transactionAmount = 0.0001;

    const swap = await walletsScreen.swapTokens('Velas', 'Velas Native', transactionAmount);

    let lastTx = (await velasTestnet.getConfirmedTransactionsForAddress(data.wallets.swap.vlxAddress))[0];

    while (swap !== lastTx){
      await page.waitForTimeout(1000);
      lastTx = (await velasTestnet.getConfirmedTransactionsForAddress(data.wallets.swap.vlxAddress))[0];
    }

    const vlxSenderFinalBalance = (await walletsScreen.getWalletsBalances())['Velas'];
    assert.isBelow(Number(vlxSenderFinalBalance), Number(vlxSenderInitialBalance) - transactionAmount);
    
    const nativeReceiverFinalBalance = await velasNativeChain.getBalance(data.wallets.swap.nativeAddress);
    assert.equal(Number(nativeReceiverFinalBalance.VLX).toFixed(6), Number(nativeReceiverInitialBalance.VLX + transactionAmount).toFixed(6));

  });
});
