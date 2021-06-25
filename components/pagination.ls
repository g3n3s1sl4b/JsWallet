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
        position: relative
        text-align: center
        padding: 20px
        @media screen and (max-width: 540px)
            padding: 10px 0
            display: flex
            align-items: flex-start
        .current-page
            display: inline
            flex: 2
        button                      
            margin: 0 20px 0 !important
            min-width: 50px
            &:first-of-type
                @media screen and (max-width: 540px)
                    margin-left: 0 !important
                    flex: 1
            &:last-of-type
                @media screen and (max-width: 540px)
                    margin-right: 0 !important
                    flex: 1
        .per-page-selector
            position: absolute
            left: 0
            padding: 5px 10px
            border: 1px solid #555668
            cursor: pointer
            @media screen and (max-width: 540px)
                position: relative
                margin-right: 10px
                padding: 5px
            &:hover
                .per-page-options
                    display: block !important
            .per-page-options
                position: relative
                &.hidden
                    display: none
                .per-page-option
                    padding: 2px 5px
                    &:hover
                        background: #555668
module.exports = (props)->

    { setPage, setPerPage, array, page, type, perPage } = props

    [disabled, setDisabled] = react.useState(true)
    [openedSelector, setOpenedSelector] = react.useState(false)

    new-array = ^^array

    style = get-primary-info store
    page$ = page - 1
    new-array.slice page$ * perPage, (page$ + 1) * perPage
    allPages = Math.ceil(array.length `div` perPage)
    entities = new-array.length

    #Props
    prev-button-disabled = (+page <= 1)
    next-button-disabled = (allPages <= +page)
    $class = if not disabled then "visible" else "hidden"


    # Listeners
    go-back = ->
        $page =
            | page > 1 => page - 1
            | _ => 1
        setPage($page)

    go-forward = ->
        $page =
            | page < allPages => page + 1
            | _ => allPages
        setPage($page)

    normalize-current-page = (_perPage)->
        _allPages = Math.ceil(array.length `div` _perPage)
        $$page =
            | (+page > +_allPages) and +_allPages > 0 => _allPages
            | +_allPages < 1 => 1
            | _ => page
        return $$page

    setting-per-page = (_perPage, cb=null)!-->
        setPerPage(_perPage)
        new-page = normalize-current-page(_perPage)
        setPage(new-page)
        setDisabled(true)

    open-per-page-selector = ->
        setOpenedSelector(true)

    close-per-page-selector = ->
        setOpenedSelector(false)

    # Render
    .pug.table-pagination
        .pug.pagination-holder
            .pug.per-page-selector(key="selector" on-click=open-per-page-selector onMouseLeave=close-per-page-selector)
                .to-show.pug Show #{per-page}
                if openedSelector
                    .per-page-options.pug
                        .span.pug.per-page-option(on-click=setting-per-page(5)) 5
                        .span.pug.per-page-option(on-click=setting-per-page(10)) 10
                        .span.pug.per-page-option(on-click=setting-per-page(20)) 20
            if +entities > perPage
                .pug
                    button {store, classes: "width-auto", text: "<", no-icon:yes, on-click: go-back, style: {width: \auto, display: \block}, makeDisabled: prev-button-disabled}
                    .pug.current-page
                        span.pug Page
                            | #{page}
                            | /
                            | #{allPages}
                    button {store, classes: "width-auto", text: ">", no-icon:yes, on-click: go-forward, style: {width: \auto, display: \block}, makeDisabled: next-button-disabled}