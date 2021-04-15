require! {
    \react
    \react-dom
    \bignumber.js
    \../../navigate.ls
    \../../get-primary-info.ls
    \../../get-lang.ls
    \../../history-funcs.ls
    \../../stake-funcs.ls : { query-accounts }
    \../icon.ls
    \prelude-ls : { map, split, filter, find, foldl, sort-by, unique, head, each }
    \../../math.ls : { div, times, plus, minus }
    \../../../web3t/providers/deps.js : { hdkey, bip39 }
    \md5
    \safe-buffer : { Buffer }
    \../../../web3t/addresses.js : { ethToVlx }
    \../../round-human.ls
    #\../../request-stake.ls
    #\../../request-unstake.ls
    #\../../txs-history.ls
    #\../pools-list.ls
    \../../components/checkbox.ls
    \../../icons.ls
    \../placeholder.ls
    \../../staking/can-make-staking.ls
    \../../components/button.ls
    \../../components/address-holder.ls
    \../../components/address-holder-popup.ls
    \../alert-txn.ls
    \../../components/amount-field.ls
    \../../seed.ls : seedmem
    \moment
    \../confirmation.ls : { prompt, prompt-stake-account-amount, alert, confirm, notify }
}
as-callback = (p, cb)->
    p.catch (err) -> cb err
    p.then (data)->
        cb null, data
.staking-content
    .form-group
        .section.create-staking-account
            display: block
            .title,.description
                width: auto
                text-align: center
        .subtitle
            margin: 20px 0 10px
        .settings
            margin-top: 20px
            .settings-item
                margin-bottom: 20px
                & > label
                    margin-bottom: 6px
                    display: inline-block
        .outer-checkbox
            display: inline-block
            margin: 0 15px 0 0
            & + label
                margin: 5px 0
        .table-scroll.lockup
            table
                td
                    &.validator-address
                        text-align: center
                    border: none
cb = console.log
show-validator = (store, web3t)-> (validator)->
    li.pug #{validator}
