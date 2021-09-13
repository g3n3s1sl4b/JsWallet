require! {
    \mobx : { toJS }
    \./math.ls : { times, minus, div, plus }
    \./api.ls : { create-transaction, push-tx }
    \./calc-amount.ls : { change-amount-calc-fiat, change-amount-send, change-amount, calc-crypto-from-eur, calc-crypto-from-usd, change-amount-without-fee }
    \./send-form.ls : { notify-form-result }
    \./get-name-mask.ls
    \./resolve-address.ls
    \./browser/window.ls
    \./navigate.ls
    \bignumber.js
    \./close.ls
    \./round.ls
    \./round5.ls
    \./round5edit.ls
    \./round-number.ls  
    \./round-human.ls  
    \./topup.ls
    \./get-primary-info.ls
    \./pending-tx.ls : { create-pending-tx }
    \./transactions.ls : { rebuild-history }
    \prelude-ls : { map, find }
    \./web3.ls
    \./api.ls : { calc-fee }
    \./pages/confirmation.ls : { confirm }
    \./get-lang.ls
    \./apply-transactions.ls
    \./get-tx-details.ls
    \ethereumjs-util : {BN}
    \bs58
    \assert   
    \./velas/velas-web3.ls
}


abis =
    Staking      : require("../web3t/contracts/StakingAuRa.json").abi
    ValidatorSet : require("../web3t/contracts/ValidatorSetAuRa.json").abi
    BlockReward  : require("../web3t/contracts/BlockRewardAuRa.json").abi
    Development  : require("../web3t/contracts/VelasDevelopment.json").abi
    Resolver     : require("../web3t/contracts/LockupResolver.json").abi
    Timelock     : require("../web3t/contracts/LockupTimelock.json").abi
    EvmToNativeBridge: require("../web3t/contracts/EvmToNativeBridge.json").abi 
    HomeBridgeNativeToErc  : require("../web3t/contracts/HomeBridgeNativeToErc.json").abi 
    ForeignBridgeNativeToErc : require("../web3t/contracts/ForeignBridgeNativeToErc.json").abi 
    ERC20BridgeToken: require("../web3t/contracts/ERC20BridgeToken.json").abi    
    ERC677BridgeToken: require("../web3t/contracts/ERC20BridgeToken.json").abi
    HomeERC677Bridge: require("../web3t/contracts/HomeBridgeNativeToErc.json").abi 
    ForeignBridgeErcToErc: require("../web3t/contracts/ForeignBridgeErcToErc.json").abi

