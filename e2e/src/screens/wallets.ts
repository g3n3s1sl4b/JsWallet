import { Page } from '../types';
import { BaseScreen } from './base';

export class MainScreen extends BaseScreen {
  constructor(public page: Page) {
    super(page);
  };

  async getWalletAddress(): Promise<string> {
    return (await this.page.getAttribute('div.wallet-detailed a[data-original]', 'data-original'))?.trim() || '';
  }

  async waitForWalletsDataLoaded(): Promise<void> {
    await this.page.waitForSelector('.wallet-item .top-left [class=" img"]', { state: 'visible' });
  }

  async selectWallet(tokenName: 'Bitcoin' | 'Velas' | 'Velas Native' | 'Velas EVM'): Promise<void> {
    await this.page.click(`.balance.title:text(" ${tokenName}")`);
  }

}
