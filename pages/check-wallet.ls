require! {
    \react
    \../tools.ls : { money }
    \prelude-ls : { each, find, map }
    \../wallet-funcs.ls
    \../get-lang.ls
    \./icon.ls
    \../get-primary-info.ls
    \../../web3t/providers/superagent.ls : { get }
    \../icons.ls
    \../round-human.ls
    \./confirmation.ls : { alert }
    \../components/button.ls
    \../components/address-holder.ls
    \../components/checkbox.ls
}
.wallet
    @import scheme
    $cards-height: 324px
    $pad: 20px
    $radius: 15px
    position: relative
    cursor: pointer
    $card-height: 60px
    min-height: $card-height
    &.disabled-wallet-item
        opacity: 0.4
        filter: grayscale(1)
        cursor: no-drop
    &.last
        height: 60px
    $mt: 20px
    box-sizing: border-box
    overflow: hidden
    transition: height .5s
    border: 0px
    &:first-child
        margin-top: 0
        box-shadow: none
    &:last-child
        margin-bottom: 0px
    .pending
        color: orange
    &.over
        background: #CCC
    &.big
        display: flex
        align-items: center
        margin: 10px
        &:last-of-type
            border-bottom: none !important
    &.active
    .wallet-middle
        width: 60%
        max-width: 250px
        >.uninstall
            text-align: left
            font-size: 10px
            padding-top: 5px
        box-sizing: border-box
        height: 85px
        float: left
        padding: 20px
        border-top: 1px solid rgb(107, 38, 142)
        border-right: 1px solid rgb(107, 38, 142)
        &:last-child
            display: block
        &:last-child
            border-right: 0 !important
        .name
            color: #fff
            font-size: 16px
            font-weight: 700
            &.per
                font-size: 10px
                color: orange
                font-weight: 100
            &:last-child
                font-size: 10px
                text-transform: uppercase
                letter-spacing: 2px
                margin-top: 5px
                opacity: .8
        .title-balance
            color: #fff
            font-size: 14px
            text-align: left
        span
            padding-left: 40px
        a
            text-align: left
    .wallet-top
        padding: 0 12px 0 0
        box-sizing: border-box
        width: 100%
        color: #677897
        font-size: 14px
        text-align: left
        overflow: hidden
        >*
            display: inline-block
            box-sizing: border-box
            vertical-align: top
            line-height: 16px
        >.top-left
            width: 100%
            display: flex
            text-align: left
            overflow: hidden
            text-overflow: ellipsis
            @media screen and (min-width: 801px)
                padding-top: 5px
            >*
                display: inline-block
                margin: 0 8px
            .outer-checkbox
                margin-left: 0
            >.img
                vertical-align: top
                margin-right: 10px
                width: 40px
                >img
                    vertical-align: top
                    max-width: 50px
                    $s: 35px
                    border-radius: 0
                    height: $s
                    @media screen and (min-width: 801px)
                        padding-top: 4px
            >.info
                text-align: left
                margin-left: 0px
                text-overflow: ellipsis
                overflow: hidden
                width: auto
                @media screen and (max-width: 390px)
                    display: none
                >.name
                    padding-left: 3px
                >.price
                    font-size: 11px
                    font-weight: bold
                    overflow: hidden
                    text-overflow: ellipsis
                    opacity: .5
                    padding: 0
                    letter-spacing: .4px
                    &.token
                        opacity: 1
                        font-size: 12px
        .top-middle
            width: 100%
            text-align: left
            .label-coin
                height: 16px
                top: 3px
                padding-left: 4px
                position: relative
            >.balance
                &:last-child
                    font-weight: bold
                    font-size: 13px
                &.title
                    @media screen and (max-width: 220px)
                        display: none
                .title-balance
                    display: none
        .top-right
            width: 40%  
            text-align: right
            .wallet-swap img
                filter: invert(1)
            .icon
                vertical-align: sub
                .icon-svg-create
                    height: 9px
                    transform: rotate(-90deg)
                    vertical-align: inherit
                    opacity: .3
            @media screen and (max-width: 800px)
                width: 35%
                display: flex
                float: right
                flex-direction: row-reverse
            >button
                outline: none
                margin-bottom: 5px
                margin-left: 5px
                cursor: pointer
                border: 0
                $round: 36px
                padding: 0
                box-sizing: border-box
                border-radius: $border
                font-size: 10px
                width: auto
                padding: 0 6px
                height: $round
                color: #6CA7ED
                text-transform: uppercase
                font-weight: bold
                background: transparent
                transition: all .5s
                text-overflow: ellipsis
                overflow: hidden
                width: 80px
                .icon-svg
                    @media screen and (max-width: 800px)
                        padding: 0
                .icon
                    position: relative
                    height: 16px
                    top: 2px
                @media screen and (max-width: 800px)
                    width: 40px
                    line-height: 30px
