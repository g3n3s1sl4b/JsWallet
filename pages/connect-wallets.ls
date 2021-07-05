require! {
    \react
    \./check-wallet.ls
    \prelude-ls : { each, keys, map, take, drop, foldl }
    \../seed.ls : seedmem
    \./menu.ls
    \../web3.ls
    \../wallets-funcs.ls
    \./manage-account.ls
    \./token-migration.ls
    \./add-coin.ls : add-coin-page
    \../get-lang.ls
    \../get-primary-info.ls
    \./history.ls
    \../icons.ls
    \./icon.ls
    \../menu-funcs.ls
    \../navigate.ls
    \../components/switch-account.ls
    \../components/checkbox.ls
    \../plugin-loader.ls : { get-all-coins }
}
.connect-wallet
    $mobile: 425px
    $tablet: 800px
    min-height: 100vh
    button.btn
        min-width: auto
        margin: 0
    .container
        margin: auto
        margin-top: 30px
        margin-bottom: 30px
        @media(max-width: $mobile)
            max-width: 600px
        max-width: 85vh 
        .trust-notification
            font-size: 14px
            opacity: 0.7
            padding: 20px 10px 0px
            display: block
        .buttons
            text-align: center
            >.button
                display: inline-block
                cursor: pointer
                height: 36px
                width: 120px
                font-weight: bold
                font-size: 10px
                text-transform: uppercase
                border-radius: var(--border-btn)
                border: 1px solid #CCC
                margin: 15px 5px
                padding: 0px 6px
                background: transparent
                text-overflow: ellipsis
                overflow: hidden
                white-space: nowrap
                &.disabled
                    opacity: 0.35
                .apply
                    vertical-align: middle
                    margin-right: 2px
                .cancel
                    vertical-align: middle
                    margin-right: 2px  
                .icon-svg-apply
                    position: relative
                    height: 12px
                    top: 2px
                    margin-right: 3px
                    filter: invert(23%) sepia(99%) saturate(1747%) hue-rotate(430deg) brightness(58%) contrast(175%)
                .icon-svg-cancel
                    position: relative
                    height: 12px
                    top: 2px
                    margin-right: 3px
                    filter: invert(22%) sepia(65%) saturate(7127%) hue-rotate(694deg) brightness(94%) contrast(115%)
    .your-account
        position: relative
        display: block
        border: 0 !important
        .tor
            right: 0px
            bottom: -27px
            .tor-content
                right: -55px
                &:after, &:before
                    right: 33%
                    top: -10%
        .switch-menu
            right: -1px
            top: 10px
            @media(max-width: 480px)
                right: -2px
    @media(max-width: 800px)
        margin-top: 0px
    .wallets
        @import scheme
        $border: var(--border-btn)
        $real-height: 300px
        $cards-height: 296px
        $pad: 20px
        $radius: 15px    
        height: 100vh
        overflow: auto
        box-sizing: border-box
        position: absolute
        left: 0
        top: 0
        bottom: 0
        $cards-pad: 15px
        right: 0
        margin: auto
        z-index: 2
        @media(max-width: $mobile)
            margin: 0
            height: calc(100vh - 100px)
        >*
            width: 100%
        .select-all-checkbox
            margin-left: 10px
            input:checked + .track
                background-color: #7081d8
        >.arrow
            position: absolute
            text-align: center
            cursor: pointer
            &.arrow-t
                top: 0
                margin-top: 10px
            &.arrow-d
                bottom: 0
                margin-bottom: 10px
                transform: rotate(180deg)
            &:not(.true)
                >.arrow-d
                    visibility: hidden
            >.arrow-container
                display: inline-block
                width: 100%
                max-width: 450px
                position: relative
        padding-top: 20px
        .wallet-container
            overflow: hidden
            overflow-y: auto
            border-radius: 0 0 $border $border
            max-height: 500px
            border-top: 1px solid #213040
            @media(max-width: $mobile)
                max-height: 100vh
                height: auto
                margin-bottom: 0px
            .wallet
                background: var(--bg-secondary)
                &.big
                    background: var(--bg-secondary)
            @media(max-width: $mobile)
                border-width: 1px 0 0 0 !important
        .switch-account
            float: right
            line-height: 2
            right: 20px
            position: relative
            display: inline-flex
            .ckeck
                color: #3cd5af
            .cancel
                color: #c25b5f
            .name
                text-overflow: ellipsis
                white-space: nowrap
                overflow: hidden
                width: 90px
                text-align: right
                cursor: default
            input
                outline: none
                width: 100px
                margin-top: -6px
                height: 36px
                line-height: 36px
                border-radius: 0px
                padding: 0px 10px
                font-size: 12px
                opacity: 1
            span
                cursor: pointer
            .icon
                vertical-align: middle
                margin-left: 20px
                transition: transform .5s
                &.rotate
                    transform: rotate(180deg)
                    transition: transform .5s
        .h1
            font-size: 12px
            text-transform: uppercase
            letter-spacing: 2px
            opacity: .8
        .icon-svg1
            position: relative
            height: 16px
            top: 2px
        .icon-svg2
            position: relative
            height: 10px
        .header
            display: flex
            align-items: center
            margin: 0 auto
            border-left: 1px solid var(--border)
            border-right: 1px solid var(--border)
            @media(max-width: $mobile)
                border: 0
            .head
                margin-left: 10px
                flex: 2
            .switch-account
                flex: 1
    .wallet
        .wallet-middle
            width: 100%
            padding: 10px 12px
            box-sizing: border-box
            color: #A8BACB
            font-size: 14px
            text-align: center
            position: relative
            display: inline-block
            height: auto
            border: 0 !important
            .address-holder
                div
                    a
                        padding-right: 10px
            &.title-balance
                display: none
                
