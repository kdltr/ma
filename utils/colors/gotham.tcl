# gotham
# https://github.com/wasamasa/gotham-theme

proc Gotham {} {
    global current_foreground current_background sbar_color
    global sbar_background tag_foreground tag_background 
    global selection_foreground
    global selection_background pseudo_selection_foreground
    global pseudo_selection_background inactive_selection_background

    set current_foreground "#99d1ce"
    set current_background "#0c1014"
    set sbar_color "#245361"
    set sbar_background "#091f2e"
    set tag_foreground "#599cab"
    set tag_background "#091f2e"
    set selection_foreground $current_foreground
    set selection_background "#0a3749"
    set pseudo_selection_foreground $selection_foreground
    set pseudo_selection_background $selection_background
    set inactive_selection_background $selection_background
    ConfigureWindow
}

DefineKey <F$theme_counter> {
    Gotham
    break
}

incr theme_counter