import { data } from './test-data';
import { Environment } from './types';

export const environment: Environment = 'local';

export const config = {
  CI: process.env.CI === 'true',
  defaultWaitTimeout: Number(process.env.DEFAULT_WAIT_TIMEOUT) || 6000,
  environment: process.env.ENVIRONMENT as Environment || environment,
  logLevel: process.env.LOG_LEVEL || 'debug',
  network: process.env.NETWORK || 'testnet',
  pw: {
    slowMo: 250,
  },
};

export const walletURL = `${data.walletHosts[config.environment]}?network=${config.network}`;