get-all-groups = (store)->
    store.connected-wallet.tokens-groups |> keys
                
connect-wallets = ({store, web3t})->
    return null if store.connected-wallet.status.queried is no
    { current, open-account, lock, wallet-style, info, refresh, lock } = menu-funcs store, web3t
    { wallets, go-up, can-up, go-down, can-down } = wallets-funcs store, web3t
    style = get-primary-info store
    lang = get-lang store
    open-account = ->
        store.current.switch-account = not store.current.switch-account
    edit-account-name = ->
        store.current.edit-account-name = current-account-name!
    default-account-name = -> "Account #{store.current.account-index}"
    edit-account = (e)->
        store.current.edit-account-name = e.target.value
    done-edit = ->
        local-storage.set-item default-account-name!, store.current.edit-account-name
        cancel-edit-account-name!
    cancel-edit-account-name = ->
        store.current.edit-account-name = ""
    current-account-name = ->
        local-storage.get-item(default-account-name!) ? default-account-name!
    account-name = current-account-name!
    rotate-class =
        if store.current.switch-account then \rotate else \ ""
    view-account-template = ->
        .pug.switch-account.h1
            span.name.pug(on-click=open-account) #{account-name}
            span.pug.icon(on-click=edit-account-name)
                img.icon-svg1.pug(src="#{icons.create}")
            span.pug.icon(on-click=open-account class="#{rotate-class}")
                img.icon-svg2.pug(src="#{icons.arrow-down}")
    edit-account-template = ->
        .pug.switch-account.h1
            input.h1.pug(value="#{store.current.edit-account-name}" on-change=edit-account style=input)
            span.ckeck.pug.icon(on-click=done-edit)
                icon "Check", 20
            span.cancel.pug.icon(on-click=cancel-edit-account-name)
                icon "X", 20
    chosen-account-template =
        if store.current.edit-account-name is "" then view-account-template! else edit-account-template!
    /* Props */
    button-disabled = 
        | store.connected-wallet.tempChosenGroups.length > 0 => false
        | _ => true
        
    button-disabled-class = if button-disabled then "disabled" else ""
    
    allGroupsAreChecked = store.connectedWallet.tempChosenGroups.length is get-all-groups(store).length
    tokens-groups = store.connected-wallet.tokens-groups

    allCheckedValue = 
        | (allGroupsAreChecked is yes) => 'all' 
        | _ => null   
    /* Styles */
    border-style-w =
        border: "1px solid #{style.app.border}"
        background: "#{style.app.input}99"
    border-style =
        border-top: "1px solid #{style.app.border}"
    row =
        display: "flex"
        height: "100vh"
        margin-left: "60px"
    left-side =
        width: "45%"
    right-side =
        width: "55%"
        border-left: "1px solid #{style.app.border}"
    header-style =
        border-top: "1px solid #{style.app.border}"
        padding: "17px 0px 20px"
        color: style.app.text
        text-align: "left"
    input=
        background: style.app.wallet
        border: "1px solid #{style.app.border}"
        color: style.app.text
    header-left =
        margin-left: "10px"
    border-right=
        border-right: "1px solid #{style.app.border}"
    logo-style = 
        width: "30px"
        margin-left: "10px"
    button-style=
        color: style.app.text
    subtitle-style =
        margin-top: "-10px"
        
        
    /* Action Listeners */
    buffer = {tokens: []}
    get-all-tokens = ->
        tokens-groups 
            |> keys
            |> each (it)->
                console.log "it" it
                buffer.tokens = buffer.tokens ++ tokens-groups[it]
        buffer.tokens   
             
    check-all-groups = ->
        store.connectedWallet.tempChosenGroups = get-all-groups(store)
        
    uncheck-all-groups = ->
        store.connectedWallet.tempChosenGroups = []  
        
    cancel = ->
        uncheck-all-groups!
        go-to-home!
        
    confirm = ->
        navigate store, web3t, "connectwalletsfinalstep"
        
    go-to-home = ->
        store.connected-wallet.status.queried = no
        navigate store, web3t, "wallets"
        
    on-change = -> 
        if not allGroupsAreChecked   
            check-all-groups!
        else 
            uncheck-all-groups! 
            
            
    /* Render */
    .pug.connect-wallet(key="wallets")
        manage-account { store, web3t }
        token-migration { store, web3t }
        add-coin-page { store, web3t }
        .wallets.pug(key="wallets-body")
            .container.pug
                .head.pug
                    h3.pug.site-to-connect #{store.connected-wallet.origin }
                    h1.pug.header-title 
                        | Connect with Velas
                        span.pug.branding
                            img.pug(src="#{info.branding.logo-sm}" style=logo-style)
                h5.pug(style=subtitle-style) Select network(s)
                .header.pug(style=header-style)
                    .pug.select-all-checkbox
                        checkbox { store, on-change, value="#{allCheckedValue}" checked=allGroupsAreChecked, disabled=no }
                    span.pug.head.left.h1.hidden(style=header-left) All Networks
                    chosen-account-template
                    switch-account store, web3t
                .wallet-container.pug(key="wallets-viewport" style=border-style-w)
                    tokens-groups |> keys |> map check-wallet store, web3t
                span.pug.trust-notification 
                    | Only connect with sites you trust.
                .pug.confirmation
                    .pug.buttons
                        button.pug.button(on-click=cancel style=button-style id="prompt-close")
                            span.cancel.pug
                                img.icon-svg-cancel.pug(src="#{icons.close}")
                                | #{lang.cancel}
                        button.pug.button(class="#{button-disabled-class}" on-click=confirm style=button-style id="prompt-confirm" disabled=button-disabled)
                            span.apply.pug
                                img.icon-svg-apply.pug(src="#{icons.apply}")
                                | #{lang.confirm}
