import { test } from '@playwright/test';
import { assert } from '../assert';
import { setupPage } from '../pw-helpers/setup-page';
import { Auth } from '../screens/auth';
import { WalletsScreen } from '../screens/wallets';
import { data, getWalletURL } from '../test-data';
import { log } from '../tools/logger';
import { VelasNative } from '@velas/velas-chain-test-wrapper';
import velasTestnet from '../api/velas-testnet/rpc';
import { velasNative } from '@velas/velas-chain-test-wrapper/lib/velas-native';

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
    await walletsScreen.waitForWalletsDataLoaded();
  });

  test('VLX > Native', async ({ page }) => {
    const vlxSenderInitialBalance = (await walletsScreen.getWalletsBalances())['Velas'];
    const nativeReceiverInitialBalance = await velasNativeChain.getBalance(data.wallets.swap.address);
    const transactionAmount = 0.0001;

    await walletsScreen.swapTokens('Velas', 'Velas Native', transactionAmount);
    await walletsScreen.openMenu('wallets');

    const previousTx = (await velasTestnet.getConfirmedTransactionsForAddress(data.wallets.swap.address)).signatures[0];
    let currentTx = previousTx;

    while (previousTx === currentTx){
      log.debug('No new transactions in the chain, wait and retry...');
      await page.waitForTimeout(1000);
      currentTx = (await velasTestnet.getConfirmedTransactionsForAddress(data.wallets.swap.address)).signatures[0];
    }
    log.debug(currentTx);

    await walletsScreen.waitForWalletsDataLoaded();

    const vlxSenderFinalBalance = (await walletsScreen.getWalletsBalances())['Velas'];
    assert.isBelow(Number(vlxSenderFinalBalance), Number(vlxSenderInitialBalance) - transactionAmount);
    
    const nativeReceiverFinalBalance = await velasNativeChain.getBalance(data.wallets.swap.address);
    assert.equal(Number(nativeReceiverFinalBalance.VLX).toFixed(6), Number(nativeReceiverInitialBalance.VLX + transactionAmount).toFixed(6));
  });

  test('Native > VLX', async ({ page }) => {
    const nativeSenderInitialBalance = await velasNativeChain.getBalance(data.wallets.swap.address);
    const vlxReceiverInitialBalance = (await walletsScreen.getWalletsBalances())['Velas'];

    const transactionAmount = 0.0001;

    await walletsScreen.swapTokens('Velas Native', 'Velas', transactionAmount);

    const txSignatureLink = String(await page.getAttribute('.sent .text a', 'href'));
    const txSignature = txSignatureLink.replace('https://native.velas.com/tx/', '');
    log.debug(txSignature);

    await walletsScreen.openMenu('wallets');
    await velasNative.waitForConfirmedTransaction(txSignature);
    await walletsScreen.waitForWalletsDataLoaded();

    const nativeSenderFinalBalance = await velasNativeChain.getBalance(data.wallets.swap.address);
    assert.isBelow(Number(nativeSenderFinalBalance.VLX), Number(nativeSenderInitialBalance.VLX) - transactionAmount);

    const vlxReceiverFinalBalance = (await walletsScreen.getWalletsBalances())['Velas'];
    assert.equal(Number(vlxReceiverFinalBalance).toFixed(6), (Number(vlxReceiverInitialBalance) + transactionAmount).toFixed(6));
  });

  test('EVM > Velas', async ({ page }) => {
    await walletsScreen.swapTokens('Velas EVM', 'Velas', 0.0001);

    const txSignatureLink = String(await page.getAttribute('.sent .text a', 'href'));
    log.debug(txSignatureLink);

    assert.isTrue(txSignatureLink.includes('https://explorer.testnet.velas.com/tx/'));
  });

  test('Velas > EVM', async ({ page }) => {
    await walletsScreen.swapTokens('Velas', 'Velas EVM', 0.0001);

    const txSignatureLink = String(await page.getAttribute('.sent .text a', 'href'));
    log.debug(txSignatureLink);

    assert.isTrue(txSignatureLink.includes('https://explorer.testnet.velas.com/tx/'));
  });

  test('EVM > Native', async ({ page }) => {
    await walletsScreen.swapTokens('Velas EVM', 'Velas Native', 0.0001);

    const txSignatureLink = String(await page.getAttribute('.sent .text a', 'href'));
    log.debug(txSignatureLink);

    assert.isTrue(txSignatureLink.includes('https://explorer.testnet.velas.com/tx/'));
  });

  test('Native > EVM', async ({ page }) => {
    await walletsScreen.swapTokens('Velas Native', 'Velas EVM', 0.0001);

    const txSignatureLink = String(await page.getAttribute('.sent .text a', 'href'));
    const txSignature = txSignatureLink.replace('https://native.velas.com/tx/', '');
    log.debug(txSignature);

    await velasNative.waitForConfirmedTransaction(txSignature);
  });
});
