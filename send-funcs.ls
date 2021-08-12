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
    { send-to } = web3t.naming
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
            | chosen-network? and chosen-network.id is \legacy and token is \vlx_bep20 => receiver   
            | chosen-network? and chosen-network.id is \legacy and not store.current.send.contract-address? => to-eth-address(receiver)     
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
        err <- create-pending-tx { store, token, network, tx, amount-send, amount-send-fee, send.to, from: wallet.address }
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
        try
            amount = wallet.balance `minus` send.amount-send `minus` (wallet.pending-sent ? 0) `minus` send.amount-send-fee
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
            | send.network.api.url => send.network.api.url + "/tx/" + data
        navigate store, web3t, \sent
        <- web3t.refresh
        
    send-escrow = ->
        name = send.to
        amount-ethers = send.amount-send
        err <- send-to { name, amount-ethers }
        
   
    /* 
    * Swap from USDT ETHEREUM to USDT VELAS 
    */     
    eth_usdt-usdt_velas-swap = (token, chosen-network, cb)->     
        return cb null if not (token is \usdt_erc20 and chosen-network.id is \vlx_usdt)
        console.log "Swap from USDT ETHEREUM to USDT VELAS"    

        web3 = velas-web3 store
        { ERC20_TOKEN_ADDRESS, FOREIGN_BRIDGEABLE_TOKEN_ADDRESS } = wallet.network
        
        UINT_MAX_NUMBER = 4294967295 
                
        value = store.current.send.amountSend 
        value = (value `times` (10^6))  
        receiver = send.to
        
        web3 = new Web3(new Web3.providers.HttpProvider(wallet?network?api?web3Provider))
        web3.eth.provider-url = wallet?network?api?web3Provider
        contract = web3.eth.contract(abis.ForeignBridgeErcToErc).at(ERC20_TOKEN_ADDRESS)    
        
        /* Check for allowed amount for contract */
        allowedRaw = contract.allowance(wallet.address, FOREIGN_BRIDGEABLE_TOKEN_ADDRESS);
        allowed = allowedRaw `div` (10 ^ 0)   
        
        #if allowed < (send.amount-send `plus` (send.amount-send-fee `times` 2)) then
            #return cb "You are now allowed to spend " + send.amount-send + " " + "USDT"
        
        { coin, gas, gas-price, amount-send, amount-send-fee, fee-type, network, tx-type } = send 
        data = contract.approve.get-data(FOREIGN_BRIDGEABLE_TOKEN_ADDRESS, value) 
        tx-obj =
            account: { wallet.address, wallet.private-key, wallet.secret-key }
            recipient: ERC20_TOKEN_ADDRESS
            network: network
            token: token
            coin: coin
            amount: 0
            amount-fee: amount-send-fee
            data: data
            gas: gas
            gas-price: gas-price
            fee-type: fee-type
        
        err, tx-data <- create-transaction tx-obj
        return cb err if err?
            
        err, tx <- push-tx { token, tx-type, network, ...tx-data }
        return cb err if err?
        
        { network } = wallet   
        contract = web3.eth.contract(abis.ForeignBridgeErcToErc).at(FOREIGN_BRIDGEABLE_TOKEN_ADDRESS)  
        
        minPerTxRaw = contract.minPerTx!  
        minPerTx = minPerTxRaw `div` (10 ^ 6)                
        if +send.amountSend < +(minPerTx) then
            return cb "Min amount per transaction is #{minPerTx} USDT"
        maxPerTxRaw = contract.maxPerTx!
        maxPerTx = maxPerTxRaw `div` (10 ^ 6)                
        if +send.amountSend > +(maxPerTx) then
            return cb "Max amount per transaction is #{maxPerTx} USDT"
        
        data = contract.relayTokens.get-data(receiver, value)
        store.current.send.contract-address = FOREIGN_BRIDGEABLE_TOKEN_ADDRESS
        store.current.send.data = data    
        cb null, data 
        
    /* 
    * Swap from USDT VELAS to USDT ETHEREUM
    */     
    usdt_velas-eth_usdt-swap = (token, chosen-network, cb)->     
        return cb null if not (token is \vlx_usdt and chosen-network.id is \usdt_erc20)
        console.log "Swap from USDT VELAS to USDT ETHEREUM"    

        web3 = velas-web3 store
        { ERC20_TOKEN_ADDRESS, FOREIGN_BRIDGEABLE_TOKEN_ADDRESS } = wallet.network
        
        ERC20_TOKEN_ADDRESS = "0xb404c51bbc10dcbe948077f18a4b8e553d160084" 
        HOME_BRIDGE_ADDRESS = "0x4a114C7a9e6581eB716085655DecBB416776ec7c"   
        FOREIGN_BRIDGEABLE_TOKEN_ADDRESS = "0xF30aC574c31270173A201027B12c3bC9734C9C26" 
        FOREIGN_BRIDGE_ADDRESS = "0x90f69A6134fD1cf45170AC55a895138da69B40aD"
        UINT_MAX_NUMBER = 4294967295 
                
        value = store.current.send.amountSend 
        value = (value `times` (10^6))  
        receiver = send.to 
        
        web3 = new Web3(new Web3.providers.HttpProvider(wallet?network?api?web3Provider))
        web3.eth.provider-url = wallet?network?api?web3Provider
        contract = web3.eth.contract(abis.ERC20BridgeToken).at(HOME_BRIDGE_ADDRESS)    
 
        { network } = wallet   
        
        minPerTxRaw = contract.minPerTx!  
        minPerTx = minPerTxRaw `div` (10 ^ 6)  
        if +send.amountSend < +(minPerTx) then
            return cb "Min amount per transaction is #{minPerTx} USDT"
        maxPerTxRaw = contract.maxPerTx!
        maxPerTx = maxPerTxRaw `div` (10 ^ 6) 
        if +send.amountSend > +(maxPerTx) then
            return cb "Max amount per transaction is #{maxPerTx} USDT"
        
        data = contract.transferAndCall.get-data(HOME_BRIDGE_ADDRESS, value, send.to)
        #store.current.send.contract-address = FOREIGN_BRIDGE_ADDRESS
        store.current.send.data = data
        #send.amount = 0
        #send.amount-send = 0
            
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
        
        /* Swap from BEP20 to legacy */
        if token is \vlx_bep20 and chosen-network.id is \legacy
        
            { wallets } = store.current.account
            chosen-network-wallet = wallets |> find (-> it.coin.token is \vlx2)
            return cb "[Swap error]: wallet #{chosen-network.id} is not found!" if not chosen-network-wallet? 
            LEGACY_TOKEN_BRIDGE = chosen-network-wallet.network.ERC20BridgeToken
            FOREIGN_BRIDGE = wallet.network.ForeignBridge       
          
            if store.current.network is \testnet and FOREIGN_BRIDGE isnt \0xF9a7046E40E7e1992B877E7C20C0715F10560AB5    
                return cb "Wrong Foreign bridge address"
           
            value = store.current.send.amountSend 
            value = to-hex (value `times` (10^18))
            data = web3t.velas.ERC677BridgeToken.transferAndCall.get-data(FOREIGN_BRIDGE, value, send.to)
            send.data = data            
            
            if store.current.network is \testnet and LEGACY_TOKEN_BRIDGE isnt \0xfEFF2e74eC612A288Ae55fe9F6e40c52817a1B6C    
                return cb "Wrong ERC20 Bridge Token address"
            
            send.contract-address = LEGACY_TOKEN_BRIDGE 
            send.amount = 0
            send.amount-send = 0
            
        /* Swap from LEGACY to BEP20 */
        if token is \vlx2 and chosen-network.id is \vlx_bep20
            { wallets } = store.current.account
            chosen-network-wallet = wallets |> find (-> it.coin.token is chosen-network.id)
            return cb "[Swap error]: wallet #{chosen-network.id} is not found!" if not chosen-network-wallet? 
            HomeBridge = chosen-network-wallet.network.HomeBridge
            
            /* VLX2 */    
            HomeBridge          = "0x57C7f6CD50a432943F40F987a1448181D5B11307"
            ForeignBridge       = "0xBDeDd09D5283fB38EFF898E3859AbAE96B712aF9" 
            ERC20BridgeToken    = "0xfEFF2e74eC612A288Ae55fe9F6e40c52817a1B6C" 
            
            /* BNB */    
            HomeBridge = \0x97B7eb15cA5bFa82515f6964a3EAa1fE71DFB7A7
            ForeignBridge = \0x719C8490730ADBBA514eec7173515a4A572dA736
            ERC677BridgeableToken = \0x77622C2F95846dDaB1300F46685CC953C17A78df
            
            receiver = store.current.send.to 
            store.current.send.contract-address = "0x97B7eb15cA5bFa82515f6964a3EAa1fE71DFB7A7"  
            data = web3t.velas.HomeBridgeNativeToErc.relayTokens.get-data(receiver)
            send.data = data     
                   
            /* Check for actual home bridge address for swap from evm to bep20 */    
            #if store.current.network is \testnet and HomeBridge isnt \0x97B7eb15cA5bFa82515f6964a3EAa1fE71DFB7A7
                #return cb "Wrong home bridge address"  
            
            #store.current.send.contract-address = \0xF9a7046E40E7e1992B877E7C20C0715F10560AB5    
            #receiver = store.current.send.to 
            #data = web3t.velas.HomeERC677BridgeLegacyToErc.relayTokens.get-data(receiver)
            
            
        /* Swap from legacy to HECO*/
        if token is \vlx2 and chosen-network.id is \vlx_huobi
            { wallets } = store.current.account
            chosen-network-wallet = wallets |> find (-> it.coin.token is \vlx_huobi)
            return cb "[Swap error]: wallet #{chosen-network.id} is not found!" if not chosen-network-wallet? 
            #HomeBridge = chosen-network-wallet.network.HomeBridge
            HomeBridge = "0x8c8884Fdb4f9a6ca251Deef70670DF7C4c48045D" 
            
            BRIDGEABLE_TOKEN_ABI = [
              {
                constant: false,
                inputs: [
                  {
                    name: '_to',
                    type: 'address'
                  },
                  {
                    name: '_value',
                    type: 'uint256'
                  },
                  {
                    name: '_data',
                    type: 'bytes'
                  }
                ],
                name: 'transferAndCall',
                outputs: [
                  {
                    name: '',
                    type: 'bool'
                  }
                ],
                payable: false,
                stateMutability: 'nonpayable',
                type: 'function'
              }
            ]
            web3 = velas-web3 store
            HOME_BRIDGE_ADDRESS = "0x57C7f6CD50a432943F40F987a1448181D5B11307"    
            erc677 = web3.eth.contract(BRIDGEABLE_TOKEN_ABI).at(HOME_BRIDGE_ADDRESS)
            
            FOREIGN_BRIDGE = "0xBDeDd09D5283fB38EFF898E3859AbAE96B712aF9"  # was foreign bridge of huobi  
            COMMON_HOME_BRIDGE_ADDRESS = "0x8c8884Fdb4f9a6ca251Deef70670DF7C4c48045D" 
            value = store.current.send.amountSend 
            value = to-hex (value `times` (10^18))
            
            #data = erc677.transferAndCall.get-data(COMMON_HOME_BRIDGE_ADDRESS, value, send.to)
            
            data = web3t.velas.HomeBridgeNativeToErc.relayTokens.get-data(send.to )     
            
            send.data = data            

            
            send.contract-address = "0x8c8884Fdb4f9a6ca251Deef70670DF7C4c48045D"    
            
            #LEGACY_TOKEN_BRIDGE = chosen-network-wallet.network.ERC20BridgeToken
            #send.contract-address = LEGACY_TOKEN_BRIDGE 
            #send.amount = 0
            #send.amount-send = 0

             
            #store.current.send.contract-address = HomeBridge    
            #receiver = store.current.send.to 
            #data = web3t.velas.HomeBridgeNativeToErc.relayTokens.get-data(receiver)
            #send.data = data 
            
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
                     
            | _ => dummy   
        err, data <- func(token, chosen-network)



        /* Swap from HECO to legacy */
        if token is \vlx_huobi and chosen-network.id is \legacy
        
            { wallets } = store.current.account
            chosen-network-wallet = wallets |> find (-> it.coin.token is \vlx2)
            return cb "[Swap error]: wallet #{chosen-network.id} is not found!" if not chosen-network-wallet? 
            LEGACY_TOKEN_BRIDGE = chosen-network-wallet.network.ERC20BridgeToken
            FOREIGN_BRIDGE = wallet.network.ForeignBridge 
                  
          
            if store.current.network is \testnet and FOREIGN_BRIDGE isnt \0x719C8490730ADBBA514eec7173515a4A572dA736    
                return cb "Wrong Foreign bridge address"
           
            value = store.current.send.amountSend 
            value = to-hex (value `times` (10^18))
            data = web3t.velas.ERC677BridgeToken.transferAndCall.get-data(FOREIGN_BRIDGE, value, send.to)
            send.data = data            
            
            if store.current.network is \testnet and LEGACY_TOKEN_BRIDGE isnt \0xfEFF2e74eC612A288Ae55fe9F6e40c52817a1B6C    
                return cb "Wrong ERC20 Bridge Token address"
            
            send.contract-address = LEGACY_TOKEN_BRIDGE 
            send.amount = 0
            send.amount-send = 0
        
        /* DONE! */
        /* Swap from ETH to ETHEREUM (VELAS) */ 
        if token is \eth and chosen-network.id is \vlx_eth then
        
            { wallets } = store.current.account
            chosen-network-wallet = wallets |> find (-> it.coin.token is chosen-network.id)
            return cb "[Swap error]: wallet #{chosen-network.id} is not found!" if not chosen-network-wallet? 
            HomeBridge = chosen-network-wallet.network.HomeBridge
            
            value = store.current.send.amountSend 
            value = to-hex (value `times` (10^18)) 

            HOME_BRIDGE = "0xb1FAB785Cb5F2d9782519942921e9afCDf2C60e0"
            FOREIGN_BRIDGE = "0xA5D512085006867974405679f2c9476F4F7Fa903"
            BRIDGEABLE_TOKEN = "0x3538C7f88aDbc8ad1F435f7EA70287e26b926344"
            
            web3 = new Web3(new Web3.providers.HttpProvider(wallet.network.api.web3Provider))
            web3.eth.provider-url = wallet.network
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
            send.data = data 

        /* DONE! */
        /* Swap from ETHEREUM (VELAS) to ETH  */ 
        if token is \vlx_eth and chosen-network.id is \eth then
        
            value = store.current.send.amountSend
            value = (value `times` (10^18))
            network = wallet.network    

            web3 = new Web3(new Web3.providers.HttpProvider(wallet.network.api.web3Provider))
            web3.eth.provider-url = wallet.network.api.web3Provider
            contract = web3.eth.contract(abis.ERC20BridgeToken).at("0xA5D512085006867974405679f2c9476F4F7Fa903")

            minPerTxRaw = contract.minPerTx!
            minPerTx = minPerTxRaw `div` (10 ^ network.decimals)
            if +send.amountSend < +(minPerTx) then
                return cb "Min amount per transaction is #{minPerTx} ETH"

            maxPerTxRaw = contract.maxPerTx!
            maxPerTx = maxPerTxRaw `div` (10 ^ network.decimals)
            if +send.amountSend > +maxPerTx then
                return cb "Max amount per transaction is #{maxPerTx} ETH"

            contract = web3.eth.contract(abis.ERC20BridgeToken).at("0x3538C7f88aDbc8ad1F435f7EA70287e26b926344")
            data = contract.transferAndCall.get-data("0xA5D512085006867974405679f2c9476F4F7Fa903", value, send.to)
            send.data = data
            send.contract-address = "0x3538C7f88aDbc8ad1F435f7EA70287e26b926344"
            send.amount = 0
            send.amount-send = 0

        
        
        /* DONE */
        /* Swap from VLX ERC20 to COIN VLX */    
        if token is \vlx_erc20 and chosen-network.id is \vlx_evm
            value = store.current.send.amountSend
            send-to = web3t.velas.ForeignBridgeNativeToErc.address 
            value = to-hex (value `times` (10^18))
            token-address = web3t.velas.ERC20BridgeToken.address   
            network = wallet.network    
            #/*
            # * Get minPerTx from HomeBridge  (not Foreign?)  
            # */ 
            minPerTxRaw = web3t.velas.HomeBridgeNativeToErc.minPerTx!
            minPerTx = minPerTxRaw `div` (10 ^ network.decimals)
            #/*
            # * Get maxPerTx from HomeBridge  (not Foreign?)  
            # */
            maxPerTxRaw = web3t.velas.HomeBridgeNativeToErc.maxPerTx!
            maxPerTx = maxPerTxRaw `div` (10 ^ network.decimals)
            homeFeeRaw = web3t.velas.ForeignBridgeNativeToErc.getHomeFee! 
            homeFee = homeFeeRaw `div` (10 ^ network.decimals)
            contract-home-fee = send.amountSend `times` homeFee
            minAmountPerTx = minPerTx `plus` contract-home-fee 
            
            if +send.amountSend < +(minAmountPerTx) then
                return cb "Min amount per transaction is #{minAmountPerTx} VLX"
            if +send.amountSend > +maxPerTx then
                return cb "Max amount per transaction is #{maxPerTx} VLX"  
              
            data = web3t.velas.ERC20BridgeToken.transferAndCall.get-data(send-to, value, send.to)
            send.data = data
            send.contract-address = web3t.velas.ERC20BridgeToken.address  
            send.amount = 0
            send.amount-send = 0
            
        
        /* DONE */    
        /* Swap from COIN VLX to VLX ERC20 */
        if (token is \vlx_evm or token is \vlx2) and chosen-network.id is \vlx_erc20 then
        
            { wallets } = store.current.account
            chosen-network-wallet = wallets |> find (-> it.coin.token is chosen-network.id)
            return cb "[Swap error]: wallet #{chosen-network.id} is not found!" if not chosen-network-wallet? 
            HomeBridge = chosen-network-wallet.network.HomeBridge
             
            store.current.send.contract-address = HomeBridge    
            receiver = store.current.send.to 
            network = wallet.network    
            minPerTxRaw = web3t.velas.HomeBridgeNativeToErc.minPerTx!
            minPerTx = minPerTxRaw `div` (10 ^ network.decimals)
            maxPerTxRaw = web3t.velas.HomeBridgeNativeToErc.maxPerTx! 
            maxPerTx = maxPerTxRaw `div` (10 ^ network.decimals)    
            homeFeeRaw = web3t.velas.HomeBridgeNativeToErc.getHomeFee! 
            homeFee = homeFeeRaw `div` (10 ^ network.decimals)
            data = web3t.velas.HomeBridgeNativeToErc.relayTokens.get-data(receiver)
            amount-to-send = send.amount-send-fee `plus` send.amount-send   
            contract-home-fee = send.amountSend `times` homeFee
            ONE_PERCENT = minPerTx `times` "0.01"    
            minAmountPerTx = minPerTx `plus` contract-home-fee `plus` ONE_PERCENT `plus` "2"    
            if +send.amountSend < +(minAmountPerTx) then
                return cb "Min amount per transaction is #{minAmountPerTx} VLX"
            if +send.amountSend > +maxPerTx then
                return cb "Max amount per transaction is #{maxPerTx} VLX" 
            send.data = data    
        
        
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
        
        if not data? then
            return cb "Transaction data must be not empty"
        send.data = data
        cb null   
    before-send-anyway = ->
        cb = console.log     
        err <- execute-contract-data!
        store.current.send.error = err.toString() if err?    
        return cb err if err?    
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
        amount-usd-change.timer = clear-timeout amount-usd-change.timer
        amount-usd-change.timer = set-timeout (-> perform-amount-usd-change value), 500
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
        min-fee = send.wallet.network.txFeeOptions.cheap       
        amount-send = wallet.balance `minus` (wallet.pending-sent ? 0)
        amount-send = amount-send `minus` min-fee if not flag 
        amount-send = 0 if amount-send < 0 
        flag = yes   
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