module.exports = (store, web3t)->
    return null if not store? or not web3t?
    lang = get-lang store
    #{ send-to } = web3t?naming
    { send } = store.current
    { wallet, fee-type } = send
    return null if not wallet?
    color = get-primary-info(store).color
    primary-button-style =
        background: color
    default-button-style = { color }
    send-tx = ({ to, wallet, network, amount-send, amount-send-fee, data, coin, tx-type, gas, gas-price, swap }, cb)->
        { token } = send.coin
        current-network = store.current.network 
        chosen-network = store.current.send.chosen-network
        receiver = store.current.send.contract-address ? to    
        recipient =
            | receiver.starts-with \V => to-eth-address(receiver)     
            | _ => receiver
        tx-obj =
            account: { wallet.address, wallet.private-key, wallet.secret-key }
            recipient: recipient
            network: network
            token: token
            coin: coin
            amount: amount-send
            amount-fee: amount-send-fee
            data: data
            gas: gas
            gas-price: gas-price
            fee-type: fee-type
            swap: swap
        #console.log "pass to create-tx -->" { gas, gas-price }    
        err, tx-data <- create-transaction tx-obj
        return cb err if err?
        parts = get-tx-details store
        agree <- confirm store, parts.0
        return cb null if not agree
        err, tx <- push-tx { token, tx-type, network, ...tx-data }
        if err? 
            if (err.toString()).indexOf("Insufficient priority. Code:-26. Please try to increase fee") then
                store.current.send.error = err
                <- set-timeout _, 2000
                store.current.send.error = ""
            return cb err   
        err <- create-pending-tx { store, token, recipient, network, tx, amount-send, amount-send-fee, send.to, from: wallet.address }
        cb err, tx
        
    perform-send-safe = (cb)->
        err, to <- resolve-address { store, address: send.to, coin: send.coin, network: send.network }
        _coin = if send.coin.token is \vlx2 then \vlx else send.coin.token   
        err = "Address is not valid #{_coin} address" if err? and err.index-of "Invalid checksum"
        resolved =
            | err? => send.to
            | _ => to
        send.to = resolved
        send.error = err if err?
        return cb err if err?
        send-tx { wallet, ...send }, cb
        
    perform-send-unsafe = (cb)->
        send-tx { wallet, ...send }, cb
        
    check-enough = (cb)->
        txFeeIn = wallet?network?txFeeIn
        fee = 
            | not txFeeIn? or txFeeIn isnt wallet?coin?token => 0
            | _ => send.amount-send-fee
        try
            amount = wallet.balance `minus` send.amount-send `minus` (wallet.pending-sent ? 0) `minus` fee
            return cb "Not Enough funds" if +amount < 0
            cb null
        catch err
            cb err
            
    send-money = ->
        return if wallet.balance is \...
        return if send.sending is yes
        err <- check-enough
        console.error "[check-enough]: " + err if err?    
        return send.error = "#{err.message ? err}" if err?
        send.sending = yes
        err, data <- perform-send-safe
        send.sending = no
        return send.error = "#{err.message ? err}" if err?
        return cb err if err?    
        # If cancel was pressed
        return null if not data?
        notify-form-result send.id, null, data
        store.current.last-tx-url = | send.network.api.linktx => send.network.api.linktx.replace \:hash, data
            | send.network.api.url => send.network.api.url + "/tx/#{data}"
        navigate store, web3t, \sent
        <- web3t.refresh
        
    send-escrow = ->
        name = send.to
        amount-ethers = send.amount-send
        #err <- send-to { name, amount-ethers }
    
    up = (str)->
        (str ? "").trim!.to-upper-case!    
    
    is-self-send = up(wallet.address) is up(store.current.send.to)  
    
    /* DONE! */    
    /* 
    * Swap from USDC to USDC VELAS
    */  
    usdc_to_usdc_velas_swap = (token, chosen-network, cb)->   
        return cb null if not (token is \usdc and chosen-network.id is \vlx_usdc)

        web3 = velas-web3 store
        { FOREIGN_BRIDGE, FOREIGN_BRIDGE_TOKEN } = wallet.network  
                        
        value = store.current.send.amountSend 
        value = (value `times` (10^6))  
        receiver = send.to 
        
        # Check for allowance 
        web3 = new Web3(new Web3.providers.HttpProvider(wallet.network.api.web3Provider))
        web3.eth.provider-url = wallet.network.api.web3Provider
        contract = web3.eth.contract(abis.ForeignBridgeErcToErc).at(FOREIGN_BRIDGE_TOKEN)
        
        /*---*/       
                
        value = store.current.send.amountSend 
        value = (value `times` (10^6))  
        receiver = send.to    
        
        /* Check for allowed amount for contract */
        allowedRaw = contract.allowance(wallet.address, FOREIGN_BRIDGE)
        allowed = allowedRaw `div` (10 ^ wallet.network.decimals)    

        { coin, gas, gas-price, amount-send, amount-send-fee, fee-type, network, tx-type } = send 
             
        web3 = new Web3(new Web3.providers.HttpProvider(wallet?network?api?web3Provider))
        web3.eth.provider-url = wallet?network?api?web3Provider            
        contract = web3.eth.contract(abis.ForeignBridgeErcToErc).at(FOREIGN_BRIDGE)  
                
        minPerTxRaw = contract.minPerTx!  
        minPerTx = minPerTxRaw `div` (10 ^ 6)  
        if +send.amountSend < +(minPerTx) then
            return cb "Min amount per transaction is #{minPerTx} USDC"
        maxPerTxRaw = contract.maxPerTx!
        maxPerTx = maxPerTxRaw `div` (10 ^ 6)                
        if +send.amountSend > +(maxPerTx) then
            return cb "Max amount per transaction is #{maxPerTx} USDC"
            
        err <- check-allowed-amount { contract, wallet, amount: send.amountSend, allowed, bridge: FOREIGN_BRIDGE, bridgeToken: FOREIGN_BRIDGE_TOKEN }
        return cb err if err? 
        
        data = 
           | is-self-send is yes => contract.transfer.get-data(FOREIGN_BRIDGE, value)
           | _ => contract.relayTokens.get-data(receiver, value) 
       
        contract-address =
           | is-self-send is yes => FOREIGN_BRIDGE_TOKEN
           | _ => FOREIGN_BRIDGE     
        
        store.current.send.contract-address = contract-address
        store.current.send.data = data
                  
        cb null, data  
        
    /* DONE! */    
    /* 
    * Swap from USDC VELAS to USDC
    */     
    usdc_velas_to_usdc_swap = (token, chosen-network, cb)->     
        return cb null if not (token is \vlx_usdc and chosen-network.id is \usdc)

        web3 = velas-web3 store
        { HOME_BRIDGE, HOME_BRIDGE_TOKEN } = wallet.network
        return cb "HOME_BRIDGE is not defined" if not HOME_BRIDGE?
        return cb "HOME_BRIDGE_TOKEN is not defined" if not HOME_BRIDGE_TOKEN?
                        
        value = store.current.send.amountSend 
        value = (value `times` (10^6))  
        receiver = send.to 
        
        web3 = new Web3(new Web3.providers.HttpProvider(wallet?network?api?web3Provider))
        web3.eth.provider-url = wallet?network?api?web3Provider
        contract = web3.eth.contract(abis.ERC20BridgeToken).at(HOME_BRIDGE)    
 
        { network } = wallet   
        try 
            minPerTxRaw = contract.minPerTx!  
            minPerTx = minPerTxRaw `div` (10 ^ 6)  
            if +send.amountSend < +(minPerTx) then
                return cb "Min amount per transaction is #{minPerTx} USDC"
            maxPerTxRaw = contract.maxPerTx!
            maxPerTx = maxPerTxRaw `div` (10 ^ 6) 
            if +send.amountSend > +(maxPerTx) then
                return cb "Max amount per transaction is #{maxPerTx} USDC"
        catch err
            return cb err if err?    
        
        data = contract.transferAndCall.get-data(HOME_BRIDGE, value, send.to)
        store.current.send.contract-address = HOME_BRIDGE_TOKEN
        store.current.send.data = data  
        cb null, data
    
    /* DONE! */
    busd_velas_to_busd_swap = (token, chosen-network, cb)->
        return cb null if not (token is \vlx_busd and chosen-network.id is \busd)

        web3 = velas-web3 store
        { HOME_BRIDGE, HOME_BRIDGE_TOKEN } = wallet.network  
                        
        value = store.current.send.amountSend 
        value = (value `times` (10^18))  
        receiver = send.to 
        
        web3 = new Web3(new Web3.providers.HttpProvider(wallet?network?api?web3Provider))
        web3.eth.provider-url = wallet?network?api?web3Provider
        contract = web3.eth.contract(abis.ERC20BridgeToken).at(HOME_BRIDGE)    
 
        { network } = wallet   
        
        minPerTxRaw = contract.minPerTx!  
        minPerTx = minPerTxRaw `div` (10 ^ 18)  
        if +send.amountSend < +(minPerTx) then
            return cb "Min amount per transaction is #{minPerTx} BUSD"
        maxPerTxRaw = contract.maxPerTx!
        maxPerTx = maxPerTxRaw `div` (10 ^ 18) 
        if +send.amountSend > +(maxPerTx) then
            return cb "Max amount per transaction is #{maxPerTx} BUSD"
        
        data = contract.transferAndCall.get-data(HOME_BRIDGE, value, send.to)
        store.current.send.contract-address = HOME_BRIDGE_TOKEN
        store.current.send.data = data
            
        cb null, data    
    
    /* DONE! */
    busd_to_busd_velas_swap = (token, chosen-network, cb)->
        return cb null if not (token is \busd and chosen-network.id is \vlx_busd) 
        { wallets } = store.current.account
        chosen-network-wallet = wallets |> find (-> it.coin.token is chosen-network.id)
        return cb "[Swap error]: wallet #{chosen-network.id} is not found!" if not chosen-network-wallet? 
        
        { FOREIGN_BRIDGE, FOREIGN_BRIDGE_TOKEN } = wallet.network        
        
        web3 = new Web3(new Web3.providers.HttpProvider(wallet.network.api.web3Provider))
        web3.eth.provider-url = wallet.network.api.web3Provider
        contract = web3.eth.contract(abis.ForeignBridgeErcToErc).at(FOREIGN_BRIDGE_TOKEN)    
                
        value = store.current.send.amountSend 
        value = (value `times` (10^18))  
        receiver = send.to
        
        /* Check for allowed amount for contract */
        allowedRaw = contract.allowance(wallet.address, FOREIGN_BRIDGE)
        allowed = allowedRaw `div` (10 ^ 0)   
 
        contract = web3.eth.contract(abis.ForeignBridgeErcToErc).at(FOREIGN_BRIDGE)         
        minPerTxRaw = contract.minPerTx!         
        minPerTx = minPerTxRaw `div` (10 ^ 18)  
        if +send.amountSend < +(minPerTx) then
            return cb "Min amount per transaction is #{minPerTx} BUSD"
        maxPerTxRaw = contract.maxPerTx!
        maxPerTx = maxPerTxRaw `div` (10 ^ 18)                
        if +send.amountSend > +(maxPerTx) then
            return cb "Max amount per transaction is #{maxPerTx} BUSD"
            
        err <- check-allowed-amount { contract, wallet, amount: send.amountSend, allowed, bridge: FOREIGN_BRIDGE, bridgeToken: FOREIGN_BRIDGE_TOKEN  }
        return cb err if err?
        
        data = 
            | is-self-send is yes => contract.transfer.get-data(FOREIGN_BRIDGE, value)
            | _ => contract.relayTokens.get-data(receiver, value) 
        
        contract-address =
            | is-self-send is yes => FOREIGN_BRIDGE_TOKEN
            | _ => FOREIGN_BRIDGE  
        
        store.current.send.contract-address = contract-address
        store.current.send.data = data    
        cb null, data    
    checking-allowed = no   
    /* Check for allowed amount for contract */
    check-allowed-amount = ({ contract, wallet, amount, allowed, bridge, bridgeToken }, cb)->
        return if checking-allowed
        return cb null if is-self-send is yes 
        return cb "bridge is not defined" if not bridge? 
        return cb "bridgeToken is not defined" if not bridgeToken? 

        return cb null if allowed >= amount
        
        token = (wallet?coin?nickname ? "").to-upper-case!    
        
        agree <- confirm store, "To execute this swap please approve that bridge contract can withdraw your #{token} and automate payments for you."
        return cb "Canceled by user" if not agree   
        
        UINT_MAX_NUMBER = 4294967295 `times` (10 ^ wallet.network.decimals)
        { coin, gas, gas-price, amount-send, amount-send-fee, fee-type, network, tx-type } = send 
        data = contract.approve.get-data(bridge, UINT_MAX_NUMBER) 
        tx-obj =
            account: { wallet.address, wallet.private-key}
            recipient: bridgeToken
            network: network
            token: token
            coin: coin
            amount: "0"
            amount-fee: "0.002"    
            data: data
            gas: 50000
            gas-price: gas-price   
            fee-type: fee-type
        
        err, tx-data <- create-transaction tx-obj
        return cb err if err?
        checking-allowed = yes   
        err, tx <- push-tx { token, tx-type, network, ...tx-data }
        return cb err if err?
        checking-allowed = no 
        cb null
        
   
    /* 
    * Swap from USDT ETHEREUM to USDT VELAS 
    */     
    eth_usdt-usdt_velas-swap = (token, chosen-network, cb)->     
        return cb null if not (token is \usdt_erc20 and chosen-network.id is \vlx_usdt)
        #console.log "eth_usdt-usdt_velas-swap"   
        web3 = velas-web3 store
        { FOREIGN_BRIDGE, FOREIGN_BRIDGE_TOKEN } = wallet.network
        return cb "FOREIGN_BRIDGE is not defined" if not FOREIGN_BRIDGE?
        return cb "FOREIGN_BRIDGE_TOKEN is not defined" if not FOREIGN_BRIDGE_TOKEN?
                        
        value = store.current.send.amountSend 
        value = (value `times` (10^6))  
        receiver = send.to
        
        web3 = new Web3(new Web3.providers.HttpProvider(wallet?network?api?web3Provider))
        web3.eth.provider-url = wallet?network?api?web3Provider
        contract = web3.eth.contract(abis.ForeignBridgeErcToErc).at(FOREIGN_BRIDGE_TOKEN)
        
        allowedRaw = contract.allowance(wallet.address, FOREIGN_BRIDGE)
        allowed = allowedRaw `div` (10 ^ 0) 

        { network } = wallet   
        contract = web3.eth.contract(abis.ForeignBridgeErcToErc).at(FOREIGN_BRIDGE)  
     
        minPerTxRaw = contract.minPerTx!  
        minPerTx = minPerTxRaw `div` (10 ^ 6)  
        if +send.amountSend < +(minPerTx) then
            return cb "Min amount per transaction is #{minPerTx} USDT"
        maxPerTxRaw = contract.maxPerTx!
        maxPerTx = maxPerTxRaw `div` (10 ^ 6)                
        if +send.amountSend > +(maxPerTx) then
            return cb "Max amount per transaction is #{maxPerTx} USDT"
            
        /* Check for allowed amount for contract */    
        err <- check-allowed-amount { contract, wallet, amount: send.amountSend, allowed, bridge: FOREIGN_BRIDGE, bridgeToken: FOREIGN_BRIDGE_TOKEN }       
        return cb err if err? 
        
        current-network = store.current.network    
        
        data = 
            | is-self-send is yes => contract.transfer.get-data(FOREIGN_BRIDGE, value)
            | _ => contract.relayTokens.get-data(receiver, value)
       
        contract-address =
           | is-self-send is yes => FOREIGN_BRIDGE_TOKEN
           | _ => FOREIGN_BRIDGE    
        
        store.current.send.contract-address = contract-address
        store.current.send.data = data   
        cb null, data 
        
    
        
    /* 
    * Swap from USDT VELAS to USDT ETHEREUM
    */     
    usdt_velas-eth_usdt-swap = (token, chosen-network, cb)->     
        return cb null if not (token is \vlx_usdt and chosen-network.id is \usdt_erc20)

        web3 = velas-web3 store
        { HOME_BRIDGE, HOME_BRIDGE_TOKEN } = wallet.network  
                        
        value = store.current.send.amountSend 
        value = (value `times` (10^6))  
        receiver = send.to 
        
        web3 = new Web3(new Web3.providers.HttpProvider(wallet?network?api?web3Provider))
        web3.eth.provider-url = wallet?network?api?web3Provider
        contract = web3.eth.contract(abis.ERC20BridgeToken).at(HOME_BRIDGE)  
        
        contract2 = web3.eth.contract(abis.ForeignBridgeErcToErc).at(HOME_BRIDGE) 
        try
            totalSupply = contract2.totalSupply()
        catch err    
 
        { network } = wallet   
        
        minPerTxRaw = contract.minPerTx!  
        minPerTx = minPerTxRaw `div` (10 ^ 6)  
        if +send.amountSend < +(minPerTx) then
            return cb "Min amount per transaction is #{minPerTx} USDT"
        maxPerTxRaw = contract.maxPerTx!
        maxPerTx = maxPerTxRaw `div` (10 ^ 6) 
        if +send.amountSend > +(maxPerTx) then
            return cb "Max amount per transaction is #{maxPerTx} USDT"
        
        data = contract.transferAndCall.get-data(HOME_BRIDGE, value, send.to)
        store.current.send.contract-address = HOME_BRIDGE_TOKEN
        store.current.send.data = data
            
        cb null, data        
        
    execute-contract-data = (cb)->
        return cb null if not store.current.send.chosen-network?
        chosen-network = store.current.send.chosen-network
        token = store.current.send.coin.token
        if chosen-network.id in <[ evm legacy ]> and token in <[ vlx_evm vlx2 ]>   
            store.current.send.contractAddress = null 
            return cb null 
        wallet = store.current.send.wallet  
        contract-address = store.current.send.contract-address     
        data = ""
        send.swap = yes 
                            
        /* DONE! */
        dummy = (a, b, cb)-> 
            cb null       
        func = 
            | token is \usdt_erc20 and chosen-network.id is \vlx_usdt =>
                /* Swap from USDT ETHEREUM to USDT VELAS  */ 
                eth_usdt-usdt_velas-swap 
            
            | token is \vlx_usdt and chosen-network.id is \usdt_erc20 =>
                /* Swap from USDT VELAS to USDT ETHEREUM */ 
                usdt_velas-eth_usdt-swap
                
            | token is \busd and chosen-network.id is \vlx_busd =>
                /* Swap from BUSD to BUSD VELAS */ 
                busd_to_busd_velas_swap  
                
            | token is \vlx_busd and chosen-network.id is \busd =>
                /* Swap from BUSD VELAS to BUSD */
                busd_velas_to_busd_swap
                
            | token is \usdc and chosen-network.id is \vlx_usdc =>
                /* Swap from USDC to USDC VELAS */
                usdc_to_usdc_velas_swap
                
            | token is \vlx_usdc and chosen-network.id is \usdc =>
                /* Swap from USDC VELAS to USDC */
                usdc_velas_to_usdc_swap
                   
            | _ => dummy   
        err, data <- func(token, chosen-network)
        return cb err if err?
        
        /* DONE */
        /* Swap from VELAS EVM to HECO */
        if token is \vlx_evm and chosen-network.id is \vlx_huobi then
            { wallets } = store.current.account
            chosen-network-wallet = wallets |> find (-> it.coin.token is chosen-network.id)
            return cb "[Swap error]: wallet #{chosen-network.id} is not found!" if not chosen-network-wallet?
            
            { HECO_SWAP__HOME_BRIDGE } = wallet.network
            
            web3 = new Web3(new Web3.providers.HttpProvider(wallet?network?api?web3Provider))
            web3.eth.provider-url = wallet?network?api?web3Provider
            contract = web3.eth.contract(abis.HomeBridgeNativeToErc).at(HECO_SWAP__HOME_BRIDGE) 
                   
            receiver = store.current.send.to 
            network = wallet.network    
            minPerTxRaw = contract.minPerTx!
            minPerTx = minPerTxRaw `div` (10 ^ network.decimals)
            maxPerTxRaw = contract.maxPerTx! 
            maxPerTx = maxPerTxRaw `div` (10 ^ network.decimals)     
            
            data = contract.relayTokens.get-data(receiver)
            
            if +send.amountSend < +(minPerTx) then
                return cb "Min amount per transaction is #{minPerTx} VLX"
            if +send.amountSend > +maxPerTx then
                return cb "Max amount per transaction is #{maxPerTx} VLX" 
            send.data = data
            store.current.send.contract-address = HECO_SWAP__HOME_BRIDGE   

        /* DONE! */
        /* Swap from HECO to VELAS EVM */
        if token is \vlx_huobi and chosen-network.id is \vlx_evm
        
            value = store.current.send.amountSend
            value = value `times` (10^18)
            
            { FOREIGN_BRIDGE, FOREIGN_BRIDGE_TOKEN } = wallet.network
            
            return cb "FOREIGN_BRIDGE is not defined" if not FOREIGN_BRIDGE?
            return cb "FOREIGN_BRIDGE_TOKEN is not defined" if not FOREIGN_BRIDGE_TOKEN?    
            
            web3 = new Web3(new Web3.providers.HttpProvider(wallet?network?api?web3Provider))
            web3.eth.provider-url = wallet?network?api?web3Provider
            contract = web3.eth.contract(abis.ForeignBridgeNativeToErc).at(FOREIGN_BRIDGE)
            
            { network } = wallet  
            /*  Get minPerTx from HomeBridge */  
            minPerTxRaw = contract.minPerTx!
            minPerTx = minPerTxRaw `div` (10 ^ network.decimals)
            
            /* Get maxPerTx from HomeBridge */
            maxPerTxRaw = contract.maxPerTx!
            maxPerTx = maxPerTxRaw `div` (10 ^ network.decimals)
            
            #homeFeeRaw = contract.getHomeFee! 
            #homeFee = homeFeeRaw `div` (10 ^ network.decimals)
            #console.log "vlx_huobi homeFee" homeFee    
            #contract-home-fee = send.amountSend `times` homeFee
            
            if +send.amountSend < +(minPerTx) then
                return cb "Min amount per transaction is #{minPerTx} VLX"
            if +send.amountSend > +maxPerTx then
                return cb "Max amount per transaction is #{maxPerTx} VLX"
            
            contract = web3.eth.contract(abis.ForeignBridgeNativeToErc).at(FOREIGN_BRIDGE_TOKEN)  

            data = 
                | is-self-send is yes => contract.transfer.get-data(FOREIGN_BRIDGE, to-hex(value), send.to)
                | _ => contract.transferAndCall.get-data(FOREIGN_BRIDGE, value, send.to)              
            
            send.data = data
            send.contract-address = FOREIGN_BRIDGE_TOKEN
        
        /* DONE! */    
        /* Swap from VELAS EVM to HECO */
        if token is \vlx_evm and chosen-network.id is \bsc_vlx then
            { wallets } = store.current.account
            chosen-network-wallet = wallets |> find (-> it.coin.token is chosen-network.id)
            return cb "[Swap error]: wallet #{chosen-network.id} is not found!" if not chosen-network-wallet?
            
            { BSC_SWAP__HOME_BRIDGE, ERC20BridgeToken } = wallet.network
            
            web3 = new Web3(new Web3.providers.HttpProvider(wallet?network?api?web3Provider))
            web3.eth.provider-url = wallet?network?api?web3Provider
            contract = web3.eth.contract(abis.HomeBridgeNativeToErc).at(BSC_SWAP__HOME_BRIDGE) 
                   
            receiver = store.current.send.to 
            network = wallet.network    
            minPerTxRaw = contract.minPerTx!
            minPerTx = minPerTxRaw `div` (10 ^ network.decimals)
            maxPerTxRaw = contract.maxPerTx! 
            maxPerTx = maxPerTxRaw `div` (10 ^ network.decimals)    
            
            #homeFeeRaw = contract.getHomeFee! 
            #homeFee = homeFeeRaw `div` (10 ^ network.decimals)
            
            data = 
               | is-self-send is yes => contract.transfer.get-data(BSC_SWAP__HOME_BRIDGE, value)
               | _ => contract.relayTokens.get-data(receiver) 
           
            contract-address =
               | is-self-send is yes => ERC20BridgeToken
               | _ => BSC_SWAP__HOME_BRIDGE  
            
            data = contract.relayTokens.get-data(receiver)
            amount-to-send = send.amount-send-fee `plus` send.amount-send   
            
            if +send.amountSend < +(minPerTx) then
                return cb "Min amount per transaction is #{minPerTx} VLX"
            if +send.amountSend > +maxPerTx then
                return cb "Max amount per transaction is #{maxPerTx} VLX" 
            send.data = data
            store.current.send.contract-address = BSC_SWAP__HOME_BRIDGE
            
        /* Swap from BSC VELAS to VELAS EVM */
        if token is \bsc_vlx and chosen-network.id is \vlx_evm
        
            value = store.current.send.amountSend
            value = value `times` (10^18)
            
            { FOREIGN_BRIDGE, FOREIGN_BRIDGE_TOKEN } = wallet.network
            
            web3 = new Web3(new Web3.providers.HttpProvider(wallet?network?api?web3Provider))
            web3.eth.provider-url = wallet?network?api?web3Provider
            contract = web3.eth.contract(abis.ForeignBridgeNativeToErc).at(FOREIGN_BRIDGE)
            
            { network } = wallet  
             
            /* Get minPerTx from HomeBridge */ 
            minPerTxRaw = contract.minPerTx!
            minPerTx = minPerTxRaw `div` (10 ^ network.decimals)
             
            /* Get maxPerTx from HomeBridge */
            maxPerTxRaw = contract.maxPerTx!
            maxPerTx = maxPerTxRaw `div` (10 ^ network.decimals)
            
            #homeFeeRaw = contract.getHomeFee! 
            #homeFee = homeFeeRaw `div` (10 ^ network.decimals)
            
            if +send.amountSend < +(minPerTx) then
                return cb "Min amount per transaction is #{minPerTx} VLX"
            if +send.amountSend > +maxPerTx then
                return cb "Max amount per transaction is #{maxPerTx} VLX"
            
            contract = web3.eth.contract(abis.ForeignBridgeNativeToErc).at(FOREIGN_BRIDGE_TOKEN) 
            
            data = 
                | is-self-send is yes => contract.transfer.get-data(FOREIGN_BRIDGE, to-hex(value), send.to)
                | _ => contract.transferAndCall.get-data(FOREIGN_BRIDGE, value, send.to)              

            send.data = data
            send.contract-address = FOREIGN_BRIDGE_TOKEN
  
        
        /* DONE! */
        /* Swap from ETH to ETHEREUM (VELAS) */ 
        if token is \eth and chosen-network.id is \vlx_eth then
        
            { wallets } = store.current.account
            chosen-network-wallet = wallets |> find (-> it.coin.token is chosen-network.id)
            return cb "[Swap error]: wallet #{chosen-network.id} is not found!" if not chosen-network-wallet? 
            
            value = store.current.send.amountSend 
            value = to-hex (value `times` (10^18)) 
            
            { HOME_BRIDGE } = wallet.network
            
            web3 = new Web3(new Web3.providers.HttpProvider(wallet.network.api.web3Provider))
            web3.eth.provider-url = wallet.network.api.web3Provider
            contract = web3.eth.contract(abis.HomeBridgeNativeToErc).at(HOME_BRIDGE)
            
            store.current.send.contract-address = HOME_BRIDGE
            receiver = send.to
            minPerTxRaw = contract.minPerTx!
            { network } = wallet        
            minPerTx = minPerTxRaw `div` (10 ^ network.decimals)                
            if +send.amountSend < +(minPerTx) then
                return cb "Min amount per transaction is #{minPerTx} ETH"
            maxPerTxRaw = contract.maxPerTx!
            maxPerTx = maxPerTxRaw `div` (10 ^ network.decimals)                
            if +send.amountSend > +(maxPerTx) then
                return cb "Max amount per transaction is #{maxPerTx} ETH"          
            data = contract.relayTokens.get-data(receiver)
            #data = contract.relayTokens.get-data(receiver)
            send.data = data 

        /* DONE! */
        /* Swap from ETHEREUM (VELAS) to ETH  */ 
        if token is \vlx_eth and chosen-network.id is \eth then
        
            value = store.current.send.amountSend
            value = (value `times` (10^18))
            network = wallet.network
            
            { FOREIGN_BRIDGE, FOREIGN_BRIDGE_TOKEN } = wallet.network    

            web3 = new Web3(new Web3.providers.HttpProvider(wallet.network.api.web3Provider))
            web3.eth.provider-url = wallet.network.api.web3Provider
            contract = web3.eth.contract(abis.ERC20BridgeToken).at(FOREIGN_BRIDGE)

            try
                minPerTxRaw = contract.minPerTx!
                minPerTx = minPerTxRaw `div` (10 ^ network.decimals)
                if +send.amountSend < +(minPerTx) then
                    return cb "Min amount per transaction is #{minPerTx} ETH"

                maxPerTxRaw = contract.maxPerTx!
                maxPerTx = maxPerTxRaw `div` (10 ^ network.decimals)
                if +send.amountSend > +maxPerTx then
                    return cb "Max amount per transaction is #{maxPerTx} ETH"
            catch err
                return cb err

            contract = web3.eth.contract(abis.ERC20BridgeToken).at(FOREIGN_BRIDGE_TOKEN)
            #data = contract.transferAndCall.get-data(FOREIGN_BRIDGE, value, send.to)
            data = contract.transferAndCall.get-data(FOREIGN_BRIDGE, value, send.to)
            send.data = data
            send.contract-address = FOREIGN_BRIDGE_TOKEN

        
        
        /* DONE */
        /* Swap from VLX ERC20 to COIN VLX */    
        if token is \vlx_erc20 and chosen-network.id in <[ vlx_evm vlx2 ]>
            value = store.current.send.amountSend
            value = (value `times` (10^18))
            network = wallet.network

            { FOREIGN_BRIDGE, FOREIGN_BRIDGE_TOKEN } = wallet.network

            web3 = new Web3(new Web3.providers.HttpProvider(wallet.network.api.web3Provider))
            web3.eth.provider-url = wallet.network.api.web3Provider
            contract = web3.eth.contract(abis.ForeignBridgeNativeToErc).at(FOREIGN_BRIDGE)

            /* Get minPerTx from HomeBridge */
            minPerTxRaw = contract.minPerTx!
            minPerTx = minPerTxRaw `div` (10 ^ network.decimals)
           
            /* Get maxPerTx from HomeBridge */
            maxPerTxRaw = contract.maxPerTx!
            maxPerTx = maxPerTxRaw `div` (10 ^ network.decimals)
            
            #homeFeeRaw = contract.getHomeFee!
            #homeFee = homeFeeRaw `div` (10 ^ network.decimals)
            #contract-home-fee = send.amountSend `times` homeFee
            
            if +send.amountSend < +(minPerTx) then
                return cb "Min amount per transaction is #{minPerTx} VLX"
            if +send.amountSend > +maxPerTx then
                return cb "Max amount per transaction is #{maxPerTx} VLX"
                           
            sending-to = 
                | send.to.starts-with \V => to-eth-address send.to
                | _ => send.to

            contract = web3.eth.contract(abis.ERC20BridgeToken).at(FOREIGN_BRIDGE_TOKEN)
            data = contract.transferAndCall.get-data(FOREIGN_BRIDGE, value, sending-to)
            
            send.data = data
            send.contract-address = FOREIGN_BRIDGE_TOKEN
            
        
        /* DONE */    
        /* Swap from COIN VLX to VLX ERC20 */
        if (token is \vlx_evm or token is \vlx2) and chosen-network.id is \vlx_erc20 then
        
            { wallets } = store.current.account
            chosen-network-wallet = wallets |> find (-> it.coin.token is chosen-network.id)
            return cb "[Swap error]: wallet #{chosen-network.id} is not found!" if not chosen-network-wallet? 
            
            { HOME_BRIDGE } = wallet.network 
            
            receiver = store.current.send.to 
            network = wallet.network    
            minPerTxRaw = web3t.velas.HomeBridgeNativeToErc.minPerTx!
            minPerTx = minPerTxRaw `div` (10 ^ network.decimals)
            maxPerTxRaw = web3t.velas.HomeBridgeNativeToErc.maxPerTx! 
            maxPerTx = maxPerTxRaw `div` (10 ^ network.decimals)    
            
            #homeFeeRaw = web3t.velas.HomeBridgeNativeToErc.getHomeFee! 
            #homeFee = homeFeeRaw `div` (10 ^ network.decimals)     
            #data = web3t.velas.HomeBridgeNativeToErc.relayTokens.get-data(receiver)
            
            data = web3t.velas.HomeBridgeNativeToErc.relayTokens.get-data(receiver)
            
            amount-to-send = send.amount-send-fee `plus` send.amount-send   
                
            if +send.amountSend < +(minPerTx) then
                return cb "Min amount per transaction is #{minPerTx} VLX"
            if +send.amountSend > +maxPerTx then
                return cb "Max amount per transaction is #{maxPerTx} VLX" 
            send.data = data 
            store.current.send.contract-address = HOME_BRIDGE  
            
        
        /* DONE */
        /* Swap into native */   
        if chosen-network.id is \native then
            $recipient = ""
            try
                $recipient = bs58.decode send.to
                hex = $recipient.toString('hex')
            catch err
                return cb "Please enter valid address"
            eth-address = \0x + hex
            data = web3t.velas.EvmToNativeBridge.transferToNative.get-data(eth-address)           
            store.current.send.contract-address = web3t.velas.EvmToNativeBridge.address
        
        #if not data? or data is "0x" then
            #return cb "Transaction data must be not empty"
        send.data = data
        cb null   
    before-send-anyway = ->
        cb = console.log    
        (document.query-selector \.textfield).blur!
        err <- execute-contract-data!
        if err?    
            error = err.toString()
            if error.to-lower-case!.index-of("canceled") isnt -1
                return  
            return store.current.send.error = error  
        send-money!  
    send-anyway = ->
        send-money!
    to-hex = ->
        new BN(it)  
    cancel = (event)->
        navigate store, web3t, \wallets
        notify-form-result send.id, "Cancelled by user"
    recipient-change = (event)!->
        _to = event.target.value
        send.to = _to    
        _to = _to.trim!
        err <- resolve-address { store, address: _to, coin: send.coin, network: send.network }
        return send.error = err if err? 
        send.error = '' 
    get-value = (event)-> 
        value = event.target?value     
        return null if not event.target?value      
        return \0 if event.target?value is ""    
        #value = event.target.value.match(/^[0-9]+([.]([0-9]+)?)?$/)?0
        #value2 =
            #| value?0 is \0 and value?1? and value?1 isnt \. => value.substr(1, value.length)
            #| _ => value
        value
    amount-change = (event)->
        value = get-value event
        # if empty string return zero!    
        value = "0" if not value? or isNaN(value)   
        <- change-amount store, value, no
    perform-amount-eur-change = (value)->
        to-send = calc-crypto-from-eur store, value
        <- change-amount store, to-send , no
    perform-amount-usd-change = (value)->
        to-send = calc-crypto-from-usd store, value
        <- change-amount-calc-fiat store, to-send, no
    amount-eur-change = (event)->
        value = get-value event
        send.amount-send-eur = value
        amount-eur-change.timer = clear-timeout amount-eur-change.timer
        amount-eur-change.timer = set-timeout (-> perform-amount-eur-change value), 500
    amount-usd-change = (event)->
        value = get-value event
        value = value ? 0 
        { wallets } = store.current.account
        { token } = store.current.send.coin
        wallet =
            wallets |> find (-> it.coin.token is token)
        { balance, usdRate } = wallet 
        send.amount-send-usd = value
        #return no if +value is 0 
        perform-amount-usd-change value
        /* Removed timeout delay here */   
        #amount-usd-change.timer = clear-timeout amount-usd-change.timer
        #amount-usd-change.timer = set-timeout (-> perform-amount-usd-change value), 500
    encode-decode = ->
        send.show-data-mode =
            | send.show-data-mode is \decoded => \encoded
            | _ => \decoded
    show-data = ->
        | send.show-data-mode is \decoded => send.decoded-data
        | _ => send.data
    show-label = ->
        if send.show-data-mode is \decoded then \encoded else \decoded
    when-empty = (str, def)->
        if (str ? "").length is 0 then def else str
    history = ->
        store.current.send-menu-open = no
        store.current.filter = {token: send.coin.token}
        apply-transactions store
        navigate store, web3t, \history
    export network =
        | store.current.network is \testnet => " (TESTNET) "
        | _ => ""
    export invoice = (wallet)->
        store.current.send-menu-open = no
        { coin, network } = store.current.send
        store.current.invoice <<<< { coin, wallet, network }
        navigate store, web3t, \invoice
    export token = send.coin.token.to-upper-case!
    export name = send.coin.name ? token
    fee-token = (wallet.network.tx-fee-in ? send.coin.token).to-upper-case!
    is-data = (send.data ? "").length > 0
    bridge-fee-token = wallet.network.txBridgeFeeIn
    choose-auto = ->
        return if has-send-error!  
        send.fee-type = \auto
        <- change-amount store, send.amount-send, no
    choose-cheap = ->
        send.fee-type = \cheap
        <- change-amount store, send.amount-send, no
    choose-custom = (amount)->
        return if has-send-error!    
        balance = send.wallet.balance
        amount-send-fee = send.amount-send-fee      
        send.fee-type = \custom
        max-amount = Math.max 1e8, balance
        send.amount-send-fee = send.fee-custom-amount = amount
        <- change-amount store, send.amount-send, no
    chosen-cheap = if send.fee-type is \cheap then \chosen else ""
    chosen-auto  = if send.fee-type is \auto then \chosen else ""
    chosen-custom  = if send.fee-type is \custom then \chosen else ""
    send-options = send.coin.tx-types ? []
    pending = wallet.pending-sent + ' ' + token
    calc-amount-and-fee = (amount-send, trials, cb)->
        return cb "Cannot estimate max amount. Please try to type manually" if trials <= 0
        return cb "Balance is not enough to send tx" if +amount-send is 0
        account = { wallet.address, wallet.private-key }
        err, amount-send-fee <- calc-fee { token, send.network, amount: amount-send, send.fee-type, send.tx-type, send.to, send.data, account }
        if send.fee-type is \custom
            amount-send-fee = send.amount-send-fee
        return cb null, { amount-send, amount-send-fee } if not err?
        return cb err if err? and err isnt "Balance is not enough to send tx"
        return cb "Fee cannot be calculated" if not amount-send-fee?
        cb null 
    flag = no   
    use-max = (cb)!->
        #txFeeIn = wallet?network?txFeeIn   
        #min-fee = 
        #    | txFeeIn? and txFeeIn isnt wallet?coin?token => 0
        #    | _ => send.wallet.network.txFeeOptions.cheap
        amount-send = wallet.balance `minus` (wallet.pending-sent ? 0)
        #amount-send = amount-send 
        #amount-send = 0 if amount-send < 0 
        #flag = yes   
        <- change-amount-send store, amount-send, no
    use-max-try-catch = (cb)->
        try
            use-max cb
        catch err
            cb err
    export use-max-amount = ->
        err <- use-max-try-catch
        alert "#{err}" if err?
    export has-send-error = ->  
        error = store.current.send.error.toString!
        error? and error.length > 0 and error.toLowerCase! isnt "not enough funds"
        
    homeFee = store.current.send.amount-send `times` store.current.send.homeFeePercent       
                     
    homeFeeUsd = homeFee `times` wallet.usdRate    
        
    getBridgeInfo = (cb)-> 
            
        chosen-network = store?current?send?chosen-network
        return cb null if not chosen-network?    
        token = store.current.send.coin.token
        
        if not chosen-network? 
            or chosen-network.referTo in <[ vlx_native ]>        
            or token is \vlx_native and chosen-network.referTo in <[ vlx vlx2 vlx_evm ]>
            or token in <[ vlx vlx_evm ]> and chosen-network.referTo in <[ vlx_native vlx2 ]> 
            or token is \vlx_native and chosen-network.referTo in <[ vlx vlx2 vlx_evm ]>   
                store.current.send.homeFeePercent = 0 
                return cb null    
        
        wallet = store.current.send.wallet
        { network } = wallet 
        abi = 
            * {"constant":true,"inputs":[],"name":"getHomeFee","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"}
            * {"constant":true,"inputs":[],"name":"getForeignFee","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"}
            * {"constant":true,"inputs":[],"name":"dailyLimit","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"}
            * {"constant":true,"inputs":[],"name":"minPerTx","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"}    
            * {"constant":true,"inputs":[],"name":"maxPerTx","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"}    
            * {"constant":true,"inputs":[],"name":"executionDailyLimit","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"}    
            * {"constant":true,"inputs":[],"name":"maxAvailablePerTx","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"}  
        
        web3 = new Web3(new Web3.providers.HttpProvider(wallet?network?api?web3Provider))
        web3.eth.provider-url = wallet.network.api.web3Provider
        { HOME_BRIDGE, HECO_SWAP__HOME_BRIDGE, BSC_SWAP__HOME_BRIDGE } = wallet.network 
        addr =
            | token is \vlx_evm and chosen-network.referTo is \vlx_huobi => HECO_SWAP__HOME_BRIDGE
            | token is \vlx_evm and chosen-network.referTo is \bsc_vlx => BSC_SWAP__HOME_BRIDGE    
            | _ => HOME_BRIDGE         
        contract = web3.eth.contract(abi).at(addr)        
        homeFeePercent = 0  
        try     
            homeFee = contract.getHomeFee!
            homeFeePercent = homeFee `div` (10 ^ wallet?network.decimals) 
            store.current.send.homeFeePercent = homeFeePercent  
        catch err
            #console.log "[getHomeFeeError]: " err
            return cb err    
            #store.current.send.homeFeePercent = 0  
            
        dailyLimit = contract.dailyLimit!
        dailyLimit = dailyLimit `div` (10 ^ wallet.network.decimals)
        
        try 
            maxAvailablePerTx = contract.maxAvailablePerTx!
            maxAvailablePerTx = maxAvailablePerTx `div` (10 ^ wallet.network.decimals)
            store.current.send.maxAvailablePerTx = maxAvailablePerTx
        catch err
            console.log "[maxAvailablePerTx error]: " err
            return cb err    
        
        store.current.send.homeDailyLimit = dailyLimit     
        store.current.network-details <<<< { dailyLimit, homeFeePercent, maxAvailablePerTx }  
        
        cb null  
    
    export execute-contract-data    
    export getBridgeInfo
    export homeFee
    export homeFeeUsd    
    export change-amount
    export send
    export wallet
    export pending
    export fee-token
    export bridge-fee-token    
    export primary-button-style
    export recipient-change
    export amount-change
    export amount-usd-change
    export amount-eur-change
    export show-data
    export show-label
    export topup : topup(store)
    export history
    export cancel
    export send-anyway
    export before-send-anyway    
    export choose-auto
    export choose-cheap
    export choose-custom
    export chosen-auto
    export chosen-cheap
    export chosen-custom
    export default-button-style
    export round5edit
    export round5
    export send-options
    export calc-amount-and-fee
    export is-data
    export encode-decode
    out$