#web3@0.19.1
require! {
    \prelude-ls : { obj-to-pairs, map, pairs-to-obj, each, find, keys }
    \./guid.ls
    \./send-form.ls : { wait-form-result }
    \./math.ls : { div, plus, times }
    \protect
    \./navigate.ls
    \./use-network.ls
    \./api.ls : { get-balance, get-transaction-info }
    \./install-plugin.ls : { build-install, build-uninstall, build-install-by-name, build-quick-install }
    \./refresh-account.ls : { background-refresh-account, set-account }
    \web3 : \Web3
    \./get-record.ls
    \./set-page-theme.ls
    \./mirror.ls
    \./plugin-loader.ls : { get-coins }
    \./velas/velas-api.ls
    \./send-funcs.ls
    \./pages.ls
    \./themes.ls
    \localStorage
    \./storage.js
    \assert
}

chromeStorage = new storage()

supported-themes =
    themes
        |> obj-to-pairs
        |> map (-> it.0)
state =
    time: null
titles = <[ name@email.com name.ethnamed.io domain.com ]>
show-cases = (store, [title, ...titles], cb)->
    return cb null if not title?
    store.current.send-to-mask = title
    <- set-timeout _, 1000
    <- show-cases store, titles
    return cb null
build-get-tx-history = (store, coin)-> (cb)->
    console.log "[web3.ls build-get-balance]" coin
    network = coin[store.current.network]
    wallet = store.current.account.wallets |> find (.coin.token is coin.token)
    console.log "{params}:" { coin.token, network, wallet.address }
    get-balance { coin.token, network, wallet.address }, cb
build-get-balance = (store, coin)-> (cb)->
    console.log "Callback:" cb
    return "Error: cb not defined" if not cb?
    console.log "[web3.ls build-get-balance]" coin
    network = coin[store.current.network]
    wallet = store.current.account.wallets |> find (.coin.token is coin.token)
    console.log "{params}:" { coin.token, network, wallet.address }
    err, balance <- get-balance { coin.token, network, wallet.address }
    return cb err if err?
    return cb null, balance
build-unlock = (store, cweb3)-> (cb)->
    return cb null if store.page is \locked
    err, data <- wait-form-result \unlock
    return cb err if err?
    cb null, data
build-send-transaction = (store, cweb3, coin)-> (tx, cb)->
    network = coin[store.current.network]
    return cb "Transaction is required" if typeof! tx isnt \Object
    { to, data, decoded-data, value, gas, amount, gas-price, swap } = tx
    return cb "Recipient (to) is required" if typeof! tx.to isnt \String
    value :=
        | value? => value
        | amount? => amount `times` (10 ^ network.decimals)
        | _ => null
    return cb "Either Value or Amount is required" if typeof! value not in <[ String Number ]>
    id = guid!
    { current } = store
    { send } = current
    contract-address = null
    amount-obtain = \0
    amount-obtain-usd = \0
    amount-send-usd = \0
    amount-send-fee = if network.tx-fee? then network.tx-fee else \0
    amount-send-fee-usd = \0
    details = (data ? "").length is 0
    amount-send = value `div` (10 ^ network.decimals)
    wallet = store.current.account.wallets |> find (.coin.token is coin.token)
    send <<<< {
        to, data, decoded-data, network, coin, wallet, value, gas, gas-price, id, amount-send,
        amount-obtain, amount-obtain-usd, amount-send-usd,
        amount-send-fee, amount-send-fee-usd, details,
        swap
    }
    { send-anyway, change-amount, choose-auto } = send-funcs store, web3t
    choose-auto!
    <- change-amount store, amount-send, yes
    navigate store, cweb3, \send, no
    send-anyway! if (tx.to isnt "") and (tx.swap? and tx.value isnt 0)
    helps = titles ++ [network.mask]
    err, data <- wait-form-result id
    # before cb was fired 'send-money' function is beeing executed.
    return cb err if err?
    cb null, data
get-contract-instance = (web3, abi, addr)->
    | typeof! web3.eth.contract is \Function => web3.eth.contract(abi).at(addr)
    | _ => new web3.eth.Contract(abi, addr)
build-contract = (store, methods, coin)-> (abi)-> at: (address)->
    { send-transaction } = methods
    network = coin[store.current.network]
    web3 = new Web3!
    web3.set-provider(new web3.providers.HttpProvider(network.api.web3-provider))
    web3.eth.send-transaction = ({ value, data, to, gas, gas-price }, cb)->
        send-transaction { to, data, value, gas, gas-price }, cb
    get-contract-instance web3, abi, address
build-network-ethereum = (store, methods, coin)->
    { send-transaction, get-balance, get-address } = methods
    contract = build-contract store, methods, coin
    { send-transaction, get-balance, get-address, contract }
