require! {
    \prelude-ls : { map, split, filter, find, foldl, drop, take, sum, unique }
    \./math.ls : { div, times, plus, minus }
}
SIMULATION_COUNT = 14600
EPOCHS_PER_YEAR = 1460
VALIDATOR_COUNT = 19
as-callback = (p, cb)->
    p.catch (err) -> cb err
    p.then (data)->
        cb null, data
fill-pools = ({ store, web3t, on-progress, on-finish }, [item, ...rest]) ->
    if not item? then
        store.staking.all-pools-loaded = yes
        store.staking.pools-are-loading = no
        return on-finish null, []
    if (([\validators, \info].index-of(store.current.page)) is -1) then
        store.staking.all-pools-loaded = no
        store.staking.pools-are-loading = no
        return on-finish null, []
    ###############
    ###############
    item.address = item.key
    item.stake = item.stake
    item.stake-initial = item.activatedStake
    item.status = "Not delegated"
    item.status = status
    item.delegators = store.staking.delegators[item.votePubkey] ? 0
    item.stakes = [] 
    on-progress [item, ...rest] if on-progress?
    on-finish-local = (err, pools) ->
        on-finish err, [item, ...pools]
    on-progress-local = (pools) ->
        on-progress [item, ...pools]
    fill-pools { store, web3t, on-progress: on-progress-local, on-finish: on-finish-local }, rest
query-pools-web3t = (store, web3t, on-progress, on-finish) ->       
    console.log "[query-pools-web3t]" 
    err, validators <- as-callback web3t.velas.NativeStaking.getStakingValidators()
    return on-finish err if err?
    console.log "Got validators" validators
    store.staking.pools-are-loading = yes
    fill-pools { store, web3t, on-progress, on-finish }, validators
query-pools = (store, web3t, on-progress, on-finish) ->
    err <- fill-delegators store, web3t      
    err, pools <- query-pools-web3t store, web3t, on-progress
    return on-finish err if err?
    on-finish err, pools
fill-delegators = (store, web3t, cb)->
    console.log "[fill-delegators]"
    accounts = store.staking.parsedProgramAccounts
    fill-delegator(store, web3t, accounts, cb)
fill-delegator = (store, web3t, [acc, ...accounts], cb)!->
    return cb null if not acc?
    voter             =        acc.account?data?parsed?info?stake?delegation?voter
    activationEpoch   = Number(acc.account?data?parsed?info?stake?delegation?activationEpoch  ? 0)
    deactivationEpoch = Number(acc.account?data?parsed?info?stake?delegation?deactivationEpoch ? 0)
    if (voter and (deactivationEpoch > activationEpoch or activationEpoch is web3t.velas.NativeStaking.max_epoch))  
        store.staking.delegators[voter] = if store.staking.delegators[voter]? then (store.staking.delegators[voter] + 1) else 1
    fill-delegator(store, web3t, accounts, cb)
# Accounts
query-accounts = (store, web3t, on-progress, on-finish) ->
    err, accounts <- query-accounts-web3t store, web3t, on-progress
    return on-finish err if err?
    on-finish err, accounts
query-accounts-web3t = (store, web3t, on-progress, on-finish) ->
    parsedProgramAccounts = store.staking.parsedProgramAccounts
    err, accs <- as-callback web3t.velas.NativeStaking.getOwnStakingAccounts(parsedProgramAccounts) 
    accs = [] if err?  
    console.log "accs" accs 
    return on-finish err if err?
    store.staking.pools-are-loading = yes
    fill-accounts { store, web3t, on-progress, on-finish }, accs
fill-accounts = ({ store, web3t, on-progress, on-finish }, [item, ...rest]) ->
    console.log "[fill-accounts]" item
    if not item? then
        store.staking.all-pools-loaded = yes
        store.staking.pools-are-loading = no
        return on-finish null, []
    if (([\validators, \info].index-of(store.current.page)) is -1) then
        store.staking.all-pools-loaded = no
        store.staking.pools-are-loading = no
        return on-finish null, []
    rent = item.account?data?parsed?info?meta?rentExemptReserve
    err, seed <- as-callback web3t.velas.NativeStaking.checkSeed(item.pubkey.toBase58())
    item.seed    = seed ? ".."
    item.address = item.pubkey.toBase58()
    item.key     = item.address
    item.rentRaw = rent
    item.balanceRaw = if rent? then (item.account.lamports `minus` rent) else '-'
    item.balance = if rent? then (Math.round((item.account.lamports `minus` rent) `div` (10^9)) `times` 100) `div` 100  else "-"
    item.rent    = if rent? then  Math.round((rent `div` (10^9)) `times` 100) `div` 100 else "-"
    item.status  = "Not delegated"
    item.validator = "-"
    if (item.account?data?parsed?info?stake) then
        activationEpoch   = Number(item.account?data?parsed?info?stake.delegation.activationEpoch)
        deactivationEpoch = Number(item.account?data?parsed?info?stake.delegation.deactivationEpoch)
        if (deactivationEpoch > activationEpoch or activationEpoch is web3t.velas.NativeStaking.max_epoch) then
            item.status    = "loading"
            item.validator = item.account?data?parsed?info?stake?delegation?voter
    on-progress [item, ...rest] if on-progress?
    on-finish-local = (err, pools) ->
        on-finish err, [item, ...pools]
    on-progress-local = (pools) ->
        on-progress [item, ...pools]
    fill-accounts { store, web3t, on-progress: on-progress-local, on-finish: on-finish-local }, rest
###################    
convert-accounts-to-view-model = (accounts) ->
    console.log "[convert accounts]" accounts
    accounts
        |> map -> {
            address: it.key ? '..'
            key: it.key
            balance: if it.balance? then it.balance else '..'
            rent: if it.rent? then Math.round((it.rent `div` (10^9)) `times` 100) `div` 100 else "-"
            lastVote: it.lastVote ? '..'
            seed: it.seed ? '..'
            validator:  it.validator ? "-",
            status: it.status ? "Not delegated",
        }
##################
convert-pools-to-view-model = (pools) ->
    console.log "[convert pools]" pools
    pools
        |> map -> {
            address: it.key ? '..',
            checked: no,
            stake: if it.stake? then it.stake else '..',
            stake-initial: if it.activatedStake? then parse-float it.activatedStake `div` (10^9) else 0,
            lastVote: it.lastVote ? '..'
            #node-stake: if it.node-stake? then round-human(parse-float it.node-stake `div` (10^18)) else '..',
            #delegate-stake: if it.node-stake? then round-human(parse-float (it.stake - it.node-stake) `div` (10^18)) else '..',
            stakers: if it.delegators? then it.delegators else '..',
            eth: no,
            is-validator:  (it?stakes? and it.stakes.length isnt 0) ? false,
            status: "active",
            my-stake: if it?stakes? then (it.stakes |> foldl plus, 0) else 0
            withdraw-amount: \0,
            validator-probability: '..'
            #delegate-roi: if it.delegate-reward? then (it.delegate-reward && round-human(it.delegate-reward / (it.stake - it.node-stake) * 100)) + \% else '..',
            #node-roi: if it.node-reward? then (it.node-reward && round-human(it.node-reward / it.node-stake * 100)) + \% else '..'
        }
module.exports = { query-pools, query-accounts, convert-accounts-to-view-model, convert-pools-to-view-model }