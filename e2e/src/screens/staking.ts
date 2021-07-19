import { velasNative } from '@velas/velas-chain-test-wrapper/lib/velas-native';
import { helpers } from '../tools/helpers';
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
  withdrawButton = '#staking-accounts tr.loading span:text(" Withdraw")';
  stakingAccountAddress = '#staking-accounts [datacolumn="Staker Address"]';

  async waitForLoaded(): Promise<void> {
    try {
      await this.page.waitForSelector('" Loading..."', { timeout: 2000 });
    } catch (e) {
      log.debug('No loading after opening staking. Looks like it\'s already fully loaded.');
    }
    await this.page.waitForSelector('.validator-item', { timeout: 12000 });
    // wait staking account item or make sure there are no accounts
    await this.page.waitForSelector(`${this.stakingAccountAddress}, #staking-accounts .amount:text(" (0) ")`, { timeout: 10000 });
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

  async getFirstStakingAccountAddressFromTheList(type: Stake): Promise<string> {
    await this.waitForLoaded();
    const accountsElementsList = await this.page.$$(`#staking-accounts tr`);
    const errorText = `No accounts in the list of required type – "${type}"`;

    for (let i = 0; i < accountsElementsList.length; i++) {
      const accountElement = accountsElementsList[i];
      let buttonText: string;

      switch (type) {
        case 'to_delegate':
          buttonText = 'Delegate';
          break;
        case 'to_undelegate':
          buttonText = 'Undelegate';
          break;
        case 'to_withdraw':
          buttonText = 'Withdraw';
          break;
      }

      if (await accountElement.$(`span:text("${buttonText}")`)) {
        const accountAddress = await (await accountElement.$('td[title]'))?.getAttribute('title');
        if (typeof accountAddress !== 'string') throw new Error(errorText);
        return accountAddress;
      }
    }
    throw new Error(errorText);
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

  async getStakingAccountsAddresses(): Promise<string[]> {
    await this.waitForLoaded();
    const stakesAccountsElements = await this.page.$$(this.stakingAccountAddress);
    const stakingAccountAddresses = await Promise.all(
      stakesAccountsElements.map(async (el) => await el.getAttribute('title') as string)
    );
    return stakingAccountAddresses;
  }

  /**
   * Function requires only initial stake accounts addresses list. Final list could be passed or will be got during function invocation.
   * Returns difference between states with specifying if stake account was added or removed from stake accounts list
   * 
   * @param initialAccountsList 
   * @param finalAccountsList 
   * @returns added or removed accounts list
   */
  async getStakingAccountsUpdate(initialAccountsAddressesList: string[], finalAccountsAddressesList?: string[]): Promise<{
    added?: string,
    removed?: string,
  } | null> {
    finalAccountsAddressesList = finalAccountsAddressesList || await this.getStakingAccountsAddresses();
    const diff = helpers.getArraysDiff(initialAccountsAddressesList, finalAccountsAddressesList);
    if (diff.length === 0) return null;
    return finalAccountsAddressesList.length > initialAccountsAddressesList.length ? { added: diff[0] } : { removed: diff[0] };
  }

  async selectAccount(type: Stake): Promise<void> {
    // "loading" classname corresponds to Undelegate and Withdraw stakes
    const selector = `#staking-accounts tr.${type === 'to_delegate' ? 'inactive' : 'loading'} .inner-address-holder div a`;
    await this.page.click(selector);
  }

  async showOnPage(amount: 5 | 10 | 20): Promise<void> {
    await this.page.click(`#accounts-selector div.to-show`);
    await this.page.click(`div:text(" ${amount}")`);
  }

  async makeSureStakingAccIsCreatedAndNotDelegated(address: string): Promise<void> {
    try {
      await velasNative.getStakeAccount(address);
    } catch (error) {
      log.debug('This is expected error. Please ignore:', error);
      if (!error.toString().includes('stake account has not been delegated')) {
        throw new Error(`Something is wrong with staking account on blockchain:\n${error}`);
      }
    }
    log.info(`Newly added staking account: ${address}`);
  }

  async makeSureStakingAccountDoesNotExist(address: string): Promise<void> {
    try {
      await velasNative.getStakeAccount(address);
    } catch (error) {
      log.debug('This is expected error. Please ignore:', error);
      if (!error.toString().includes('account not found')) {
        throw new Error(`Staking account still exist but should not. Error:\n${error}`);
      }
    }
    log.info(`Withdrawed staking account: ${address}`);
  }

}