get-choosen-groups = (store, chosenAccounts)->
connect-wallets.init = ({ store, web3t }, cb)->
    console.log "1. [init]"
    delete store.current.send?wallet
    store.current.send?tx-type = \regular
    store.current.send.is-swap = no
    store.connectedWallet.importing-networks = no
    store.current.send.chosen-network = null
    console.log "We do not have account" if not store.current.account? 
    #return cb null if store.current.account?
    #TODO: fix this seedmem.get! but before need to ask users to make backup wallets
    seedmem.mnemonic = seedmem.get!
    err <- web3t.init
    
    #all-coins = get-all-coins(store)
    #err, wallets <- generate-coin-wallets all-coins
    #return cb err if err?
    
    /* Get previously added networks Object for current site */
    origin = store.connected-wallet.origin
    chosenNetworks = 
        | store.connected-wallet.connectedSites["#{origin}"]? => [...store.connected-wallet.connectedSites["#{origin}"]]
        | _ => {}
    chosenNetworks = store.connected-wallet.connected-sites["#{origin}"] ? {}  
    
    tempChosenGroups = Object.keys(chosenNetworks)
    store.connectedWallet.tempChosenGroups = tempChosenGroups 
    
    #store.connectedWallet.tempChosenGroups = get-all-groups(store)    
        
    cb null
    
    
connect-wallets.focus = ({ store, web3t }, cb)->
    console.log "2. [focus]"
    #err <- web3t.refresh   
    err <- web3t.refresh-balances
    err <- web3t.refresh-interface
    cb err
module.exports = connect-wallets