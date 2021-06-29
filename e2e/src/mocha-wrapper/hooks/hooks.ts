import { log } from '../../tools/logger';

export const mochaHooks = {
  beforeAll(): void {
    log.info(`Tests are running ${process.env.CI ? 'on CI' : 'locally'}`);
  },
};

export default mochaHooks;
