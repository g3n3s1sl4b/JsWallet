import { config } from "./config";

export const data = {
  
  walletURLs: {
    local: 'localhost:8080/main-index.html',
    devnet: '',
    mainnet: 'https://wallet.velas.com/',
    testnet: 'https://wallet.testnet.velas.com/',
  },
  wallets: {
    withFunds: {
      address: 'Dawj15q13fqzh4baHqmD2kbrRCyiFfkE6gkPcUZ21KUS',
      seed: 'with funds',
    },
    fundsReceiver: {
      address: 'FJWtmzRwURdnrgn5ZFWvYNfHvXMtHK1WS7VHpbnfG73s',
      seed: 'funds receiver',
    },
    login: {
      seed: ["decade", "cargo", "toe", "library", "cycle", "furnace", "idea", "tourist", "fuel", "chimney", "fury", "actual", "cash", "scheme", "race", "reason", "finger", "pulp", "nature", "family", "language", "spring", "kidney", "ancient"],
    },
    payer: {
      publicKey: '9kMFdW1VENdVpMyG9NNadNTzwXghknj3iU7CUwYFP1GC',
      seed: 'delay swift sick mixture vibrant element review arm snap true broccoli industry expect thought panel curve inhale rally dish close trade damp skin below',
    },
    staking: {
      staker: {
        publicKey: '59vpQgPoDEhux1G84jk6dbbARQqfUwYtohLU4fgdxFKG',
        seed: 'occur memory armor lemon wide slush risk gauge answer work small pluck inform hawk away zone robot flock flash owner fall about curve note',
      },
      withoutStakeAccount: {
        publicKey: '5Rv7YBtPikC15gHrfpdYBhn1nhpieqrGusbrKhAshYXW',
        seed: 'chase excite tomato luxury trash foster swamp scene dismiss one huge save lottery awesome throw hungry three correct door rib rib repair modify grass',
      }
    }
  }
};

export function getWalletURL(params: { testnet: boolean } = { testnet: false }) {
  const url = data.walletURLs[config.env];
  return params.testnet ? url + '?network=testnet' : url;
}
