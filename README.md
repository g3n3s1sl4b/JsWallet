# Velas Multi-Currency Wallet



### Install Web Wallet on your server

1. mkdir wallet-area
2. cd wallet-area
1. git clone https://github.com/velas/JsWallet wallet
2. git clone http://github.com/velas/web3t
3. cd web3t
4. npm i 
5. cd ../wallet
6. npm i 
7. npm i lsxc -g
7. npm run wallet-start
8. open http://127.0.0.1:8080

Tested with `node --version` v11.10.1


### Run wallet locally
(Works on node 14.16)
1. `npm i lsxc -g`
2. `git clone https://github.com/velas/JsWallet`
#### Prepare web3t
2. `git clone http://github.com/velas/web3t`
3. `cd web3t`
4. `npm i`
5. Delete git cache and copy web3t to JsWallet
6. `cd .. && rm -rf JsWallet/.compiled-ssr/web3t/.git/objects/ && mkdir -p JsWallet/.compiled-ssr/web3t/ && cp -pr web3t/ JsWallet/.compiled-ssr/web3t/`
7. `cd JsWallet`
8. `npm run wallet-start`
9. open `localhost:8080/main-index.html`


### Run e2e tests
Please refer to e2e/README.md

### Features

* All coins managed by single mnemonic pharse
* Ability to install/uninstall other coins from github repository
* Web3 api support for multi-currency

### Supported Browsers:

* Chrome
* Mozilla 
* Opera
* Safari

### Supported Sreens: 

* Mobile - Compact Design
* Desktop - Extended Design with Transaction History 

### Supported Coins

* VLX
* BTC (+ All OMNI)
* LTC
* DASH
* ETH (+ All ERC20)
* ETC
* USDT (+ USDT_ERC20)
* and other less known
