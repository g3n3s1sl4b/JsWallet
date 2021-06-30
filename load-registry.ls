require! {
    \../web3t/providers/superagent.ls : { get, post }
    \atob
    \./providers.ls
    \../web3t/plugins/btc-coin.ls : btc
    \../web3t/plugins/eth-coin.ls : eth
    \../web3t/plugins/symblox.ls : syx
    \../web3t/plugins/symblox-v2.ls : syx2
    \../web3t/plugins/ltc-coin.ls : ltc
    \../web3t/plugins/usdt-coin.ls : usdt
    \../web3t/plugins/usdt_erc20.json : usdt_erc20
    #\../web3t/plugins/gobyte-coin.js : gbx
    \../web3t/plugins/vlx_erc20-coin.ls : vlx_erc20
    \../web3t/plugins/vlx-coin.ls : vlx_evm
}
module.exports = (cb) ->
    def = [ eth, usdt, syx, syx2, usdt_erc20, ltc, vlx_erc20, vlx_evm ]
    cb null, def