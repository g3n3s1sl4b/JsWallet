require! {
    \react
    \../get-primary-info.ls
    \../get-lang.ls
    \./icon.ls
    \../icons.ls 
    \../components/text-field.ls   
    \../round5edit.ls
    \../components/amount-field.ls
    \prelude-ls : { find }
    \../math.ls : { minus, div, plus, times }
}
.confirmation
    @-webkit-keyframes appear
        from
            opacity: 0
        to
            opacity: 1
    @-moz-keyframes appear
        from
            opacity: 0
        to
            opacity: 1
    @-o-keyframes appear
        from
            opacity: 0
        to
            opacity: 1
    @keyframes appear
        from
            opacity: 0
        to
            opacity: 1
    @import scheme
    position: fixed
    z-index: 99999999
    height: 100vh
    top: 0
    left: 0
    width: 100%
    box-sizing: border-box
    background: rgba(black, 0.7)
    display: flex
    justify-content: center
    align-items: center
    animation: appear .1s ease-in
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
    >.confirmation-body
        background: white
        text-align: center
        position: fixed
        width: 100%
        margin: 10px
        border-radius: var(--border-btn)
        width: calc(100% - 20px)
        max-width: 550px
        box-shadow: 7px 10px 13px #0000001f, -16px 20px 13px #00000024
        input
            border-radius: var(--border-btn)
            height: 36px
            width: 90px
            line-height: 36px
            font-size: 13px
            outline: none
        >.header
            padding: 15px 0 0
            font-size: 17px
            font-weight: bold
            margin-bottom: 10px
            border-radius: 10px 10px 0 0
        >.text
            padding: 10px
            input
                border-radius: var(--border-btn)
        >.buttons
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
                .apply
                    vertical-align: middle
                    margin-right: 2px
                .cancel
                    vertical-align: middle
                    margin-right: 2px
    .pin-input
        .input-area
            max-width: 200px;
            margin: auto;
        input
            text-align: left
            font-size: 12px
            display: inline-block
            height: 36px
            background: transparent
            border: 0
            border-radius: var(--border-btn)
            outline: none
            width: 130px
            margin-bottom: 5px
            letter-spacing: 5px
            padding: 7px 25px 7px 7px
            box-sizing: border-box
            &:focus
                border-color: #248295
            &:placeholder
                color: $primary + 40
            @media screen and (max-width: 800px)
                padding: 7px 0
                text-align: center
alert-modal = (store)->
    return null if typeof! store.current.alert isnt \String
    cancel = ->
        store.current.alert = no
        callback = state.callback
        state.callback = null
        callback no if typeof! callback is \Function
    style = get-primary-info store
    confirmation-style =
        background: style.app.background
        background-color: style.app.bgspare
        color: style.app.text
    confirmation-style2 =
        color: style.app.text
    button-style=
        color: style.app.text
    confirmation=
        background: style.app.background
        background-color: style.app.bgspare
        color: style.app.text
        border-bottom: "1px solid #{style.app.border}"
    lang = get-lang store
    .pug.confirmation
        .pug.confirmation-body(style=confirmation)
            .pug.header(style=confirmation-style) Alert
            .pug.text(style=confirmation-style2) #{store.current.alert}
            .pug.buttons
                button.pug.button(on-click=cancel style=button-style id="alert-close")
                    span.cancel.pug
                        img.icon-svg-cancel.pug(src="#{icons.close}")
                        | #{lang.cancel}
notification-modal = (store)->
    return null if typeof! store.current.notification isnt \String
    cancel = ->
        store.current.notification = no
        callback = state.callback
        state.callback = null
        callback no if typeof! callback is \Function
    style = get-primary-info store
    confirmation-style =
        background: style.app.background
        background-color: style.app.bgspare
        color: style.app.text
    confirmation-style2 =
        color: style.app.text
    button-style=
        color: style.app.text
    confirmation=
        background: style.app.background
        background-color: style.app.bgspare
        color: style.app.text
        border-bottom: "1px solid #{style.app.border}"
    lang = get-lang store
    .pug.confirmation
        .pug.confirmation-body(style=confirmation)
            .pug.header(style=confirmation-style) Alert
            .pug.text(style=confirmation-style2) #{store.current.notification}
            .pug.buttons
                button.pug.button(on-click=cancel style=button-style id="notification-close")
                    span.cancel.pug
                        img.icon-svg-apply.pug(src="#{icons.apply}")
                        | Ok
