import playwright, {
  Browser, BrowserContext, BrowserContextOptions, devices, Page
} from 'playwright-chromium';
import { config } from './config';

const windowSize = { width: 1920, height: 1080 };

export class PW {
  browser: Browser | undefined;
  context: BrowserContext | undefined;
  page: Page | undefined;

  async launchBrowser(config?: {
    headless?: boolean,
    slowMo?: number,
    args?: string[],
  }): Promise<Browser> {
    const browser = await playwright.chromium.launch({
      args: ['--disable-dev-shm-usage', '--disable-gpu', '--no-sandbox', `--window-size=${windowSize.width},${windowSize.height}`],
      devtools: false,
      headless: true,
      slowMo: 100,
      ...config,
    });
    if (!browser) throw new Error('Can\'t launch broser.');
    this.browser = browser;
    return browser;
  }

  async getContext(params?: { browser?: Browser, mobileDeviceName?: string, newInstance?: boolean }): Promise<BrowserContext> {
    const mobileDevice = (params && params.mobileDeviceName) ? devices[params.mobileDeviceName] : {};
    const contextParams = {
      ...mobileDevice,
    } as BrowserContextOptions;
    const browser = params?.browser || this.browser || await this.launchBrowser();
    let context = browser.contexts()[0];
    if (!context || params?.newInstance) {
      context = await browser.newContext(contextParams);
    }
    context.setDefaultTimeout(config.defaultWaitTimeout);
    if (!context) throw new Error('Can\'t create browser context.');
    this.context = context;
    this.browser = browser;
    return context;
  }

  async getPage(params?: { browser?: Browser, context?: BrowserContext, newInstance?: boolean }): Promise<Page> {
    const context = params?.context || this.context || await this.getContext({ browser: params?.browser });
    let page = context.pages()[0];

    if (!page || params?.newInstance) {
      page = await context.newPage();
    }

    page.setDefaultNavigationTimeout(40000);
    // resize window for desktop (skip mobile)
    // @ts-expect-error access private property
    if (!context._options.isMobile) {
      await page.setViewportSize({ width: windowSize.width, height: windowSize.height });
    }
    page.setDefaultTimeout(config.defaultWaitTimeout);
    this.page = page;
    this.context = page.context();
    this.browser = context.browser() || undefined;
    return page;
  }

  async init(): Promise<{ browser: Browser, context: BrowserContext, page: Page }> {
    const browser = await this.launchBrowser();
    this.browser = browser;
    const context = await this.getContext({ browser });
    this.context = context;
    const page = await this.getPage({ browser, context });
    this.page = page;
    return { browser, context, page };
  }
}

// export const pw = new PW();
