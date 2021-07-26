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

test.describe('Transactions >', () => {
  test.beforeEach(async ({ page }) => {
    setupPage(page);
    auth = new Auth(page);
    walletsScreen = new WalletsScreen(page);
    await page.goto(getWalletURL({ testnet: true }));
    await auth.loginByRestoringSeed(data.wallets.txSender.seed);
  });

  test('Send VLX native', async ({ page }) => {
    const receiverInitialBalance = await velasNativeChain.getBalance(data.wallets.fundsReceiver.address);
    const senderInitialBalance = await velasNativeChain.getBalance(data.wallets.txSender.address);
    const transactionAmount = 0.0001;

    await walletsScreen.selectWallet('Velas Native');
    await page.click('#wallets-send');
    await page.fill('#send-recipient', 'FJWtmzRwURdnrgn5ZFWvYNfHvXMtHK1WS7VHpbnfG73s');
    await page.type('div.amount-field input[label="Send"]', String(transactionAmount));
    await page.click('#send-confirm');
    await page.click('#confirmation-confirm');

    const txSignatureLink = String(await page.getAttribute('.sent .text a', 'href'));
    const txSignature = txSignatureLink.replace('https://native.velas.com/tx/', '');
    if (!txSignature) throw new Error('Cannot get transaction signature from tx link');

    const tx = await velasNativeChain.waitForConfirmedTransaction(txSignature);
    assert.exists(tx);

    await page.click('[datatesting="transaction"] div.more');
    const receiverAddress = (await page.getAttribute('[datatesting="transaction"] .address-holder a[data-original]', 'data-original'))?.trim();
    assert.equal(receiverAddress, data.wallets.fundsReceiver.address);

    const receiverFinalBalance = await velasNativeChain.getBalance(data.wallets.fundsReceiver.address);
    assert.equal(receiverFinalBalance.VLX.toFixed(6), (receiverInitialBalance.VLX + transactionAmount).toFixed(6));

    const senderFinalBalance = await velasNativeChain.getBalance(data.wallets.txSender.address);
    assert.isBelow(senderFinalBalance.VLX, senderInitialBalance.VLX - transactionAmount, 'Final sender balance is not below the initial sender balance');
  });

  test.only('Send ETH', async ({ page }) => {
    await page.pause()
    await walletsScreen.addWalletsPopup.open();
    await walletsScreen.addWalletsPopup.add('Ethereum');
    await walletsScreen.waitForWalletsDataLoaded();
    
    const transactionAmount = 0.00001;

    await walletsScreen.selectWallet('Ethereum');
    await page.click('#wallets-send');
    await page.fill('#send-recipient', '0xb322f01cb6a191974e7291600a4dc1b46f00f752');
    await page.type('div.amount-field input[label="Send"]', String(transactionAmount));
    await page.click('#send-confirm');
    await page.click('#confirmation-confirm');

    const txSignatureLink = String(await page.getAttribute('.sent .text a', 'href'));
    assert.isTrue(txSignatureLink.includes('https://ropsten.etherscan.io/'));
  });
});