confirmation-modal = (store)->
    return null if typeof! store.current.confirmation isnt \String
    confirm = ->
        store.current.confirmation = yes
        callback = state.callback
        state.callback = null
        callback yes if typeof! callback is \Function
    cancel = ->
        store.current.confirmation = no
        callback = state.callback
        state.callback = null
        callback no if typeof! callback is \Function
    style = get-primary-info store
    confirmation-style =
        background: style.app.background
        background-color: style.app.bgspare
        color: style.app.text
    confirmation-style2 =
        color: style.app.text
    button-style=
        color: style.app.text
    confirmation=
        background: style.app.background
        background-color: style.app.bgspare
        color: style.app.text
        border-bottom: "1px solid #{style.app.border}"
    lang = get-lang store
    .pug.confirmation
        .pug.confirmation-body(style=confirmation)
            .pug.header(style=confirmation-style) #{lang.confirmation}
            .pug.text(style=confirmation-style2) #{store.current.confirmation}
            .pug.buttons
                button.pug.button(on-click=confirm style=button-style id="confirmation-confirm")
                    span.apply.pug
                        img.icon-svg-apply.pug(src="#{icons.apply}")
                        | #{lang.confirm}
                button.pug.button(on-click=cancel style=button-style id="confirmation-close")
                    span.cancel.pug
                        img.icon-svg-cancel.pug(src="#{icons.close}")
                        | #{lang.cancel}
prompt-modal = (store)->
    return null if typeof! store.current.prompt isnt \String
    confirm = ->
        store.current.prompt = yes
        callback = state.callback
        state.callback = null
        prompt-answer = store.current.prompt-answer
        store.current.prompt-answer = ""
        callback prompt-answer if typeof! callback is \Function
    cancel = ->
        store.current.prompt = no
        callback = state.callback
        state.callback = null
        callback null if typeof! callback is \Function
        store.current.prompt-answer = ""
    change-input = (e)->
        store.current.prompt-answer = e.target.value
    style = get-primary-info store
    confirmation-style =
        background: style.app.background
        background-color: style.app.bgspare
        color: style.app.text
    input-style =
        background: style.app.input
        color: style.app.text
        border: "0"
    button-style=
        color: style.app.text
    confirmation=
        background: style.app.background
        background-color: style.app.bgspare
        color: style.app.text
        border-bottom: "1px solid #{style.app.border}"
    lang = get-lang store
    .pug.confirmation
        .pug.confirmation-body(style=confirmation)
            .pug.header(style=style=confirmation-style) #{lang.confirmation}
            .pug.text(style=style=confirmation-style) #{store.current.prompt}
            .pug
                input.pug(on-change=change-input value="#{store.current.prompt-answer}" style=input-style id="prompt-input")
            .pug.buttons
                button.pug.button(on-click=confirm style=button-style id="prompt-confirm")
                    span.apply.pug
                        img.icon-svg-apply.pug(src="#{icons.apply}")
                        | #{lang.confirm}
                button.pug.button(on-click=cancel style=button-style id="prompt-close")
                    span.cancel.pug
                        img.icon-svg-cancel.pug(src="#{icons.close}")
                        | #{lang.cancel}