staking-accounts-content = (store, web3t)->
    style = get-primary-info store
    lang = get-lang store
    button-primary3-style=
        border: "1px solid #{style.app.primary3}"
        color: style.app.text2
        background: style.app.primary3
        background-color: style.app.primary3-spare
    { go-back } = history-funcs store, web3t
    lang = get-lang store
    pairs = store.staking.keystore
    activate = (step)->
        store.staking.accounts.stake.step = step
    withdraw = ->
        console.log "withdraw!"
    topup-the-contract = ->
        console.log "topup-the-contract!"
    stake-to-contract = ->
        console.log "stake-to-contract!"
    change-address = ->
        store.staking.add.add-validator = it.target.value
    change-withdraw = ->
        store.staking.withdrawAmount = it.target.value
    change-stake = !->
        try
            value = new bignumber(it.target.value).toFixed!.to-string!
            store.staking.add.add-validator-stake = value
        catch err
            console.log "[Change-stake]: #{err}"
    get-balance = ->
        wallet =
            store.current.account.wallets
                |> find -> it.coin.token is \vlx_native
        wallet?balance ? 0
    get-options = (cb)->
        err, data <- web3t.velas.Staking.candidateMinStake
        return cb err if err?
        min =
            | +store.staking-accounts.stake-amount-total >= 10000 => 1
            | _ => data `div` (10^18)
        balance = (store.staking-accounts.chosen-lockup.locked-funds-raw `div` (10^18)) `minus` 0.1
        stake = store.staking-accounts.add.add-validator-stake
        return cb lang.amountLessStaking if 10000 > +stake
        return cb lang.balanceLessStaking if +balance < +stake
        max = +balance
        cb null, { min, max }
    use-min = ->
        #err, options <- get-options
        #return alert store, err, cb if err?
        store.staking-accounts.add.add-validator-stake = 10000
    use-max = ->
        #err, options <- get-options
        #return alert store, err, cb if err?
        balance = store.staking-accounts.chosen-lockup.locked-funds-raw `div` (10^18)
        store.staking-accounts.add.add-validator-stake = Math.max (balance `minus` 0.1), 0
    vote-for-change = ->
        err, can <- web3t.velas.ValidatorSet.emitInitiateChangeCallable
        return alert store, err, cb if err?
        return alert store, lang.actionProhibited, cb if can isnt yes
        data = web3t.velas.ValidatorSet.emitInitiateChange.get-data!
        #console.log { data }
        to = web3t.velas.ValidatorSet.address
        amount = 0
        err <- web3t.vlx2.send-transaction { to, data, amount }
        store.current.page = \staking
    vlx-token = "VLX"
    hide-stake-place = ->
        null
    build = (store, web3t)-> (item)->
        return null if not item? or not item.key?
        { account, address, balance, key, rent, seed, status, validator } = item
        index = store.staking.accounts.index-of(item) + 1
        $status =
            | status is 'inactive' => "Not Delegated"
            | _ => status
        vlx =
            store.current.account.wallets |> find (.coin.token is \vlx_native)
        return null if not vlx?
        wallet =
            address: item.address
            network: vlx.network
            coin: vlx.coin
        wallet-validator =
            address: validator
            network: vlx.network
            coin: vlx.coin
        # Select contract from list  
        undelegate = ->
            #err, options <- get-options
            #return alert store, err, cb if err?
            #err <- can-make-staking store, web3t
            #return alert store, err, cb if err?
            agree <- confirm store, "Are you sure you would to undelegate?"
            return if agree is no 
            #
            err, result <- as-callback web3t.velas.NativeStaking.undelegate(item.address)
            console.error "Undelegate error: " err if err?
            return alert store, err.toString! if err?
            <- notify store, "FUNDS UNDELEGATED"
            navigate store, web3t, \validators
        choose = ->
            store.staking.chosen-account = item
            navigate store, web3t, \poolchoosing
            cb null
        $button =
            | item.status is "inactive" =>
                button { store, text: \Delegate, on-click: choose , type: \secondary , icon : \arrowRight } 
            | _ => button { store, classes: "action-undelegate" text: \Undelegate, on-click: undelegate , type: \secondary , icon : \arrowLeft }  
        show-stake-place = ->
            null
        tr.pug(class="#{item.status}" key="#{address}" on-mouse-enter=show-stake-place on-mouse-leave=hide-stake-place)
            td.pug
                span.pug.circle(class="#{item.status}") #{index}
            td.pug(datacolumn='Staker Address' title="#{address}")
                address-holder-popup { store, wallet, item}
            td.pug #{balance}
            td.pug(class="validator-address" title="#{validator}")
                if validator? and validator isnt ""
                    address-holder-popup { store, wallet: wallet-validator, item }
                else
                    "---"
            td.pug #{seed}
            td.pug #{$status}
            td.pug
                $button
    cancel = ->
        store.staking-accounts.chosen-lockup = null
        store.staking-accounts.add.add-validator-stake = 0
    refresh = ->
        store.staking.all-pools-loaded = no
        if ((store.staking.all-pools-loaded is no or !store.staking.all-pools-loaded?) and store.staking.pools-are-loading is yes)
            return no
        store.staking.pools-are-loading = yes
        cb = console.log
        cb null, \done
    icon-style =
        color: style.app.loader
        margin-top: "10px"
        width: "inherit"
    staker-pool-style =
        max-width: 200px
        background: style.app.stats
    stats=
        background: style.app.stats
    create-staking-account = ->
        cb = console.log 
        amount <- prompt store, "How much would you like to deposit?"
        return if amount+"".trim!.length is 0
        min_stake = web3t.velas.NativeStaking.min_stake
        main_balance = get-balance!
        return alert store, "Balance is not enough to create staking account (#{min_stake} VLX)" if +min_stake > +main_balance
        return alert store, "Minimal stake must be #{min_stake} VLX" if +min_stake > +amount
        return alert store, "Balance is not enough to spend #{amount} VLX" if +main_balance < +amount
        amount = amount * 10^9
        err, result <- as-callback web3t.velas.NativeStaking.createAccount(amount)
        console.error "Result sending:" err if err?
        return alert store, err.toString! if err?
        <- notify store, "ACCOUNT CREATED AND FUNDS DEPOSITED"
        navigate store, web3t, "validators"
    .pug.staking-accounts-content
        .pug
            .form-group.pug(id="create-staking-account")
                .pug.section.create-staking-account 
                    .title.pug
                        h3.pug Create staking account    
                    .description.pug
                        button {store, classes: "width-auto", text: "Create account", no-icon:yes, on-click: create-staking-account, style: {width: \auto}}               
        .pug
            .form-group.pug(id="staking-accounts")
                .pug.section
                    .title.pug
                        h3.pug Your staking accounts
                    .description.pug.table-scroll.lockup(on-mouse-leave=hide-stake-place)
                        table.pug
                            thead.pug
                                tr.pug
                                    td.pug(width="3%" style=stats) #
                                    td.pug(width="40%" style=staker-pool-style) Account
                                    td.pug(width="10%" style=stats) Balance
                                    td.pug(width="30%" style=stats) Validator
                                    td.pug(width="7%" style=stats) Seed
                                    td.pug(width="10%" style=stats) Status
                            tbody.pug
                                store.staking.accounts |> map build store, web3t
staking-accounts = ({ store, web3t })->
    .pug.staking-accounts-content
        staking-accounts-content store, web3t
stringify = (value) ->
    if value? then
        round-human(parse-float value `div` (10^18))
    else
        '..'
module.exports = staking-accounts