import { Env } from './types';

const env: Env = 'local';

export const config = {
  defaultWaitTimeout: Number(process.env.DEFAULT_WAIT_TIMEOUT) || 5000,
  env: process.env.ENV as Env || env,
  logLevel: process.env.LOG_LEVEL || 'info',
};