prompt-modal2 = (store)->
    return null if typeof! store.current.prompt2 isnt \String
    wallet = store.current.account.wallets |> find (-> it.coin.token is \vlx_native)
    confirm = ->
        return if not store.current.prompt-answer? or store.current.prompt-answer is 0 or store.current.prompt-answer is ""
        store.current.prompt2 = yes
        callback = state.callback
        state.callback = null
        prompt-answer = store.current.prompt-answer
        store.current.prompt-answer = ""
        callback prompt-answer if typeof! callback is \Function
    cancel = ->
        store.current.prompt2 = no
        callback = state.callback
        state.callback = null
        callback null if typeof! callback is \Function
        store.current.prompt-answer = ""
    amount-change = (e)->
        balance = (wallet?balance ? 1)
        max-amount = Math.floor(balance `minus` 1)
        amount =
            | e.target.value > max-amount => max-amount
            | _ => e.target.value
        store.current.prompt-answer = amount
    style = get-primary-info store
    confirmation-style =
        background: style.app.background
        background-color: style.app.bgspare
        color: style.app.text
    input-style =
        background: style.app.input
        color: style.app.text
        border: "0"
    input-holder-style = 
        max-width: '250px'
        margin: 'auto'
    button-style=
        color: style.app.text
    confirmation=
        background: style.app.background
        background-color: style.app.bgspare
        color: style.app.text
        border-bottom: "1px solid #{style.app.border}"
    lang = get-lang store
    button-primary3-style=
        border: "0"
        color: style.app.text2
        background: style.app.primary3
        background-color: style.app.primary3-spare
        cursor: "pointer"
    max-amount-container =
        text-align: "left"
    use-max-amount = !->
        store.current.prompt-answer = 
            | not wallet? => 0
            | _ => Math.floor(wallet.balance `minus` 1)
    .pug.confirmation
        .pug.confirmation-body(style=confirmation)
            .pug.header(style=style=confirmation-style)#{store.current.prompt2}
            .pug.text(style=style=confirmation-style)
            .pug(style=input-holder-style)
                amount-field { store, value: "#{round5edit store.current.prompt-answer}", on-change: amount-change, placeholder="0", id="prompt-input" }
                .pug.max-amount(style=max-amount-container)
                    button.pug.send-all(on-click=use-max-amount style=button-primary3-style type="button" id="send-max") #{lang.use-max}
            .pug.buttons
                button.pug.button(on-click=confirm style=button-style id="prompt-confirm")
                    span.apply.pug
                        img.icon-svg-apply.pug(src="#{icons.apply}")
                        | #{lang.confirm}
                button.pug.button(on-click=cancel style=button-style id="prompt-close")
                    span.cancel.pug
                        img.icon-svg-cancel.pug(src="#{icons.close}")
                        | #{lang.cancel}
prompt-modal3 = (store)->
    return null if typeof! store.current.prompt3 isnt \String
    console.log "prompt3-modal" 
    chosenAccount = store.staking.chosenAccount
    rent = chosenAccount.rent
    active_stake = chosenAccount.active_stake `div` (10^9)
    inactive_stake = chosenAccount.inactive_stake `div` (10^9)
    balanceRaw = chosenAccount.balanceRaw `div` (10^9)
    console.log "Account" chosenAccount
    min_stake = "1"
    confirm = ->
        return if not store.current.prompt-answer? or +store.current.prompt-answer is 0 or store.current.prompt-answer is ""
        store.current.prompt3 = yes
        callback = state.callback
        state.callback = null
        prompt-answer = store.current.prompt-answer
        store.current.prompt-answer = ""
        callback prompt-answer if typeof! callback is \Function
    cancel = ->
        store.current.prompt3 = no
        callback = state.callback
        state.callback = null
        callback null if typeof! callback is \Function
        store.current.prompt-answer = ""
    amount-change = (e)->
        balance = (chosenAccount?balance ? 1)
        max-amount = Math.floor(balance `minus` min_stake)
        amount =
            | e.target.value > max-amount => max-amount
            | _ => e.target.value
        store.current.prompt-answer = amount
    style = get-primary-info store
    confirmation-style =
        background: style.app.background
        background-color: style.app.bgspare
        color: style.app.text
    input-style =
        background: style.app.input
        color: style.app.text
        border: "0"
    input-holder-style = 
        max-width: '250px'
        margin: 'auto'
    button-style=
        color: style.app.text
    confirmation=
        background: style.app.background
        background-color: style.app.bgspare
        color: style.app.text
        border-bottom: "1px solid #{style.app.border}"
    lang = get-lang store
    button-primary3-style=
        border: "0"
        color: style.app.text2
        background: style.app.primary3
        background-color: style.app.primary3-spare
        cursor: "pointer"
    max-amount-container =
        text-align: "left"
    use-max-amount = !->
        store.current.prompt-answer = 
            | not chosenAccount? => 0
            | _ => balanceRaw `minus` active_stake `minus` min_stake
    .pug.confirmation
        .pug.confirmation-body(style=confirmation)
            .pug.header(style=style=confirmation-style)#{store.current.prompt3}
            .pug.text(style=style=confirmation-style)
            .pug(style=input-holder-style)
                amount-field { store, value: "#{round5edit store.current.prompt-answer}", on-change: amount-change, placeholder="0", id="prompt-input" }
                .pug.max-amount(style=max-amount-container)
                    button.pug.send-all(on-click=use-max-amount style=button-primary3-style type="button" id="send-max") #{lang.use-max}
            .pug.buttons
                button.pug.button(on-click=confirm style=button-style id="prompt-confirm")
                    span.apply.pug
                        img.icon-svg-apply.pug(src="#{icons.apply}")
                        | #{lang.confirm}
                button.pug.button(on-click=cancel style=button-style id="prompt-close")
                    span.cancel.pug
                        img.icon-svg-cancel.pug(src="#{icons.close}")
                        | #{lang.cancel}
