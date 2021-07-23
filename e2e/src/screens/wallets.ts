import { log } from '../tools/logger';
import { ElementHandle, Page } from '../types';
import { BaseScreen } from './base';

export type Currency = 'Bitcoin' | 'Velas' | 'Velas Native' | 'Velas EVM' | 'Litecoin';
export type Balances = Record<Currency, string | null>;

export class WalletsScreen extends BaseScreen {
  constructor(public page: Page) {
    super(page);
  };

  async getWalletAddress(): Promise<string> {
    return (await this.page.getAttribute('div.wallet-detailed a[data-original]', 'data-original'))?.trim() || '';
  }

  async selectWallet(tokenName: Currency): Promise<void> {
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

  async getWalletsBalances(): Promise<Balances> {
    await this.waitForWalletsDataLoaded();
    const walletElements = await this.page.$$('.wallet-item');
    const balances: Balances = {
      'Velas': null,
      'Velas EVM': null,
      'Velas Native': null,
      'Bitcoin': null,
      'Litecoin': null,
    };

    for (let i = 0; i < walletElements.length; i++) {
      const walletElement = walletElements[i];
      const tokenName: Currency = await this.getTokenNameOfWalletItemElement(walletElement) as Currency;

      // skip if wallet is not in the wallets list
      if (!await this.isWalletInWalletsList(tokenName)) continue;

      const amountOfTokens = await this.getAmountOfTokensFromOfWalletItemElement(walletElement);
      balances[tokenName] = amountOfTokens;
    }
    log.info(balances);
    return balances;
  }

  async isWalletInWalletsList(tokenName: Currency): Promise<boolean> {
    return this.page.isVisible(`.balance.title:text(" ${tokenName}")`);
  }

  private async getAmountOfTokensFromOfWalletItemElement(walletElement: ElementHandle<SVGElement | HTMLElement>): Promise<string> {
    const amountOfTokens = await (await walletElement.$('.info .token.price'))?.getAttribute('title');
    if (!amountOfTokens) throw new Error('Cannot get amount of tokens');
    return amountOfTokens;
  }

  private async getTokenNameOfWalletItemElement(walletElement: ElementHandle<SVGElement | HTMLElement>): Promise<string> {
    const tokenName = (await (await walletElement.$('.balance.title'))?.textContent())?.trim();
    if (!tokenName) throw new Error('Cannot get token name');
    return tokenName;
  }

  async updateBalances(): Promise<void> {
    await this.page.click('.balance .button.lock');
    await this.waitForWalletsDataLoaded();
  }

  async hideWallet(): Promise<void> {
    await this.waitForWalletsDataLoaded();
    await this.page.click('.wallet-header .uninstall');
    await this.waitForWalletsDataLoaded();
  }

  async waitForWalletsDataLoaded(): Promise<void> {
    await this.page.waitForSelector('.wallet-item .top-left [class=" img"]', { state: 'visible', timeout: 10000 });
  }

  addWalletsPopup = {
    open: async () => {
      await this.page.click('.header .button.lock.mt-5');
    },
    add: async (tokenName: Currency) => {
      const walletItemsList = await this.page.$$('.manage-account .settings .list .item');
      for (let i = 0; i < walletItemsList.length; i++) {
        const walletItem = walletItemsList[i];
        const wallenTokenName = (await (await walletItem.$(`span.title:text("${tokenName}")`))?.textContent())?.trim();
        const addButton = await walletItem.$('button');
        if (wallenTokenName === tokenName) {
          await addButton?.click();
        }
      }
    }

  }

}
