require! {
    \react
    \../get-primary-info.ls
    \../round5.ls
    \../round.ls
    \prelude-ls : { find }
    \../math.ls : { times }
    \./keyboard.ls
    \../numbers.js : {parseNum, formatNum}
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
    input-style =
        background: style.app.input
        color: style.app.text
        overflow-x: \auto
    current=
        ref: null
    { wallets } = store.current.account
    wallet =
        wallets |> find (-> it.coin.token is token)
    value-token = value ? 0
    usd =
        | wallet.usd-rate? => (value-token || "0") `times` wallet.usd-rate
        | _ => ".."
    eur =
        | wallet.eur-rate? => (value-token || "0") `times` wallet.eur-rate
        | _ => ".."
    actual-placeholder = placeholder ? ""
    normalize = ->
        return \0 if not it?
        return parse-int it if it.index-of('.') is -1
        return parse-int(it) + "." if it.substr(it.length - 1, 1) is "."
        [first=\0, second=\0] = it.split('.')
        "#{parse-int first}.#{second}"
    get-number = (value)->
        number = (value ? "").toString!
        return \0 if number is ""
        #value = number.replace(/,/gi, '.')
        #value = value.match(/^[0-9]+([.]([0-9]+)?)?$/)?0
        #value2 =
            #| value?0 is \0 and value?1? and value?1 isnt \. => value.substr(1, value.length)
            #| _ => value
        value
    on-change-internal = (it)->
        value = get-number it.target?value
        if not value-without-decimal-with-dot(value)
            value = parseNum(value)
        value = value.toString!
        value = value
        on-change { target: { value } }
    token = \vlx if token is \vlx2
    token-label = token.to-upper-case!
    value-without-decimal-with-dot = (value)->
        value = (value ? "").toString()
        res = value.split(".")
        value.index-of('.') > -1 and (res.length > 1 and res[1] is "")
    format-my-number = (value)->
        value = value
        number-isnt-normal = value-without-decimal-with-dot(value)
        value = 
            | number-isnt-normal =>
                res = (value ? "").split(".")
                left = formatNum(res.0)
                value = left + "."    
            | _ =>  value = formatNum(value)  
        value   
    .pug.input-area
        input.pug(type="text" value="#{format-my-number(value-token)}" style=input-style on-change=on-change-internal placeholder=actual-placeholder id="#{id}" disabled=disabled)
        span.suffix.pug(style=input-style)
            img.icon.pug(src="#{wallet.coin.image}")
            span.pug #{token-label}
        if show-details? and show-details then   
            .show-details.pug
                .panel.pug
                    .pug USD: #{round usd}