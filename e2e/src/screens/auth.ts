import { log } from '../tools/logger';
import { Page } from '../types';
import { BaseScreen } from './base';

export type Language = 'fr' | 'en' | 'kr' | 'cn' | 'sp' | 'ua' | 'ru' | 'ar';

export class Auth extends BaseScreen {
  constructor(public page: Page) {
    super(page);
  };
 
  customSeedInput = {
    fillAndConfirm: async (seedPhrase: string | string[]): Promise<void> => {
      if (typeof seedPhrase !== 'string') seedPhrase = seedPhrase.join(' ');
      log.info(`Fill seed phrase: ${seedPhrase}`)
      await this.page.fill('#seedphrase-custom', seedPhrase);
      await this.page.click('#seed-phrase-next');
    },
  }

  async loginByRestoringSeed(seedPhrase: string | string[]) {
    const auth = new Auth(this.page);

    const isLoggedIn = await this.isLoggedIn();
    if (isLoggedIn) {
      log.info(`User is already logged in`);
      return;
    }

    const passwordInput = await this.page.isVisible('[placeholder="Password or PIN"]', { timeout: 2000 });
    if (passwordInput) {
      log.info(`You try to log in. And login was already performed in this context. Adding new account...`);
      await auth.passwordForLoggedOutAcc.newAccount();
    }

    await auth.language.select('en');
    await auth.welcome.restore();
    await auth.restoreFrom.seed('custom');
    await auth.passwordForNewAcc.fillAndConfirm('111222');
    await auth.customSeedInput.fillAndConfirm(seedPhrase);

    await this.page.waitForSelector('.menu-item');
    await this.page.waitForSelector('.balance');
    log.info('Successfully logged in');
  }

  newSeed = {
    getArrayWithSeed: async (params: { log?: boolean }): Promise<string[]> => {
      const wordsElements = await this.page.$$('div.words .word span:nth-child(2)');
      const seedWords: string[] = [];

      for (let i = 0; i < wordsElements.length; i++) {
        const word = await wordsElements[i].textContent() as string;
        seedWords.push(word.trim());
      }

      if (params.log) {
        log.info(`Seed phrase:\n${seedWords.join(' ')}`);
      }

      return seedWords;
    },

    clickNext: async (): Promise<void> => {
      await this.page.click('#seed-next');
    }
  }

  passwordForLoggedOutAcc = {
    typeAndConfirm: async (password: string): Promise<void> => {
      await this.page.type('[type="password"]', password);
      await this.page.click('" Enter"');
    },

    newAccount: async (): Promise<void> => {
      await this.page.click('button.setup');
      await this.page.click('button#confirmation-confirm');
    },
  }

  passwordForNewAcc = {
    fillAndConfirm: async (password: string): Promise<void> => {
      await this.page.fill('[type="password"]', password);
      await this.page.click('button.setup');
    }
  }

  restoreFrom = {
    seed: async (type: '24' | '12' | 'custom'): Promise<void> => {
      await this.page.click(`#restore-${type}`);
    },
  }

  language = {
    select: async (language: Language): Promise<void> => {
      await this.page.click(`#lang-${language}`);
    }
  }

  terms = {
    accept: async (): Promise<void> => {
      await this.page.click('" Accept"');
    },
  }

  welcome = {
    create: async (): Promise<void> => {
      await this.page.click('#btn-create');
    },

    restore: async (): Promise<void> => {
      await this.page.click('#btn-restore');
    },
  }

  wordByWordSeedInputForm = {
    fill: async (seedWords: string[]): Promise<void> => {
      const elementWithWordNumberSelector = '.words [placeholder*="word #"]';
      for (let i = 0; i < seedWords.length; i++) {
        // example of "placeholder" attribute value: "word #1"
        const placeholderValue = await this.page.getAttribute(elementWithWordNumberSelector, 'placeholder');
        // cut text "word #" and leave only number at the end of string
        const requestedWordNumber = Number(placeholderValue?.slice(6));
        await this.page.type(`.words [placeholder*="word #${requestedWordNumber}"]`, seedWords[requestedWordNumber - 1]);
        await this.page.click('" Next"');
      }
    }
  }
}
