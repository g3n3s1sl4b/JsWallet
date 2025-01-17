import { test } from '@playwright/test';
import { velasNative } from '@velas/velas-chain-test-wrapper';
import { assert } from '../../assert';
import { walletURL } from '../../config';
import { setupPage } from '../../pw-helpers/setup-page';
import { Auth } from '../../screens/auth';
import { WalletsScreen } from '../../screens/wallets';
import { data } from '../../test-data';
import { helpers } from '../../tools/helpers';

let auth: Auth;
let walletsScreen: WalletsScreen;

test.describe.parallel('Transactions >', () => {
  test.beforeEach(async ({ page }) => {
    setupPage(page);
    auth = new Auth(page);
    walletsScreen = new WalletsScreen(page);
    await page.goto(walletURL);
    await auth.loginByRestoringSeed(data.wallets.txSender.seed);
    await walletsScreen.waitForWalletsDataLoaded();
  });

  test('Send VLX native', async ({ page }) => {
    const receiverInitialBalance = await velasNative.getBalance(data.wallets.fundsReceiver.address);
    const senderInitialBalance = await velasNative.getBalance(data.wallets.txSender.address);
    const transactionAmount = 0.0001;

    await walletsScreen.selectWallet('token-vlx_native');
    await page.click('#wallets-send');
    await page.fill('#send-recipient', 'FJWtmzRwURdnrgn5ZFWvYNfHvXMtHK1WS7VHpbnfG73s');
    await page.fill('div.amount-field input[label="Send"]', String(transactionAmount));
    await page.click('#send-confirm:not([disabled])');
    await page.waitForSelector('#confirmation-confirm', { timeout: 30000 });
    await page.click('#confirmation-confirm');

    const txSignatureLink = String(await page.getAttribute('.sent .text a', 'href'));
    const txSignature = txSignatureLink.replace('https://native.velas.com/tx/', '');
    if (!txSignature) throw new Error('Cannot get transaction signature from tx link');

    const tx = await velasNative.waitForConfirmedTransaction(txSignature);
    assert.exists(tx);

    // disable next steps because UI doesn't always create tx details element and receiver balance is checked anyway

    // await page.click('[datatesting="transaction"] div.more', { timeout: 10000 });
    // const receiverAddress = (await page.getAttribute('[datatesting="transaction"] .address-holder a[data-original]', 'data-original'))?.trim();
    // assert.equal(receiverAddress, data.wallets.fundsReceiver.address);

    const receiverFinalBalance = await velasNative.getBalance(data.wallets.fundsReceiver.address);
    assert.equal(helpers.toFixed(receiverFinalBalance.VLX, 6), helpers.toFixed((receiverInitialBalance.VLX + transactionAmount), 6));

    const senderFinalBalance = await velasNative.getBalance(data.wallets.txSender.address);
    assert.isBelow(senderFinalBalance.VLX, senderInitialBalance.VLX - transactionAmount, 'Final sender balance is not below the initial sender balance');
  });

  test.skip('Send BTC', async ({ page }) => {
    // TODO: network request error
    await walletsScreen.selectWallet('token-btc');
    await page.click('#wallets-send');
    await page.fill('#send-recipient', 'mvvFj8fbFpL61S2HyhvcqEHjT2ThB1f78j', { timeout: 15000 }); //accound with index 2
    await page.fill('div.amount-field input[label="Send"]', '0.00001');
    await page.click('#send-confirm:not([disabled])');
    await page.click('#confirmation-confirm');
    const txSignatureLink = String(await page.getAttribute('.sent .text a', 'href'));
    assert.isTrue(txSignatureLink.includes('https://bitpay.com/insight/#/BTC/testnet/'));
  });

  test.skip('Send LTC', async ({ page }) => {
    // TODO: network request error
    await walletsScreen.addWalletsPopup.open();
    await walletsScreen.addWalletsPopup.add('token-ltc');
    await walletsScreen.waitForWalletsDataLoaded();

    await walletsScreen.selectWallet('token-ltc');
    await page.click('#wallets-send', { timeout: 10000 });
    await page.fill('#send-recipient', 'mvvFj8fbFpL61S2HyhvcqEHjT2ThB1f78j'); //accound with index 2
    await page.fill('div.amount-field input[label="Send"]', '0.00001');
    await page.click('#send-confirm:not([disabled])');
    await page.click('#confirmation-confirm');

    const txSignatureLink = String(await page.getAttribute('.sent .text a', 'href'));
    assert.isTrue(txSignatureLink.includes('https://testnet.litecore.io/'));
  });

  test('Send ETH', async ({ page }) => {
    await walletsScreen.waitForWalletsDataLoaded();
    
    const transactionAmount = 0.00001;

    await walletsScreen.selectWallet('token-eth_legacy');
    if (!await page.waitForSelector('#wallets-send')) throw new Error('Probably ETH wallet is disabled.');
    await page.click('#wallets-send');
    await page.fill('#send-recipient', '0xb322f01cb6a191974e7291600a4dc1b46f00f752'); //accound with index 2
    await page.fill('div.amount-field input[label="Send"]', String(transactionAmount));
    await page.click('#send-confirm:not([disabled])');
    await page.click('#confirmation-confirm');

    const txSignatureLink = String(await page.getAttribute('.sent .text a', 'href'));
    assert.isTrue(txSignatureLink.includes('https://ropsten.etherscan.io/'));
  });
});
