require! {
    \react
    \react-dom
    \bignumber.js
    \../../get-primary-info.ls
    \../../get-lang.ls
    \../../history-funcs.ls
    \../../stake-funcs.ls : { query-pools }
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
    \../confirmation.ls : { alert }
    \../../components/button.ls
    \../../components/address-holder.ls
    \../alert-txn.ls
    \../../components/amount-field.ls
    \../../seed.ls : seedmem
    \moment
}
.single-section
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
    return if store.staking.accounts.length is 0
    { go-back } = history-funcs store, web3t
    lang = get-lang store
    pairs = store.staking.keystore
    activate = (step)->
        store.staking.accounts.stake.step = step
    withdraw = ->
        {address, lockedPool, maxWithdrawAllowed} = store.staking-accounts.chosen-lockup
        lockup-address = store.staking.accounts.chosen-lockup.address
        Timelock = web3t.velas.Timelock.at(lockup-address)
        contract-address = Timelock.address
        amount = maxWithdrawAllowed.to-fixed! `div` (10^18)
        return alert store, lang.actionProhibited, cb if +amount is 0
        vlx2 =
            store.current.account.wallets |> find (.coin.token is \vlx2)
        vlx-address = vlx2.address2
        data = Timelock.withdraw.get-data(vlx-address, amount)
        to = contract-address
        err <- web3t.vlx2.send-transaction { to, data, amount: 0 }
    topup-the-contract = ->
        #err, options <- get-options
        #return alert store, err, cb if err?
        return alert store, "please choose the contract", cb if not store.staking-accounts.chosen-lockup?
        type = typeof! store.staking-accounts.add.add-validator-stake
        return alert store, "please enter correct amount, got #{type}", cb if type not in <[ String Number ]>
        stake = store.staking-accounts.add.add-validator-stake `times` (10^18)
        contract-address = store.staking-accounts.chosen-lockup.address
        TimeLock = web3t.velas.Timelock.at(contract-address)
        vlx2 =
            store.current.account.wallets |> find (.coin.token is \vlx2)
        vlx-address = vlx2.address2
        err, lockedPool <- TimeLock.getDefaultPool!
        return cb err if err?
        data = TimeLock.stakeAmount.get-data vlx-address, stake
        to = TimeLock.address
        amount = store.staking-accounts.add.add-validator-stake
        err <- web3t.vlx2.send-transaction { to, amount }
        return cb err if err?
        return store.staking-accounts.add.result = "#{err}" if err?
        #<- staking-accounts.init { store, web3t }
        #store.staking-accounts.stake.step = \stake
        cb null
    stake-to-contract = ->
        #err, options <- get-options
        #return alert store, err, cb if err?
        err <- can-make-staking store, web3t
        return alert store, err, cb if err?
        return alert store, "please choose the contract", cb if not store.staking-accounts.chosen-lockup?
        type = typeof! store.staking-accounts.add.add-validator-stake
        return alert store, "please enter correct amount, got #{type}", cb if type not in <[ String Number ]>
        stake = store.staking-accounts.add.add-validator-stake `times` (10^18)
        contract-address = store.staking-accounts.chosen-lockup.address
        TimeLock = web3t.velas.Timelock.at(contract-address)
        vlx2 =
            store.current.account.wallets |> find (.coin.token is \vlx2)
        vlx-address = vlx2.address2
        err, lockedPool <- TimeLock.getDefaultPool!
        return cb err if err?
        data = TimeLock.stake.get-data vlx-address, stake
        to = TimeLock.address
        amount = store.staking-accounts.add.add-validator-stake
        err <- web3t.vlx2.send-transaction { to, data, amount }
        return cb err if err?