cb = console~log
module.exports = (store, web3t, wallets, wallet)-->
    { button-style, uninstall, wallet, active, big, balance, balance-usd, pending, send, receive, swap, expand, usd-rate, last } = wallet-funcs store, web3t, wallets, wallet
    lang = get-lang store
    style = get-primary-info store
    label-uninstall =
        | store.current.refreshing => \...
        | _ => "#{lang.hide}"
    wallet-style=
        color: style.app.text
    border-style =
        border-bottom: "1px solid #{style.app.border}"
    border =
        border-top: "1px solid #{style.app.border}"
        border-right: "1px solid #{style.app.border}"
    button-primary3-style=
        border: "0"
        color: style.app.text2
        background: style.app.primary3
        background-color: style.app.primary3-spare
    address-input=
        color: style.app.color3
        background: style.app.bg-primary-light
    btn-icon =
        filter: style.app.btn-icon
    icon-color=
        filter: style.app.icon-filter
    placeholder =
        | store.current.refreshing => "placeholder"
        | _ => ""
    placeholder-coin =
        | store.current.refreshing => "placeholder-coin"
        | _ => ""
    name = wallet.coin.name ? wallet.coin.token
    token = wallet.coin.token
    token-display = (wallet.coin.nickname ? "").to-upper-case!
    makeDisabled = store.current.refreshing
    wallet-is-disabled  = isNaN(wallet.balance)
    is-loading = store.current.refreshing is yes
    account-index = store.connected-wallet.tempChosenAccounts.index-of(token)
    disabled-class = if not is-loading and wallet-is-disabled then "disabled-wallet-item" else ""
    value = store.connected-wallet.tempChosenAccounts[account-index] ? null
    isChecked = value?
    wallets_keys = wallets |> map (-> it.coin.token)
    tempChosenAccounts = store.connected-wallet.tempChosenAccounts
    on-change = ->
        console.log "[Check wallet on-change]"         
        if account-index > -1
            store.connected-wallet.tempChosenAccounts.splice(account-index, 1)
        else
            store.connected-wallet.tempChosenAccounts.push(token)
        store.connected-wallet.tempChosenAccountsAllChecked = 
            | wallets_keys.length is tempChosenAccounts.length => yes 
            | _ => no   
    .wallet.pug.wallet-item(class="big" key="#{token}" style=border-style)
        .wallet-top.pug
            .top-left.pug(style=wallet-style)
                checkbox { store, on-change, value="#{value}" checked=isChecked, disabled=no }
                .img.pug(class="#{placeholder-coin}")
                    img.pug(src="#{wallet.coin.image}")
                .info.pug
                    .balance.pug.title(class="#{placeholder}") #{name}
                    .price.token.pug(class="#{placeholder}" title="#{wallet.balance}")
                        span.pug #{ round-human wallet.balance }
                        span.pug #{ token-display }
                    .price.pug(class="#{placeholder}" title="#{balance-usd}")
                        span.pug #{ round-human balance-usd}
                        span.pug USD
        .wallet-middle.pug(style=border)
            address-holder { store, wallet, type: \bg }