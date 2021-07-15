import { log } from '../tools/logger';
import { Page } from '../types';
import { BaseScreen } from './base';

type Stake = 'to_undelegate' | 'to_withdraw' | 'to_delegate';

export class StakingScreen extends BaseScreen {
  constructor(public page: Page) {
    super(page);
  };

  delegateButton = '#staking-accounts tr.inactive span:text(" Delegate")';
  undelegateButton = '#staking-accounts .action-undelegate span:text(" Undelegate")';
  withdrawButton = '#staking-accounts tr.loading span:text(" Undelegate")';

  async waitForLoaded(): Promise<void> {
    try {
      await this.page.waitForSelector('" Loading..."', { timeout: 2000 });
    } catch (e) {
      log.debug('No loading after opening staking. Looks like it\'s already fully loaded.');
    }
    await this.page.waitForSelector('.validator-item', { timeout: 12000 });
    // staking account item
    await this.page.waitForSelector('#staking-accounts [datacolumn="Staker Address"]', { timeout: 10000 });
    await this.page.waitForTimeout(1000);
  }

  async waitForStakesAmountUpdated(initialStakesAmount: number, stakeType: Stake | 'all' = 'all'): Promise<number> {
    let finalAmountOfStakingAccounts = await this.getAmountOfStakes(stakeType);
    while (finalAmountOfStakingAccounts === initialStakesAmount) {
      log.warn('Amount of stake accounts still the same. Wait and refresh the staking data...');
      await this.page.waitForTimeout(5000);
      await this.refresh();
      finalAmountOfStakingAccounts = await this.getAmountOfStakes(stakeType);
    }
    return finalAmountOfStakingAccounts;
  }

  async refresh(): Promise<void> {
    await this.page.click('[title="refresh"]');
    await this.waitForLoaded();
  }

  async clickDelegate(): Promise<void> {
    try {
      await this.page.click(this.delegateButton);
    } catch (e) {
      throw new Error(`No stakes available to delegate. Please undelegate first\n${e}`)
    }
  }

  async clickUndelegate(): Promise<void> {
    try {
      await this.page.click(this.undelegateButton);
    } catch (e) {
      throw new Error(`No stakes available to undelegate. Please delegate first\n${e}`)
    }
  }

  async getAmountOfStakes(type: Stake | 'all'): Promise<number> {
    await this.waitForLoaded();
    if (type === 'all') return (await this.page.$$('#staking-accounts [datacolumn="Staker Address"]')).length;
    let stakeItemSelector: string;
    switch (type) {
      case 'to_delegate':
        stakeItemSelector = this.delegateButton;
        break;
      case 'to_undelegate':
        stakeItemSelector = this.undelegateButton;
        break;
      case 'to_withdraw':
        stakeItemSelector = this.withdrawButton;
        break;
    }
    return (await this.page.$$(stakeItemSelector)).length;
  }

  async selectAccount(type: Stake): Promise<void> {
    // loading classname corresponds to Undelegate and Withdraw stakes
    const selector = `#staking-accounts tr.${type === 'to_delegate' ? 'inactive' : 'loading'} .inner-address-holder div a`;
    await this.page.click(selector);
  }

  async showOnPage(amount: 5 | 10 | 20): Promise<void> {
    await this.page.click(`#accounts-selector div.to-show`);
    await this.page.click(`div:text(" ${amount}")`);
  }
}