prompt-password-modal = (store)->
    return null if typeof! store.current.prompt-password isnt \String
    confirm = ->
        store.current.prompt-password = yes
        callback = state.callback
        state.callback = null
        prompt-answer = store.current.prompt-password-answer
        store.current.prompt-password-answer = ""
        callback prompt-answer if typeof! callback is \Function
    cancel = ->
        store.current.prompt-password = no
        callback = state.callback
        state.callback = null
        callback null if typeof! callback is \Function
        store.current.prompt-password-answer = ""
    change-input = (e)->
        store.current.prompt-password-answer = e.target.value
    style = get-primary-info store
    confirmation-style =
        background: style.app.background
        background-color: style.app.bgspare
        color: style.app.text
    input-style =
        background: style.app.input
        color: style.app.text
        border: "0"
    button-style=
        color: style.app.text
    confirmation=
        background: style.app.background
        background-color: style.app.bgspare
        color: style.app.text
        border-bottom: "1px solid #{style.app.border}"
    catch-key = ->
        confirm! if it.key-code is 13
    focus-input = (ref)!->
        ref.focus! if ref?
    lang = get-lang store
    .pug.confirmation
        .pug.confirmation-body(style=confirmation)
            .pug.header(style=style=confirmation-style) #{lang.confirmation}
            .pug.text(style=style=confirmation-style) #{store.current.prompt-password}
            .pug.pin-input
                text-field { ref:(c)->{ a = focus-input(c)}, store, type: 'password' value: store.current.prompt-password-answer, placeholder: "", on-change: change-input , on-key-down: catch-key, id="prompt-input" }  
            .pug.buttons
                button.pug.button(on-click=confirm style=button-style id="prompt-confirm")
                    span.apply.pug
                        img.icon-svg-apply.pug(src="#{icons.apply}")
                        | #{lang.confirm}
                button.pug.button(on-click=cancel style=button-style id="prompt-close")
                    span.cancel.pug
                        img.icon-svg-cancel.pug(src="#{icons.close}")
                        | #{lang.cancel}
export confirmation-control = (store)->
    #for situation when we ask peen before action. this window should be hidden
    return null if store.current.page-pin?
    .pug
        prompt-modal3 store
        confirmation-modal store
        prompt-modal2 store
        prompt-modal store
        prompt-password-modal store
        alert-modal store
        notification-modal store
state=
    callback: null
export confirm = (store, text, cb)->
    store.current.confirmation = text
    state.callback = cb
export notify = (store, text, cb)->
    store.current.notification = text
    state.callback = cb
export prompt = (store, text, cb)->
    store.current.prompt = text
    state.callback = cb
export prompt2 = (store, text, cb)->
    store.current.prompt2 = text
    state.callback = cb
export prompt3 = (store, text, cb)->
    store.current.prompt3 = text
    state.callback = cb
export prompt-password = (store, text, cb)->
    store.current.prompt-password = text
    state.callback = cb
export alert = (store, text, cb)->
    store.current.alert = text
    state.callback = cb
window.confirm-state = state