build-other-networks = (store, methods, coin)->
    { send-transaction, get-balance, get-address, get-transaction-receipt } = methods
    contract = ->
        throw "Not Implemented For this network"
    { send-transaction, get-balance, get-address, contract, get-transaction-receipt }
build-network-specific = (store, methods, coin)->
    builder =
        | coin.token in <[ eth ]> => build-network-ethereum
        | _ => build-other-networks
    builder store, methods, coin
build-get-usd-amount = (store, coin)-> (amount, cb)->
    return cb "wallet isnt loaded" if typeof! store.current.account?wallets isnt \Array
    wallet =
        store.current.account.wallets |> find (.coin.token is coin.token)
    return cb "wallet not found for #{token}" if not wallet?
    return cb "usd rate not found #{token}" if not wallet.usd-rate?
    usd = amount `times` wallet.usd-rate
    cb null, usd
build-get-transaction-receipt = (store, cweb3, coin)-> (tx, cb)->
    network = coin[store.current.network]
    { wallet } = coin
    get-transaction-info { coin.token, network, tx }, cb
build-api = (store, cweb3, coin)->
    get-transaction-receipt = build-get-transaction-receipt store, cweb3, coin
    send-transaction = build-send-transaction store, cweb3, coin
    get-balance = build-get-balance store, coin
    get-address = build-get-address store, coin
    get-usd-amount = build-get-usd-amount store, coin
    methods = { get-address, send-transaction, get-balance, get-usd-amount, get-transaction-receipt }
    build-network-specific store, methods, coin
build-use = (web3, store)->  (network)->
    <- use-network web3, store, network
get-apis = (cweb3, store, cb)->
    res =
        store.coins
            |> map -> [it.token, build-api(store, cweb3, it)]
            |> pairs-to-obj
    cb null, res
export refresh-apis = (cweb3, store, cb)->
    store.coins |> map (.token) |> each (-> delete cweb3[it])
    cweb3.velas = velas-api store
    #console.log \refresh-apis,
    err, coins <- get-coins store
    return cb err if err?
    store.coins = coins
    err, apis <- get-apis cweb3, store
    return cb err if err?
    cweb3 <<<< apis
    cb null
setup-refresh-timer = ({ refresh-timer, refresh-balances })->
    return if typeof! refresh-timer isnt \Number
    clear-timeout setup-refresh-timer.timer
    setup-refresh-timer.timer = set-timeout refresh-balances, refresh-timer
build-get-account-name = (cweb3, naming)-> (store, cb)->
    record = get-record store
    err, data <- naming.whois record
    return cb err if err?
    cb null, data
build-get-supported-tokens = (cweb3, store)-> (cb)->
    return cb "wallet isnt loaded" if typeof! store.current.account?wallets isnt \Array
    tokens =
        store.coins
            |> map (.token)
    cb null, tokens
build-get-address = (store, coin)-> (cb)->
    return cb "wallet isnt loaded" if not mirror.account-addresses?
    address = mirror.account-addresses[coin.token]
    return cb "wallet not found for #{coin.token}" if not address?
    cb null, address
