require! {
    \react
    \../get-primary-info.ls
    \../round5.ls
    \../round.ls
    \../round-number.ls
    \prelude-ls : { find }
    \../math.ls : { times }
    \./keyboard.ls
    \../numbers.js : {formatNum, parse-num}
}
.input-area
    @import scheme
    position: relative
    margin: 10px 0
    width: 100%
    box-sizing: border-box
    height: 36px
    line-height: 36px
    >*
        display: inline-block
        box-sizing: border-box
        margin: 0 !important
        height: inherit
        line-height: inherit
        vertical-align: top
        z-index: 1
    >input
        background: transparent
        overflow-x: auto
        color: white
        display: inline-block
        width: calc(100% - 70px) !important
        padding: 0 10px
        border-radius: $border 0 0 $border !important
        border: none
        text-align: left
        &:disabled
            opacity: .2
    >.suffix
        $color: rgba(#ccc, 0.3)
        width: 70px
        border-left: 1px solid $color
        text-align: center
        border-radius: 0 $border $border 0
        >*
            display: inline-block
        >.icon
            width: 15px
            margin-bottom: -1px
            margin-right: 5px
    >.show-details
        display: none
    &:hover
        >.show-details
            display: block
            position: absolute
            top: 36px
            right: 0
            width: auto
            padding: 0
            color: white
            height: 90px
            text-align: right
            background: transparent
            >.panel
                padding: 10px
                background: rgba(black, 0.8)
                display: inline-block
                max-width: 250px
                min-width: 250px
                text-align: left
module.exports = ({ store, value, on-change, placeholder, id, show-details, token="vlx2", disabled=no })->
    style = get-primary-info store
    usd = null
    eur = null
    ref=null
    input-style =
        background: style.app.input
        color: style.app.text
        overflow-x: \auto
    current=
        ref: null
    { wallets } = store.current.account
    wallet =
        wallets |> find (-> it.coin.token is token)
    if wallet?
        usd =
            | wallet.usd-rate? => (value || "0") `times` wallet.usd-rate
            | _ => ".."
        eur =
            | wallet.eur-rate? => (value || "0") `times` wallet.eur-rate
            | _ => ".."
    # Input validation #
    decimalsConfig = wallet.network.decimals
    decimals = value.toString!.split(".").1
    if decimals? and (decimals.length > decimalsConfig) then
        value = round-number(value, {decimals: decimalsConfig})
    max-amount = 1e10
    if +value > max-amount then
        value =  max-amount
    ####################
    actual-placeholder = placeholder ? ""        
    normalize = ->
        return \0 if not it?
        return parse-int it if it.index-of('.') is -1
        return parse-int(it) + "." if it.substr(it.length - 1, 1) is "."
        [first=\0, second=\0] = it.split('.')
        "#{parse-int first}.#{second}"
    get-number = (val)->
        number = (val ? "").toString!
        return \0 if number is ""
        val
    on-click = (it)->
        store.inputCaretPosition = it.target.selectionEnd
    on-change-internal = (it)->
        if (store.inputCaretPosition - it.target.selectionEnd) <= 1
            store.inputCaretPosition = it.target.selectionEnd
        value = it.target?value
        value = get-number(value)
        # Restrictions check #
        decimals = value.toString!.split(".").1
        if decimals? and (decimals.length > decimalsConfig) then
            value = round-number(value, {decimals: decimalsConfig})
        balance = +wallet.balance
        max-amount = Math.max 1e10, balance
        if +value > max-amount then
            value = max-amount
        # # # # # # # # # # #
        res = (value ? "0").toString().split(".")
        parsed-left = parseNum(res?0)
        has-dot = res.length > 1
        value = "0" if not value? or value is ""
        str_val = (value ? "0").toString()
        $value = 
            | it.target?value is "" => 0
            | value-without-decimal-with-dot(value) =>
                left = res.0
                parseNum(left) + "."
            | has-dot and parsed-left is parseNum(it.target?value) =>
                parsed-left + "." + (res?1 ? "" )    
            | has-dot and (str_val.length isnt (+str_val).toString().length) and (+value is +str_val) =>
                parseNum(res.0) + "." + (res?1 ? "" )          
            | _ => parseNum(value)
        value = $value
        console.log "parse #{it.target?value} to #{value}"
        it.target.selectionEnd = store.inputCaretPosition
        it.target.selectionStart = store.inputCaretPosition
        on-change { target: { value } }
    token = \vlx if token is \vlx2
    token-label = token.to-upper-case!
    value-without-decimal-with-dot = (value)->
        value = (value ? "0").toString()
        res = value.split(".")
        value.index-of('.') > -1 and (res.length > 1 and res[1] is "")
    format-my-number = (value)->
        number-isnt-normal = value-without-decimal-with-dot(value)
        str_val = (value ? "0").toString()
        res = str_val.split(".")
        has-dot = res.length > 1
        $value = 
            | value is "" => "0"
            | number-isnt-normal =>
                left = formatNum(res.0)
                left + "."
            | has-dot and res?1 and (+value is res.0) =>
                formatNum(res.0) + "." + res.1  
            # if number has zeroes in the decimals at the end  
            | has-dot and (str_val.length isnt (+str_val).toString().length) and (+value is +str_val) =>
                formatNum(res.0) + "." + res.1    
            | _ =>  formatNum(value)  
        $value  
    focus-input = (ref)!->
        ref.focus! if ref? 
    func = (r)->
        current.ref = r
    .pug.input-area
        input.pug( ref=func type="text" value="#{format-my-number(value)}" style=input-style on-click=on-click on-change=on-change-internal placeholder=actual-placeholder id="#{id}" disabled=disabled)
        span.suffix.pug(style=input-style)
            img.icon.pug(src="#{wallet.coin.image}")
            span.pug #{token-label}
        if show-details? and show-details then   
            .show-details.pug
                .panel.pug
                    .pug USD: #{round usd}