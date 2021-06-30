import { assert } from '../mocha-wrapper/assert';
import { PW } from '../playwright-helpers';
import { Auth, Language } from '../screens/auth';
import { MainScreen } from '../screens/wallets';
import { data, walletURL } from '../test-data';
import { log } from '../tools/logger';
import { Browser, BrowserContext, Page } from '../types';


describe('Auth', function () {
  let browser: Browser;
  let context: BrowserContext;
  let page: Page;
  let auth: Auth;
  let mainScreen: MainScreen;
  const accountAddress24Words = 'VCtQbbgQHnXfEAsYgbhWuWhyftzYRk6h6a';
  const accountAddress12Words = 'V2BrnFYpvAx6RTkjb1Db7AU7JFtnDrv19Q';
  let pw: PW;

  before(async function () {
    pw = new PW();
    ({ browser, context, page } = await pw.init());
  });

  after(async function () {
    await browser.close();
  });

  describe('Sign up', function () {
    before(async function () {
      context = await pw.getContext();
      page = await pw.getPage();
      auth = new Auth(page);
    });

    afterEach(async function () {
      await context.close();
    });

    it('Create wallet', async function () {
      await page.goto(walletURL);
      await auth.language.select('en');
      await auth.welcome.create();
      await auth.passwordForNewAcc.typeAndConfirm('111222');

      const seedWords = await auth.newSeed.getArrayWithSeed({ log: true });

      await auth.newSeed.clickNext();
      await auth.wordByWordSeedPhraseInputForm.fill(seedWords);
      await auth.terms.accept();

      assert.isTrue(await page.isVisible('.menu-item'));
      assert.isTrue(await page.isVisible('.balance'));
    });
  });

  describe('Restore with:', function () {
    beforeEach(async function () {
      context = await pw.getContext();
      page = await pw.getPage();
      auth = new Auth(page);
      mainScreen = new MainScreen(page);
    });

    afterEach(async function () {
      await context.close();
    });

    it('custom seed phrase', async function () {
      await page.goto(walletURL);
      await auth.loginByRestoringSeed(data.seedPhrase);
    });

    it('24-words seed phrase', async function () {
      await page.goto(walletURL);
      await auth.language.select('en');
      await auth.welcome.restore();
      await auth.restoreFrom.seed('24');
      await auth.passwordForNewAcc.typeAndConfirm('111222');
      await auth.wordByWordSeedPhraseInputForm.fill(data.seedPhrase);

      assert.isTrue(await page.isVisible('.menu-item'));
      assert.isTrue(await page.isVisible('.balance'));
      assert.equal(await mainScreen.getWalletAddress(), accountAddress24Words, 'Account address on UI does not equal expected');
    });

    it('12-words seed phrase', async function () {
      await page.goto(walletURL);
      await auth.language.select('en');
      await auth.welcome.restore();
      await auth.restoreFrom.seed('12');
      await auth.passwordForNewAcc.typeAndConfirm('111222');
      const seed12Words: string[] = { ...data.seedPhrase };
      seed12Words.length = 12;
      await auth.wordByWordSeedPhraseInputForm.fill(seed12Words);

      assert.isTrue(await page.isVisible('.menu-item'));
      assert.isTrue(await page.isVisible('.balance'));
      assert.equal(await mainScreen.getWalletAddress(), accountAddress12Words, 'Account address on UI does not equal expected');
    });
  });

  describe('Log in', function () {
    let mainScreen: MainScreen;

    before(async function () {
      context = await pw.getContext();
      page = await pw.getPage();
      mainScreen = new MainScreen(page);
      auth = new Auth(page);
      await page.goto(walletURL);
      await auth.loginByRestoringSeed(data.seedPhrase);
    });

    after(async function () {
      await context.close();
    });

    beforeEach(async function () {
      await page.reload();
    });

    it('Can\'t log in with incorrect password', async function () {
      await auth.passwordForLoggedOutAcc.typeAndConfirm('111111');
      assert.isTrue(await page.isVisible('.wrong'));
    });

    it('Log in with pin', async function () {
      await auth.passwordForLoggedOutAcc.typeAndConfirm('111222');

      assert.isTrue(await mainScreen.isLoggedIn());
      assert.equal(await mainScreen.getWalletAddress(), accountAddress24Words, 'Account address on UI does not equal expected');
    });
  });

  describe('Choose language on sign up', function () {
    before(async function () {
      context = await pw.getContext();
      page = await pw.getPage({ newInstance: true });
      auth = new Auth(page);
      await page.goto(walletURL);
    });

    after(async function () {
      await context.close();
    });

    it('Change language', async function () {
      const welcomeTexts = {
        fr: 'Bienvenu(e)!',
        en: 'Welcome!',
        kr: '어서 오십시오!',
        cn: '欢迎！',
        //in: 'स्वागत हे!',
        sp: '¡Bienvenido!',
        ua: 'Ласкаво просимо!',
        ru: 'Добро пожаловать!',
        ar: 'مرحبا!',
        //id: 'Selamat datang!',
        //ph: 'pagsalubong sa Pitaka',
        //yr: 'Kaabo!',
        //vn: 'Chào mừng!'
      };

      const languages = Object.keys(welcomeTexts) as Language[];
      for (let i = 0; i < languages.length; i++) {
        const language = languages[i];
        log.info(language);
        await auth.language.select(language);
        const actualWelcomeText = (await page.textContent('.welcome'))?.trim();
        assert.equal(actualWelcomeText, welcomeTexts[language], `${language} language on UI does not equal chosen language`);
        await page.reload();
      }
    });
  });
});
