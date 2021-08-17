require! {
    \./velas/addresses.ls
    \prelude-ls : { map, filter, obj-to-pairs }
    \./round-human.ls
    \./round-number.ls
}
module.exports = (store, web3t)->
    { send } = store.current
    decimalsConfig = send.network.decimals
    is-data = (send.data ? "").length > 0
    network = store.current.network
    contract =
        addresses[network]
            |> obj-to-pairs
            |> filter -> it.1 is send.to
            |> map -> it.0
            |> -> it ? send.to
    wallet = store.current.send.wallet
    swap = store.current.send.swap
    token-display = (wallet.coin.nickname ? send.coin.token).to-upper-case!
    amount-send = round-human send.amount-send, {decimals: decimalsConfig}
    funtype =
        if +send.amount-send > 0 then "Send #{amount-send} #{token-display} to #{contract} contract" else "Execute the #{contract} contract"
    text-parts-contract =
        * funtype
        * "You are allowed to spend your resources on execution #{round-number send.amount-send-fee, {decimals: decimalsConfig}} #{token-display}."
    text-parts-regular =
        * "Send #{amount-send} #{token-display} to #{send.to}"
        * "You are allowed to spend your resources on execution #{round-number send.amount-send-fee, {decimals: decimalsConfig}} #{token-display}."
    text-parts-swap =
        * "Swap #{amount-send} #{token-display} to #{send.to}"
        * "You are allowed to spend your resources on execution #{round-number send.amount-send-fee, {decimals: decimalsConfig}} #{token-display}."
    
    text =
        | is-data => text-parts-contract
        | swap is yes => text-parts-swap 
        | _ => text-parts-regular
    text