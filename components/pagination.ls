require! {
    \react
    \./middle-ellipsis : MiddleEllipsis
    \../get-primary-info.ls
    \../icons.ls
    \./identicon.ls
    \./button.ls
    \../math.ls : { div, times, plus, minus }
}
.table-pagination
    @import scheme
    .pagination-holder
        text-align: center
        padding: 20px
        @media screen and (max-width: 540px)
            padding: 10px 0
        button                      
            margin: 0 20px 0 !important
module.exports = ({ store, type, config })->
    { array, perPage } = config
    new-array = ^^array
    page = store.staking["current_#{type}_page"] ? 1
    allPages = Math.ceil(array.length `div` perPage)
    style = get-primary-info store
    page$ = page - 1
    new-array.slice page$ * per-page, (page$ + 1) * per-page
    entities = new-array.length
    #Props
    prev-button-disabled = +page <= 1
    next-button-disabled = allPages <= +page
    # Listeners
    go-back = ->
        store.staking["current_#{type}_page"] = 
            | page > 1 => page - 1
            | _ => 1
    go-forward = ->
        page = store.staking["current_#{type}_page"]
        store.staking["current_#{type}_page"] = 
            | page < allPages => page + 1
            | _ => allPages
    # Render
    .pug.table-pagination
        .pug.pagination-holder
            button {store, classes: "width-auto", text: "<", no-icon:yes, on-click: go-back, style: {width: \auto, display: \block}, makeDisabled: prev-button-disabled}
            span.pug.curren-page 
                span.pug Page 
                    | #{page} 
                    | / 
                    | #{allPages}
            button {store, classes: "width-auto", text: ">", no-icon:yes, on-click: go-forward, style: {width: \auto, display: \block}, makeDisabled: next-button-disabled}