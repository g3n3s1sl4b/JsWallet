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
        >.title
            position: absolute
            z-index: 999
            top: 0
            box-sizing: border-box
            width: 100%
            height: 100px
            color: gray
            font-size: 22px
            padding: 10px
            .closed
                position: absolute
                padding: 10px 20px
                font-size: 20px
                right: 0
                top: 0
                cursor: pointer
                &:hover
                    color: #CCC
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
        >.settings
            padding-top: 90px
            padding-bottom: 90px
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
create-item = ({ store, web3t }, item)-->
    console.log "item" item
    extension-disconnect = ->
        (store.connected-wallet.chosenAccounts).splice(store.connected-wallet.chosenAccounts.index-of(item), 1)      
        store.connected-wallet.openStatusBarPopup = no
        chrome.tabs.query {
            currentWindow: true
            active: true
        }, (tabs) ->
            activeTab = tabs.0
            response <- chrome.tabs.sendMessage activeTab.id, {'networks': store.connected-wallet.chosenAccounts}
            console.log "response", response 
    wallet = store.current.account.wallets |> find (-> it.coin.token is item)
    console.log "wallet" wallet 
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
    site = store.connected-wallet.site    
    connected-number = store.connected-wallet.chosenAccounts.length    
    .pug.manage-connected-wallets
        .account-body.pug(style=account-body-style)
            .pug.title(style=color)
                .pug
                    .pug #{site}
                    h4.pug You have #{connected-number} accounts connected to this site.   
                    .pug.closed(on-click=close)
                        icon \X, 20             
            .pug.settings
                .pug.section
                    .list.pug
                        store.connected-wallet.chosenAccounts
                            |> map create-item { store, web3t }