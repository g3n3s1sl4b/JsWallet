require! {
    \react
    \react-dom
    \bignumber.js
    \../../navigate.ls
    \../../get-primary-info.ls
    \../../get-lang.ls
    \../../history-funcs.ls
    \../icon.ls
    \prelude-ls : { map, split, filter, find, foldl, sort-by, unique, head, each }
    \../../math.ls : { div, times, plus, minus }
    \safe-buffer : { Buffer }
    \../../../web3t/addresses.js : { ethToVlx }
    \../../round-human.ls
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
    \../confirmation.ls : { prompt2, prompt-stake-account-amount, alert, confirm, notify }
    \../../components/pagination.ls
    \./error-funcs.ls : { get-error-message }
}
as-callback = (p, cb)->
    p.catch (err) -> cb err
    p.then (data)->
        cb null, data
.staking-accounts-content
    @keyframes blink-animation
        50%
            opacity: 0.3
    @-webkit-keyframes blink-animation
        50%
            opacity: 0.3
    .blink
        animation: 1s linear blink-animation  infinite
        -webkit-animation: 1s linear blink-animation  infinite
    .entities-loader
        display: block
        padding: 40px
        text-align: center
        .inner-section
            padding: 40px
            .item
                display: inline
    .notification-entity
        @media(max-width: 540px)
            display: block
            margin-top: 20px !important 
    .hint
        .tooltip
            position: absolute
            text-transform: uppercase
            left: 25px
            top: -8px
            z-index: 1
            line-height: 14px
            font-size: 9px
            font-weight: 600
            color: #fff
            padding: 5px
            background: #000
            visibility: hidden
            &:after, &:before
                right: 100%
                top: 21%
                border: solid transparent
                content: " "
                height: 0
                width: 0
                position: absolute
                pointer-events: none
            &:after
                border-color: rgba(136, 183, 213, 0)
                border-right-color: #000
                border-width: 6px
                margin-top: 2px
            &:before
                border-color: rgba(194, 225, 245, 0)
                border-width: 8px
                margin-top: 0px
    .hint
        &:hover
            .tooltip
                visibility: visible
    .title
        h3
            display: inline
        .amount
            color: white
            font-size: 11px
            opacity: 0.5    
    .form-group
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
        .table-scroll
            transition: max-height .5s
            table
                thead
                    td
                        cursor: pointer
                        &:hover
                            color: #dde6ff
                td
                    &.account-status
                        text-transform: capitalize
                        &.deactivating
                            color: #ff5555
                        &.activating
                            color: orange
                        &.active
                            color: green
                        &.inactive
                            color: gray
                    &.validator-address
                        text-align: center
                    border: none
cb = console.log
show-validator = (store, web3t)-> (validator)->
    li.pug #{validator}