#        data = web3t.velas.Staking.stake.get-data store.staking.chosen-pool.address, stake
#        to = web3t.velas.Staking.address
#        amount = store.staking.add.add-validator-stake
#        err <- web3t.vlx2.send-transaction { to, data, amount }
        #return cb err if err?
        return store.staking-accounts.add.result = "#{err}" if err?
        #<- staking-accounts.init { store, web3t }
    change-address = ->
        store.staking.add.add-validator = it.target.value
    change-withdraw = ->
        store.staking-accounts.withdrawAmount = it.target.value
    change-stake = !->
        try
            value = new bignumber(it.target.value).toFixed!.to-string!
            store.staking-accounts.add.add-validator-stake = value
        catch err
            console.log "[Change-stake]: #{err}"
    return null if not pairs.mining?
    get-options = (cb)->
        #i-am-staker = i-stake-choosen-pool!
        #return cb null if i-am-staker
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
        store.staking-accounts.lockupStakingAddress = null
        null
    build = (store, web3t)-> (item)->
        { address, lockedFunds, lockedPool, stake, lockedFundsReleaseTime, lockThreshold } = item
        stake = round-human(parse-float item.stake `div` (10^18))
        index = store.staking-accounts.lockupContracts.index-of(item) + 1
        vlx2 =
            store.current.account.wallets |> find (.coin.token is \vlx2)
        wallet =
            address: ethToVlx item.address
            network: vlx2.network
            coin: vlx2.coin
        # Select contract from list
        choose = ->
            cb = console.log
            item.checked = yes
            store.staking-accounts.error = ""
            lockedPool = item.lockedPool
            contract = item.address
            store.staking-accounts.currentTimelock = web3t.velas.Timelock.at(contract)
            err, amount <- web3t.velas.Staking.stakeAmount lockedPool, contract
            store.staking-accounts.stake-amount-total = amount.to-fixed!
            store.staking-accounts.chosen-lockup = item
            err <- pools-list.init { store, web3t }
            err <- request-unstake.init { store, web3t }
            return cb err if err?
            cb null
        show-stake-place = ->
            store.staking-accounts.lockupStakingAddress = lockedPool
            null
        lockedUntil = if lockedFundsReleaseTime? then moment(lockedFundsReleaseTime * 1000).format("DD/MM/YYYY hh:mm") else ".."
        lockedThreshold = if lockThreshold? then (lockThreshold `div`(10^18)) else ".."
        tr.pug(class="#{item.status}" key="#{item.address}" on-mouse-enter=show-stake-place on-mouse-leave=hide-stake-place)
            td.pug
                span.pug.circle(class="#{item.status}") #{index}
            td.pug(datacolumn='Staker Address' title="#{ethToVlx item.address}")
                address-holder { store, wallet }
            td.pug #{lockedFunds}
            td.pug #{stake}
            td.pug #{lockedThreshold}
            td.pug #{lockedUntil}
            td.pug
                button { store, on-click: choose , type: \secondary , icon : \arrowRight }
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
    cancel-choose-pool = ->
        <- pools-list.init({store, web3t, select-action: no})
    .pug.staking-content.delegate
        if not store.staking.chosen-pool? and not store.staking-accounts.chosen-lockup?
            .pug.main-sections
                .form-group.pug(id="staking-accounts")
                    .pug.section
                        .title.pug
                            h3.pug Lock-up contracts
                        .description.pug.table-scroll.lockup(on-mouse-leave=hide-stake-place)
                            table.pug
                                thead.pug
                                    tr.pug
                                        td.pug(width="3%" style=stats) #
                                        td.pug(width="40%" style=staker-pool-style) Address
                                        td.pug(width="20%" style=stats) Non-staked Amount
                                        td.pug(width="20%" style=stats) Staked Amount
                                        td.pug(width="7%" style=stats) Threshold, VLX
                                        td.pug(width="10%" style=stats) Locked Until
                                        td.pug(width="9%" style=stats) Select
                                tbody.pug
                                    store.staking-accounts.lockupContracts |> map build store, web3t
        # We have choosen contract
        if store.staking-accounts.chosen-lockup?
            current-contract = store.staking-accounts.chosen-lockup
            choose-pool-from-list = ->
                store.staking-accounts.chosen-lockup-action  = 'select'
            lockup-action-choose = not current-contract.lockedPool? or (current-contract.lockedPool? and +current-contract.lockedPool is 0)
            get-balance = ->
                wallet =
                    store.current.account.wallets
                        |> find -> it.coin.token is \vlx2
                wallet.balance
            your-balance = " #{round-human get-balance!} "
            lang-stake = if store.staking-accounts.stake-amount-total > 0 then lang.stakeMore else lang.stake
            change-unstake = ->
                store.staking-accounts.unstakeAmount = it.target.value
            on-change-autostaking = ->
                cb = console.log
                value = it.target.value is \true
                contract-address = store.staking-accounts.chosen-lockup.address
                TimeLock = web3t.velas.Timelock.at(contract-address)
                func = if store.staking-accounts.chosen-lockup.isForwardingEnabled then TimeLock.disableForwarding else  TimeLock.enableForwarding
                data = func.get-data!
                to = contract-address
                err <- web3t.vlx2.send-transaction { to, data, amount: 0 }
                return cb err if err?
                #web3t.use networks-reverted[not value]
            isForwardingEnabled = store.staking-accounts.chosen-lockup.isForwardingEnabled is yes
            autostaking-state = if isForwardingEnabled then "enabled" else "disabled"
            Locked-pool-label = if store.staking-accounts.chosen-lockup-action is 'select' then
                "Select default pool from the list:"
            else
                "Default pool:"
            .pug.single-section.form-group(id="choosen-lockup")
                .pug.section
                    .title.pug
                        h3.pug Lock-up contract
                        .buttons.pug
                            button { store, on-click: cancel , type: \secondary , icon : "back" , text: "Back" id="cancel-pool"}
                    .description.pug
                        .pug.chosen-pool(title="#{store.staking-accounts.chosen-lockup.address}")
                            span.pug
                                | #{ethToVlx store.staking-accounts.chosen-lockup.address}
                                img.pug.check(src="#{icons.img-check}")
                            .pug.settings
                                if current-contract.lockedPool? and +current-contract.lockedPool isnt 0 then
                                    .pug.flex-container.flex-container-centered.settings-item
                                        checkbox { store, value: isForwardingEnabled, id:"autostaking-switcher", on-change:  on-change-autostaking, checked:isForwardingEnabled}
                                        span.pug Autostaking is #{autostaking-state}
                                .pug.flex-container.flex-container-centered.settings-item
                                    if current-contract.lockedPool?
                                        if store.staking-accounts.chosen-lockup-action is \select then
                                            button {store, on-click: cancel-choose-pool,  text: "Cancel", no-icon: yes, id="cancel-choose-pool"}
                                    .pug.subtitle.color
                                        label.pug #{Locked-pool-label}
                                    .pug.table-non-scroll.min-height.description.width100
                                    if store.staking-accounts.chosen-lockup-action is \choose then
                                        .pug
                                            button {store, classes: "width-auto", text: "Select default pool", no-icon:yes, on-click: choose-pool-from-list, style: {width: \auto}}
                #txs-history { store, web3t }
                .pug.section
                    .title.pug
                        h3.pug #{lang.withdraw}
                    .description.pug
                        if store.staking-accounts.chosen-lockup.maxWithdrawAllowed > 0
                            .pug.left
                                label.pug
                                .pug.balance
                                button { store, on-click: withdraw, classes: "width-auto" type: \secondary , icon : \apply , text: "Withdraw #{(store.staking-accounts.chosen-lockup.maxWithdrawAllowed `div` (10^18))} VLX" }
                        else
                            .pug.balance
                                span.pug You have no available
                                span.pug.color VLX
                                span.pug to withdraw
                #request-stake store, web3t
                #request-unstake store, web3t
                # if we have some funds to unstake
                if no and  +store.staking-accounts.stake-amount-total > 0
                    use-min2 = ->
                        store.staking-accounts.unstakeAmount = 0
                    use-max2 = ->
                        balance = store.staking-accounts.chosen-lockup.stake `div` (10^18)
                        store.staking-accounts.unstakeAmount = balance
                    unstake = ->
                        {address, lockedPool} = store.staking-accounts.chosen-lockup
                        lockup-address = store.staking-accounts.chosen-lockup.address
                        Timelock = web3t.velas.Timelock.at(lockup-address)
                        contract-address = Timelock.address
                        pool-address = lockedPool
                        amount = store.staking-accounts.unstakeAmount `times` (10^18)
                        return alert store, "#{lang.max} #{max.to-fixed! `div` (10^18)}" if +amount > +store.staking-accounts.stake-amount-total
                        return alert store, lang.actionProhibited, cb if +amount is 0
                        vlx2 =
                            store.current.account.wallets |> find (.coin.token is \vlx2)
                        vlx-address = vlx2.address2
                        data = Timelock.unstake.get-data(vlx-address, amount)
                        to = pool-address
                        err <- web3t.vlx2.send-transaction { to, data, amount:0, gas: 4600000, gas-price: 1000000 }
                        return cb err if err?
                    .pug.section
                        .title.pug
                            h3.pug Unstake
                        .description.pug
                            .pug.left
                                label.pug Unstake
                                amount-field { store, value: store.staking-accounts.unstakeAmount, on-change: change-unstake, placeholder: lang.unstake, token: "vlx2", id:"unstake-vlx-input" }
                                .pug.balance
                                    span.pug.small-btns
                                        button.small.pug(style=button-primary3-style on-click=use-min2) #{lang.min}
                                        button.small.pug(style=button-primary3-style on-click=use-max2) #{lang.max}
                                    span.pug #{lang.stake}:
                                    span.pug.color #{round-human (store.staking-accounts.chosen-lockup.stake `div` (10^18))}
                                        img.label-coin.pug(src="#{icons.vlx-icon}")
                                        span.pug.color #{vlx-token}
                                button { store, on-click: unstake , type: \secondary , icon : \apply , text: \btnApply }
