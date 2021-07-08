import { Page } from '../types';
import { BaseScreen } from './base';

export class WalletsScreen extends BaseScreen {
  constructor(public page: Page) {
    super(page);
  };

  async getWalletAddress(): Promise<string> {
    return (await this.page.getAttribute('div.wallet-detailed a[data-original]', 'data-original'))?.trim() || '';
  }

  async selectWallet(tokenName: 'Bitcoin' | 'Velas' | 'Velas Native' | 'Velas EVM'): Promise<void> {
    await this.waitForWalletsDataLoaded();
    const tokenNameSelector = `div.big.wallet-item .balance.title:text(" ${tokenName}")`;
    // some time is required to load wallets and switch between them; so custom waiter is implemented
    let requiredCurrencyIsALreadySelected = await this.page.isVisible(tokenNameSelector);
    while (!requiredCurrencyIsALreadySelected) {
      await this.page.click(`.balance.title:text(" ${tokenName}")`);
      await this.page.waitForTimeout(100);
      requiredCurrencyIsALreadySelected = await this.page.isVisible(tokenNameSelector);
    }
  }
}
