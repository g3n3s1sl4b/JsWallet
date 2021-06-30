import { config } from "./config";

export const data = {
  seedPhrase: ["decade", "cargo", "toe", "library", "cycle", "furnace", "idea", "tourist", "fuel", "chimney", "fury", "actual", "cash", "scheme", "race", "reason", "finger", "pulp", "nature", "family", "language", "spring", "kidney", "ancient"],
  walletURLs: {
    local: 'localhost:8080/main-index.html',
    devnet: '',
    mainnet: 'https://wallet.velas.com/',
    testnet: 'https://wallet.testnet.velas.com/',
  }
};

export const walletURL = data.walletURLs[config.env];
