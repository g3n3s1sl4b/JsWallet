import { config } from '../config';
import { log } from '../tools/logger';
import { Browser, BrowserContext, Page } from '../types';

type MenuItem = 'wallets' | 'staking' | 'search' | 'settings' | 'support';

export abstract class BaseScreen {
  context: BrowserContext;
  browser: Browser;

  selectors = {
    address: 'div.wallet-detailed a[data-original]',
    menu: {
      settings: '#menu-settings',
      staking: '#menu-delegate',
      wallets: '#menu-wallets'
    },
  }

  constructor(public page: Page) {
    this.context = this.page.context();
    const browser = this.context.browser();
    if (!browser) throw new Error(`Browser was closed`);
    this.browser = browser;
  };

  async isLoggedIn(): Promise<boolean> {
    this.page.setDefaultTimeout(2000);
    try {
      await this.page.waitForSelector('.balance');
      log.info(`User is logged in`);
      return true;
    } catch (e) {
      log.info(`User is not logged in`);
      return false;
    } finally {
      this.page.setDefaultTimeout(config.defaultWaitTimeout);
    }
  }

  async openMenu(item: MenuItem): Promise<void> {
    let menuItemName: MenuItem | 'delegate' = item;
    if (item === 'staking') menuItemName = 'delegate';
    await this.page.click(`#menu-${menuItemName}`);

    // wait for wallets data loaded
    if (menuItemName === 'wallets') {
      await this.page.waitForSelector('.wallet-item .top-left [class=" img"]', { state: 'visible' });
    }
  }
}