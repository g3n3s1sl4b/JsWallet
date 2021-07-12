import { test } from '@playwright/test';
import { assert } from '../assert';
import { setupPage } from '../pw-helpers/setup-page';
import { Auth, Language } from '../screens/auth';
import { WalletsScreen } from '../screens/wallets';
import { data, getWalletURL } from '../test-data';
import { log } from '../tools/logger';

test.describe('Auth', () => {
  let auth: Auth;
  let walletsScreen: WalletsScreen;
  const accountAddress24Words = 'VCtQbbgQHnXfEAsYgbhWuWhyftzYRk6h6a';
  const accountAddress12Words = 'V2BrnFYpvAx6RTkjb1Db7AU7JFtnDrv19Q';

  test.beforeEach(async ({ page }) => {
    setupPage(page);
    await page.goto(getWalletURL());
    walletsScreen = new WalletsScreen(page);
    auth = new Auth(page);
  });

  test.describe('Sign up', () => {
    test('Create wallet', async ({ page }) => {
      await auth.language.select('en');
      await auth.welcome.create();
      await auth.pinForNewAcc.fillAndConfirm('111222');

      const seedWords = await auth.newSeed.getArrayWithSeed({ log: true });

      await auth.newSeed.next();
      await auth.wordByWordSeedInputForm.fill(seedWords);
      await auth.terms.accept();

      assert.isTrue(await page.isVisible('.menu-item'));
      assert.isTrue(await page.isVisible('.balance'));
    });
  });

  test.describe('Restore with:', () => {
    test.afterEach(async ({ context }) => {
      await context.close();
    });

    test('custom seed phrase', async () => {
      await auth.loginByRestoringSeed(data.wallets.login.seed);
    });

    test('24-words seed phrase', async ({ page }) => {
      await auth.language.select('en');
      await auth.welcome.restore();
      await auth.restoreFrom.seed('24');
      await auth.pinForNewAcc.fillAndConfirm('111222');
      await auth.wordByWordSeedInputForm.fill(data.wallets.login.seed);

      assert.isTrue(await page.isVisible('.menu-item'));
      assert.isTrue(await page.isVisible('.balance'));
      assert.equal(await walletsScreen.getWalletAddress(), accountAddress24Words, 'Account address on UI does not equal expected');
    });

    test('12-words seed phrase', async ({ page }) => {
      await auth.language.select('en');
      await auth.welcome.restore();
      await auth.restoreFrom.seed('12');
      await auth.pinForNewAcc.fillAndConfirm('111222');
      const seed12Words: string[] = { ...data.wallets.login.seed };
      seed12Words.length = 12;
      await auth.wordByWordSeedInputForm.fill(seed12Words);

      assert.isTrue(await page.isVisible('.menu-item'));
      assert.isTrue(await page.isVisible('.balance'));
      assert.equal(await walletsScreen.getWalletAddress(), accountAddress12Words, 'Account address on UI does not equal expected');
    });
  });

  test.describe('Can\t restore with invalid seed', () => {
    test.only('Can\'t restore with incorrect seed phrase', async ({ page }) => {
      await auth.language.select('en');
      await auth.welcome.restore();
      await auth.restoreFrom.seed('24');
      await auth.pinForNewAcc.fillAndConfirm('111222');
      await auth.wordByWordSeedInputForm.fill(Array(24).fill("sad"), {fast: true});

      assert.isTrue(await page.isVisible('.confirmation-body'), 'No alert for incorrect seed phrase on UI');
      assert.isFalse(await page.isVisible('.menu-item'), 'Restored with incorrect seed phrase');
    });
  });

  test.describe('Log in', () => {
    test.beforeEach(async ({ page }) => {
      walletsScreen = new WalletsScreen(page);
      await auth.loginByRestoringSeed(data.wallets.login.seed);
      await page.reload();
    });

    test('Can\'t log in with incorrect password', async ({ page }) => {
      await auth.pinForLoggedOutAcc.typeAndConfirm('111111');
      assert.isTrue(await page.isVisible('.wrong'));
    });

    test('Log in with pin', async () => {
      await auth.pinForLoggedOutAcc.typeAndConfirm('111222');

      assert.isTrue(await walletsScreen.isLoggedIn());
      assert.equal(await walletsScreen.getWalletAddress(), accountAddress24Words, 'Account address on UI does not equal expected');
    });
  });

  test.describe('Choose language on sign up', () => {
    test('Change language', async ({ page }) => {
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
