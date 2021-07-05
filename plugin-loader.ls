require! {
    \prelude-ls : { filter, map, keys }
    \./install-plugin.ls : { get-install-list }
    \./browser/window.ls
    \../web3t/load-coins.ls
}
gobyte = require \../web3t/plugins/gobyte-coin.ls
export common = (store)->
    vlx2 = require \../web3t/plugins/vlx2-coin.ls
    btc  = require \../web3t/plugins/btc-coin.ls
    native  = require \../web3t/plugins/sol-coin.ls
    coins = [vlx2, native, btc]
    if store.url-params.gbx?
        coins.push gobyte
    coins
export get-all-coins = (store)->
    network = store.current.network
    err, coins <- load-coins {}
    coins 
        |> keys 
        |> map (-> coins[it])
export get-all-plugins = (store)->
    network = store.current.network
    err, coins <- load-coins {}
    coins 
        |> keys 
        |> map (-> coins[it])
        |> filter (-> it.token not in <[vlx2, native, btc]>)         
export get-coins = (store, cb)->
    network = store.current.network
    base =
        common store
            |> filter (?)
            |> filter (.type is \coin)
            |> filter (.enabled)
            |> filter (-> not it[network].disabled is yes)
    err, items <- get-install-list
    return cb err if err?
    installed =
        items |> filter (.type is \coin)
            |> filter (.enabled isnt no)
    all =  base ++ installed
    cb null, all