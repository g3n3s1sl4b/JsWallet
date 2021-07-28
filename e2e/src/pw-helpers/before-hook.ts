import { getWalletURL } from '../config';
import { log } from '../tools/logger';

export default () => {
  log.info(`Tests are running ${process.env.CI ? 'on CI' : 'locally'} on ${getWalletURL()}`);
};
