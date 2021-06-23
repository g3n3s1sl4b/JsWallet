require! {
    \react
    \prelude-ls : { map, filter, find }
    \./loading2.ls
    \../web3.ls
    \../get-primary-info.ls
    \../get-lang.ls
    \./icon.ls
    \../icons.ls
    \../../web3t/providers/superagent.ls : { get }
    \../navigate.ls
}
.manage-connected-wallets   
    @import scheme
    @keyframes bounceIn
        from
            opacity: 0
            transform: scale3d(0.8, 0.8, 0.8)
        to
            opacity: 1
            transform: scale3d(1, 1, 1)
    position: absolute
    width: 100%
    top: 0
    z-index: 999
    padding-top: 5%
    box-sizing: border-box
    padding: 10px
    background: rgba(black, 0.08)
    backdrop-filter: blur(5px)
    height: 100vh
    >.account-body
        max-width: 600px
        display: inline-block
        animation-duration: 0.5s
        animation-name: bounceIn
        background: white
        width: 100%
        margin-top: 5vh
        margin-bottom: 25vh
        border-radius: var(--border-btn)
        position: relative
        height: 65vh
        overflow: hidden
        box-shadow: 17px 10px 13px #0000001f, -6px 10px 13px #00000024
        .closed
            position: absolute
            z-index: 3
            padding: 10px 20px
            font-size: 20px
            right: 0
            top: 0
            cursor: pointer
            &:hover
                color: #CCC
        .account-body-inner
            margin: auto
            position: absolute
            top: 0
            bottom: 0
            left: 0
            right: 0
            padding: 20px
        .title
            z-index: 999
            top: 0
            box-sizing: border-box
            width: 100%
            color: gray
            font-size: 22px
            .search-content
                position: relative
                padding: 0 10px
                @media (max-width: 580px)
                    padding: 0
                .search
                    margin-top: 10px
                    border: 1px solid #CCC
                    padding: 9px
                    border-radius: var(--border-btn)
                    width: 100%
                    padding-left: 35px
                    box-sizing: border-box
                    font-size: 13px
                    outline: none
                .icon
                    top: 6px
                    left: 20px
                    position: absolute
                    @media (max-width: 580px)
                        left: 10px
        .settings
            padding-top: 0px
            padding-bottom: 30px
            height: calc(65vh - 180px)
            overflow-y: scroll
            .section
                position: relative
                min-height: 200px
                .list
                    height: 80%
                    padding: 10px
                    margin: auto 10px
                    @media (max-width: 580px)
                        padding: 10px 0
                    .item
                        width: 49%
                        margin-bottom: 10px
                        display: inline-block
                        background: #642dbd
                        border-radius: var(--border-btn)
                        padding: 10px
                        text-align: left
                        float: left
                        box-sizing: border-box
                        @media (max-width: 580px)
                            width: 100%
                            float: none
                        &:nth-child(odd)
                            margin-right: 10px
                            @media (max-width: 580px)
                                margin-right: 0
                        >*
                            display: inline-block
                            vertical-align: middle
                            height: 40px
                            line-height: 40px
                            box-sizing: border-box
                        input
                            margin: 0 5px
                            border-radius: var(--border-btn)
                            width: calc(100% - 90px)
                            border: 0
                            padding: 5px 10px
                            outline: none
                            font-size: 15px
                        img
                            width: 40px
                            border-radius: 0px
                        .title
                            margin-left: 10px
                            color: gray
                            width: calc(100% - 90px)
                        button
                            width: 40px
                            height: 40px
                            line-height: 45px
                            border-radius: var(--border-btn)
                            border: 0 !important
                            box-sizing: border-box
                            padding: 0
                            margin: 0
                            cursor: pointer
                            color: black
                            background: transparent
                            outline: none
                            &:hover
                                color: white
                                opacity: .6
                                transition: .5s
                            img
                                width: 15px    
                            >*
                                vertical-align: middle
        .extra-button    
            display: inline-block
            cursor: pointer
            padding: 10px
            width: auto
            font-weight: bold
            font-size: 10px
            text-transform: uppercase
            border-radius: var(--border-btn)
            border: 1px solid #CCC
            margin: 15px 5px
            background: transparent
            text-overflow: ellipsis
            overflow: hidden
            white-space: nowrap
            margin-top: 40px
create-item = ({ store, web3t }, item)-->
    extension-disconnect = ->
        whom = store.connected-wallet.activeTab
        return if not whom?
        /* Get current opened tab origin */ 
        origin = store.connected-wallet.origin 
        chosenAccounts = store.connected-wallet.connected-sites["#{origin}"] ? [] 
        chosenAccounts.splice(chosenAccounts.index-of(item), 1)      
        tabs <- chrome.tabs.query {currentWindow: true, active: true}
        activeTab = tabs?0
        response <- chrome.tabs.sendMessage whom, {'networks': chosenAccounts}
        console.log "response", response 
    wallet = store.current.account.wallets |> find (-> it.coin.token is item)
    {name, image} = wallet.coin    
    title = "#{name}"
    style = get-primary-info store
    button-style =
        border: "1px solid #{style.app.text}"
        color: style.app.text
    background =
        background: style.app.input
    menu-style=
        color: style.app.text
    .item.pug(style=background)
        img.pug(src="#{image}")
        span.pug.title(style=menu-style) #{title}
        button.pug(on-click=extension-disconnect style=button-style)
            img.icon-svg1.pug(src="#{icons.close}")
module.exports = ({ store, web3t } )->
    return null if store.connected-wallet.openStatusBarPopup isnt yes
    network = store.current.network   
    close = ->
        store.connected-wallet.openStatusBarPopup = no
    style = get-primary-info store
    account-body-style =
        background: style.app.background
        background-color: style.app.bgspare
        color: style.app.text
    color =
        color: style.app.text
    lang = get-lang store
    input-style=
        color: style.app.text
        background: style.app.input
        border: "0"
    button-style =
        border: "1px solid #{style.app.text}"
        color: style.app.text
    site = store.connected-wallet.site 
    origin = store.connected-wallet.origin  
    chosenAccounts = store.connected-wallet.connected-sites["#{origin}"] ? []  
    connected-number = chosenAccounts.length 
    go-to-manual-connect = ->
        store.connected-wallet.status.queried = yes      
        navigate store, web3t, "connectwallets"   
    .pug.manage-connected-wallets
        .account-body.pug(style=account-body-style)
            .pug.closed(on-click=close)
                icon \X, 20   
            .account-body-inner.pug
                .pug.title(style=color)
                    .pug
                        .pug #{site}
                        h6.pug You have #{connected-number} wallet(s) connected to this site.   
                .pug.settings
                    .pug.section
                        if chosenAccounts.length <= 0
                            .pug
                                .pug Velas is not connected this site.\nTo connect site to a web3t, find the connect button on their site.\n\nOr you can manually connect current site.
                                .extra-button.pug(on-click=go-to-manual-connect style=button-style) Manually connect
                        else
                            .list.pug
                                chosenAccounts
                                    |> map create-item { store, web3t }