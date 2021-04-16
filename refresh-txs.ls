require! {
    \./calc-wallet.ls
    \./transactions.ls : { load-all-transactions }
    \./load-rates.ls
    \./workflow.ls : { run, task }
}
refresh-txs = (web3, store, cb)->
    store.current.transactions-are-loading = yes
    task1 = task (cb)->
        load-all-transactions store, web3, cb
    <- run [ task1 ] .then
    store.current.transactions-are-loading = no
module.exports = refresh-txs