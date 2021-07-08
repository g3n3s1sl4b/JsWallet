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
    }
  }
};

export function getWalletURL(params: { testnet: boolean } = { testnet: false }) {
  const url = data.walletURLs[config.env];
  return params.testnet ? url + '?network=testnet' : url;
}
