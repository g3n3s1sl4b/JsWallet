require! {
    \react
    \../get-primary-info.ls
    \prelude-ls : { find }
    \../math.ls : { times }
    \./keyboard.ls
    \../numbers.js : {parseNum, formatNum}
    \../send-funcs.ls
    \../round-number.ls
}
module.exports = ({ store, value, on-change, placeholder, id, show-details, title, token="vlx2", disabled=no })->
    # Styles ##################
    style = get-primary-info store
    amount-style=
        background: style.app.input
        border: "1px solid #{style.app.border}"
        color: style.app.text
    just-crypto-background =
        background: style.app.wallet  
    ###########################
    # Input validation ########
    decimalsConfig = 4
    decimals = value.toString!.split(".").1
    if decimals? and (decimals.length > decimalsConfig) then
        value = round-number(value, {decimals: 4})
    max-amount = 1e12
    if +value > max-amount then
        value =  max-amount
    ###########################
    # Listeners
    get-number = (value)->
        number = (value ? "").toString!
        return \0 if number is ""
        value
    value-without-decimal-with-dot = (value)->
        value = (value ? "").toString()
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
    on-change-internal = (it)->
        console.log "fiat on-change"
        value = it.target?value
        value = get-number(value)
        # Restrictions check #
        if decimals? and (decimals.length > decimalsConfig) then
            console.log "more than 4 decimals"
            value = it.target.value = round-number(value, {decimals: 4})
        max-amount = 1e12
        if +value > max-amount then
            value = it.target.value = max-amount
        ######################
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
        #it.target.selectionEnd = store.inputCaretPosition
        #it.target.selectionStart = store.inputCaretPosition
        on-change { target: { value } }
    .input-wrapper.small.pug(style=amount-style)
        .label.lusd.pug $
        input.pug.amount-usd(type='text' style=just-crypto-background on-change=on-change-internal placeholder=placeholder title=title value="#{format-my-number(value)}" id="send-amount-usd" disabled=disabled)