export paginate = (array, per-page, page)->
    page = page - 1
    array.slice page * per-page, (page + 1) * per-page
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
    isSpinned = if ((store.staking.all-accounts-loaded is no or !store.staking.all-accounts-loaded?) and store.staking.accounts-are-loading is yes) then "spin disabled" else ""
    refresh = ->
        return if store.staking.all-accounts-loaded isnt yes
        store.staking.getAccountsFromCashe = no
        navigate store, web3t, "validators"
    build = (store, web3t)-> (item)->
        index = item.seed-index + 1
        return null if not item? or not item.key?
        { account, address, balance, balanceRaw, key, rent, seed, status, validator, active_stake, inactive_stake } = item
        activationEpoch = account?data?parsed?info?stake?delegation?activationEpoch
        deactivationEpoch = account?data?parsed?info?stake?delegation?deactivationEpoch
        activeBalanceIsZero =  +active_stake is 0
        max-epoch = web3t.velas.NativeStaking.max_epoch
        is-activating = activeBalanceIsZero and validator isnt ""
        has-validator = item.validator.toString!.trim! isnt ""
        $status =
            | item.status is "inactive" and (not has-validator) => "Not Delegated"
            | item.status is "inactive" and has-validator => "Delegated (Inactive)"
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
            undelegate-amount = item.balance
            agree <- confirm store, lang.areYouSureToUndelegate + " #{undelegate-amount} VLX \nfrom #{item.validator} ?"
            return if agree is no 
            #
            err, result <- as-callback web3t.velas.NativeStaking.undelegate(item.address)
            console.error "Undelegate error: " err if err?
            return alert store, err.toString! if err?
            <- notify store, lang.fundsUndelegated
            store.staking.getAccountsFromCashe = no
            navigate store, web3t, \validators
        choose = ->
            store.staking.chosen-account = item
            navigate store, web3t, \poolchoosing
            cb null
        withdraw = ->
            agree <- confirm store, lang.areYouSureToWithdraw
            return if agree is no
            { balanceRaw, rent, address, account } = item
            amount = account.lamports `plus` rent
            err, result <- as-callback web3t.velas.NativeStaking.withdraw(address, amount)
            err-message = get-error-message(err, result)
            return alert store, err-message if err-message?
            <- set-timeout _, 1000
            <- notify store, lang.fundsWithdrawn
            store.staking.getAccountsFromCashe = no
            navigate store, web3t, \validators
        stake-data = item?account?data?parsed?info?stake
        $button =
            | item.status is \inactive =>
                button { store, text: lang.to_delegate, on-click: choose, type: \secondary , icon : \arrowRight }
            | (+deactivationEpoch isnt +max-epoch) and (+store.staking.current-epoch >= +deactivationEpoch) =>
                button { store, text: lang.withdraw, on-click: withdraw, type: \secondary , icon : \arrowLeft }
            | _ => 
                disabled = item.status in <[ deactivating ]>
                if stake-data? and stake-data.delegation?
                    {activationEpoch, deactivationEpoch} = stake-data.delegation
                    if +activationEpoch < +deactivationEpoch and +deactivationEpoch isnt +max-epoch
                        disabled = yes     
                button { store, classes: "action-undelegate" text: lang.to_undelegate, on-click: undelegate , type: \secondary , icon : \arrowLeft, makeDisabled: disabled }
        tr.pug(class="#{item.status}" key="#{address}")
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
            if no
                td.pug(class="account-status #{status}") #{$status}
            td.pug
                $button
    cancel = ->
        store.staking-accounts.chosen-lockup = null
        store.staking-accounts.add.add-validator-stake = 0
    icon-style =
        color: style.app.loader
        margin-top: "10px"
        width: "inherit"
    staker-pool-style =
        max-width: 200px
        background: style.app.stats
    stats=
        background: style.app.stats
    notification-border =
        border: "1px solid orange"
        padding: 5px
        border-radius: 5px
        width: "auto"
        margin: "10px 20px 0"
    block-style = 
        display: "block"
    create-staking-account = ->
        cb = console.log 
        err <- as-callback web3t.velas.NativeStaking.getStakingAccounts(store.staking.parsedProgramAccounts)
        console.error err if err?
        amount <- prompt2 store, lang.howMuchToDeposit
        return if not amount?
        return if amount+"".trim!.length is 0
        min_stake = web3t.velas.NativeStaking.min_stake
        main_balance = get-balance!
        tx-fee = 5000 `div` (10^9)
        rest = 0.1
        amount = amount `minus` (store.staking.rent `plus` tx-fee `plus` rest) if +(main_balance `minus` amount) <= 0
        return alert store, lang.balanceIsNotEnoughToCreateStakingAccount  if +min_stake > +main_balance
        return alert store, lang.minimalStakeMustBe + " #{(min_stake)} VLX" if +min_stake  > +(amount)
        return alert store, lang.balanceIsNotEnoughToSpend + " #{(amount)} VLX" if +main_balance < +amount
        amount = amount * 10^9
        err, result <- as-callback web3t.velas.NativeStaking.createAccount(amount)
        console.error "Result sending:" err if err?
        if err?
            err = lang.balanceIsNotEnoughToCreateStakingAccount if ((err.toString! ? "").index-of("custom program error: 0x1")) > -1
        return alert store, err.toString! if err?
        store.staking.getAccountsFromCashe = no
        #checkAccountWasCreated
        <- set-timeout _, 1000
        <- notify store, lang.accountCreatedAndFundsDeposited
        navigate store, web3t, "validators"
    totalOwnStakingAccounts = store.staking.totalOwnStakingAccounts ? 0
    loadingAccountIndex = Math.min(totalOwnStakingAccounts, store.staking.loadingAccountIndex)
    perPage =  store.staking.accounts_per_page
    page = store.staking.current_accounts_page
    pagination-disabled = store.staking.accounts-are-loading is yes
    .pug.staking-accounts-content
        .pug
            .form-group.pug(id="create-staking-account")
                .pug.section.create-staking-account 
                    .title.pug
                        h3.pug #{lang.createStakingAccount}
                    .description.pug
                        span.pug
                            button {store, classes: "width-auto", text: lang.createAccount, no-icon:yes, on-click: create-staking-account, style: {width: \auto, display: \block}}
                        if store.staking.accounts.length is 0
                            span.pug.notification-entity(style=notification-border) Please create a staking account before you stake
                        else 
                            span.pug.notification-entity(style=notification-border) #{lang.youCanStakeMore}
        .pug
            .form-group.pug(id="staking-accounts")
                .pug.section
                    .title.pug
                        h3.pug.section-title #{lang.yourStakingAccounts} 
                            span.pug.amount (#{store.staking.accounts.length}) 
                        .pug
                            .loader.pug(on-click=refresh style=icon-style title="refresh" class="#{isSpinned}")
                                icon \Sync, 25
                    .description.pug
                        if store.staking.accounts-are-loading is no then
                            .pug.table-scroll
                                table.pug
                                    thead.pug
                                        tr.pug
                                            td.pug(width="3%" style=stats) #
                                            td.pug(width="40%" style=staker-pool-style title="Your Staking Account") #{lang.account} (?)
                                            td.pug(width="10%" style=stats title="Your Deposited Balance") #{lang.balance} (?)
                                            td.pug(width="30%" style=stats title="Where you staked") #{lang.validator} (?)
                                            td.pug(width="7%" style=stats title="The ID of your stake. This is made to simplify the search of your stake in validator list") #{lang.seed} (?)
                                            if no
                                                td.pug(width="10%" style=stats title="Current staking status. Please notice that you cannot stake / unstake immediately. You need to go through the waiting period. This is made to reduce attacks by staking and unstaking spam.") #{lang.status} (?)
                                            td.pug(width="10%" style=stats) #{(lang.action ? "Action")}
                                    tbody.pug
                                        paginate( (store.staking.accounts |> sort-by (.seed-index)), perPage, page)
                                            |> map build store, web3t
                        else
                            .pug.table-scroll
                                span.pug.entities-loader
                                    span.pug.inner-section
                                        h3.pug.item.blink Loading...
                                            span.pug.item  #{loadingAccountIndex}
                                            span.pug.item of
                                            span.pug.item  #{totalOwnStakingAccounts}
                        pagination {store, type: \accounts, disabled: pagination-disabled, config: {array: store.staking.accounts }}
staking-accounts = ({ store, web3t })->
    .pug.staking-accounts-content
        staking-accounts-content store, web3t
stringify = (value) ->
    if value? then
        round-human(parse-float value `div` (10^18))
    else
        '..'
module.exports = staking-accounts