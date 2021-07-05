require! {
    \react
    \../icons.ls
    \../get-primary-info.ls
    \../get-lang.ls
    \../pages/confirmation.ls : { alert }
}
.statusbar
    .connectStatusButton
        position: absolute
        top: 20px
        left: 20px
        z-index: 13
        border-width: 1px
        border-style: solid
        border-color: rgb(70, 66, 66)
        padding: 6px 8px
        cursor: pointer
        display: inline-block
        margin-top: -5px
        .connected-wallet-state
            position: absolute
        .connection-state-icon  
            display: inline-block
            width: 7px
            height: 7px
            background-color: white
            opacity: 0.3
            margin-right: 8px
            &:not(.disconnected)
                background-color: #68da68 !important
                opacity: 1 !important
        .button-status-text
            color: white
            opacity: 0.7
            font-size: 12px
            display: inline-block           
statusbar = ({ store, web3t })->
    lang = get-lang store
    style = get-primary-info store
    applied-text = lang[text] ? text ? ""
    applied-icon = icons[icon ? text] ? icons.more
    text = 
        | Object.keys(store.connected-wallet.chosenNetworks).length > 0 => "Connected"
        | _ => "Disconnected"
    status = 
        |  Object.keys(store.connected-wallet.chosenNetworks).length > 0 => "connected"
        | _ => "disconnected" 
    on-click = -> 
        #return alert store, "Velas is not connected this site.\nTo connect site to a web3t, find the connect button on their site.\n\nOr you can manually connect current site." if store.connected-wallet.chosenAccounts.length <= 0  
        store.connected-wallet.openStatusBarPopup = yes     
    .pug.statusbar( on-click=on-click )
        .pug.connectStatusButton.button.connect-wallet-btn(class="#{status}")
            .pug.connection-state-icon(class="#{status}")
            .pug.button-status-text #{text}
module.exports = statusbar