require! {
    \react-chartjs-2 : { Line }
    \react
    \prelude-ls : { map, reverse, take }
    \../../round-number.ls
    \../../math.ls : { div, times, plus, minus }
}
.rewards-linear-graph
    margin-top: 50px
    .rewards-stats-container     
        padding: 0 10%
get-color = (items)-> (it)->
    index = items.index-of(it)
    base = 
        | it.status is \active => 3986863 + ( index * 2 )
        | it.status is \inactive => 3872625
        | it.status is \banned => 16730920
        | _ => 3872625
    h = base.to-string 16
    '#' + h
build-data = (items)->
    data = items 
        |> map (it)->
            it.amount `div` (10^9)
    datasets: [{
        data
        backgroundColor: 'rgba(75,192,192,0.4)'
        borderColor: 'rgba(75,192,192,1)'
        lineTension: 0
        grid:
            borderColor: 'rgb(255 255 255 / 42%)'
    }]
    labels: items |> map (.epoch)
legend =
    display: false
module.exports = ({store, web3t})->
    return null if not store.staking.chosenAccount?
    return null if store.staking.chosenAccount.rewards.length < 2
    rewards = store.staking.chosenAccount.rewards |> take 10 |> reverse
    data = build-data rewards
    options = {
        scales: {
            xAxisID: {
                grid: {
                    borderColor: "red"
                    color: "red"
                    drawBorder: true
                }
            }
            yAxisID: {
                gridLines: {
                    drawBorder: true
                    color: 'rgb(255 255 255 / 42%)'
                    zeroLineColor: 'rgb(255 255 255 / 42%)'
                }
            }
        }
    }
    .pug.rewards-linear-graph
        .pug.rewards-stats-container
            Line.pug(data=data options=options width="300px" height=100 legend=legend)