module.exports = (store, config)->
    cweb3 = {}
    #velas-web3
    refresh-timer = config?refresh-timer
    console.log "refresh-timer" config
    use = build-use cweb3, store
    install = build-install cweb3, store
    install-quick = build-quick-install cweb3, store
    uninstall = build-uninstall cweb3, store
    install-by-name = build-install-by-name cweb3, store
    naming = {}
    get-supported-tokens = build-get-supported-tokens cweb3, store
    get-account-name = build-get-account-name cweb3, naming
    refresh-balances = (cb)->
        setup-refresh-timer { refresh-timer, refresh-balances }
        err <- background-refresh-account cweb3, store
        cb? null
    setup-refresh-timer { refresh-timer, refresh-balances }
    init = (cb)->
        set-account cweb3, store, cb
    refresh-interface = (cb)->
        err <- refresh-apis cweb3, store
        return cb err if err?
        cb null
    refresh-page = (cb)->
        console.log "[refresh-page]"
        return cb null if store.current.page in  <[ wallets connectwallets ]>
        page = pages[store.current.page]
        return cb null if not page?
        return cb null if typeof! page.init isnt \Function
        <- page.init { store, web3t, call-again: no }
        return cb null if typeof! page.focus isnt \Function
        <- page.focus { store, web3t }
    refresh = (cb)->
        #return if store.current.refreshing
        err <- refresh-interface
        return cb err if err?
        err <- refresh-balances
        return cb err if err?
        refresh-page cb
        
    exitExtension = (data)->
        console.log "[exitExtension] was" {store.connected-wallet.connected-sites} 
        { sender, origin } = data
        
        transform = (obj)->
            obj
                |> obj-to-pairs
                |> map (-> [it.0, it.1.slice!])
                |> pairs-to-obj    
        cloneResult = store.connected-wallet.connected-sites
            |> obj-to-pairs
            |> map (-> [it.0, transform(it.1)])       
            |> pairs-to-obj 
        <- chromeStorage.setItem({connectedVelasSites: cloneResult}) 
        
    injectedNetworks = (data, cb)->
        { sender, origin } = data
        strip-origin = (addr)->
            protocol = (addr + "").split("://").0 + "://"
            url = (addr + "").split("://").1    
            origin = url.split(\/).0
            { site: protocol + origin, origin } 
        {site, origin} = strip-origin(origin)   
        store.connected-wallet.origin = origin
        store.connected-wallet.site = site
        store.connected-wallet.activeTab = sender
        # Check if origin who queried available networks is in connected-site array
        #console.log "store.connected-wallet" store.connected-wallet
        result <- chromeStorage.getItem("connectedVelasSites")
        #console.log ""
        #console.log "origin" origin 
        #console.log "Got data from chrome Storage" result
        #console.log "Object.keys(result.connectedVelasSites) MUST BE NON EMPTY" Object.keys(result.connectedVelasSites)
        #console.log ""
        
        #if(Object.keys(result.connectedVelasSites).length > 0 and Object.keys(result.connectedVelasSites)[0].indexOf(".") is -1)
            #throw new Error("connectedVelasSites has no origin as a property")
        
        /* Get previously connected networks Object from connectedSites property */ 
        #connectedSites = store.connected-wallet.connectedSites 
        connectedSites = store.connected-wallet.connectedSites <<<< (result?connectedVelasSites ? {})
            
        responseObject = connectedSites["#{origin}"] ? {}
        
        if result?connectedVelasSites?["#{origin}"]? then
            console.log "YEs, we have SAVED data for origin" {result.connectedVelasSites["#{origin}"]}    
        
        #console.log "****** responseObject" responseObject
        
        /* If we got data from chrome local storage update extension local storage as well */ 
        store.connected-wallet.connectedSites = connectedSites
            
        wallets_keys = 
            | store.current.account? =>
                store.current.account.wallets |> map (-> it.coin.token)
            | _ => []
        store.connected-wallet.tempChosenAccountsAllChecked = 
            | wallets_keys.length > 0 and wallets_keys.length is Object.keys(responseObject).length => yes 
            | _ => no  
        
        /* Update temporary chosen wallets for import  */
        store.connected-wallet.tempChosenGroups = Object.keys(responseObject)
        #console.log "Update temporary chosen wallets for import" Object.keys(responseObject)
        /* Update chosen acccounts for wallet for certain domain */
        store.connected-wallet.chosenNetworks = responseObject 
        #console.log "Update chosen acccounts for wallet for certain domain" responseObject
           
        
        tabs <- chrome.tabs.query { currentWindow: true active: true }
        activeTab = tabs?0
        response <- chrome.tabs.sendMessage sender, { networks: responseObject }
        #console.log "Extension response sent", response 
        cb null
        
    /* [Extension] Open choose accounts to import screen initiated by client. */
    injectAccounts = (data, cb)->
        whom = store.connected-wallet.activeTab
        return cb "active client`s Tab was not defined" if not whom?
        #console.log "[injectedAccounts] data" data
        store.connected-wallet.status.queried = yes
        navigate store, cweb3, \connectwallets
        /* Send response */
        #tabs <- chrome.tabs.query { currentWindow: true active: true }
        #activeTab = tabs?0
        #response <- chrome.tabs.sendMessage whom, {"myResponse": "Response from extension"}
        #console.log "confirm response", response 
        cb null
    set-theme = (it)!->
        return if it not in supported-themes
        store.theme = it
        localStorage.set-item \theme, it
        set-page-theme store, it
    set-lang = (it, cb)->
        return cb "support only en, ru" if it not in <[ en ru uk ]>
        store.lang = it
        cb null
    set-preference = (preference)->
        set = (key)->
            return if keys not in <[ disablevlx1 ]>
            store.preference[key] = preference[key] ? store.preference[key]
        store.preference |> keys |> each set
    lock = ->
        navigate store,  , \locked
    unlock = build-unlock store, cweb3
    set-preference config if typeof! config is \Object
    refresh-interface ->
    web3 = new Web3!
    velas = velas-api store
    cweb3 <<<< { velas, exitExtension, injectedNetworks, refresh-balances, refresh-interface, injectAccounts, web3.utils, unlock, set-preference, get-supported-tokens, use, refresh, lock, init, install, uninstall, install-by-name, naming, get-account-name, set-theme, set-lang, install-quick }
    cweb3