staking-accounts = ({ store, web3t })->
    .pug.staking-accounts-content
        staking-accounts-content store, web3t
stringify = (value) ->
    if value? then
        round-human(parse-float value `div` (10^18))
    else
        '..'
fill-staking-account = ({web3t, store},[staking-account, ...staking-accounts], cb)->
    return cb null, [] if not staking-account?
    item = {}
    item.address = staking-account.key
    item.lockedFundsRaw = 0
    item.lockedFunds = 0
    item.status = \inactive
    item.lockedPool = 'lockedPool'
    item.stake = staking-account.stake
    item.lockedFundsReleaseTime = 0
    item.isForwardingEnabled = no
    item.maxWithdrawAllowed = 0
    item.lockThreshold = 0
    _item = [item]
    err, rest <- fill-staking-account {web3t, store}, staking-accounts
    all = _item ++ rest
    cb null, all
fill-staking-accounts = ({web3t, store}, cb)->
    accounts = store.staking.staking.accounts
    err, res <- fill-staking-account {web3t, store}, accounts
    return cb err if err?
    cb null, res
staking-accounts.fill-staking-accounts = fill-staking-accounts
staking-accounts.init = ({ store, web3t }, cb)->
    store.staking-accounts.stake.step = "topup"
    store.staking-accounts.stake.choosen-pull = null
    store.staking-accounts.currentTimelock = null
    store.staking-accounts.chosen-lockup-action = ''
    store.staking-accounts.withdrawAmount = 0
    store.staking-accounts.unstakeAmount = 0
    store.staking-accounts.add.add-validator-stake = 0
    store.staking-accounts.add.add-topup-stake = 0
    store.staking-accounts.lockup-was-choosed = no
    store.staking.pool-was-choosed = no
    store.staking-accounts.chosen-lockup = null
    err, result <- fill-staking-accounts {web3t, store}
    store.staking-accounts.lockupContracts = result
    cb null
#staking-accounts.rebuild-pools-list = ->
    #store.staking-accounts.chosen-lockup-action
module.exports = staking-accounts
#V31V1kD7DpT9eoRcdXf7T1fbFqcNh