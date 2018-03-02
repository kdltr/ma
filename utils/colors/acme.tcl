#
# acme color theme - same as the default colors
#

proc Acme {} {
    global current_foreground current_background sbar_color
    global sbar_background tag_foreground tag_background 
    global selection_foreground
    global selection_background pseudo_selection_foreground
    global pseudo_selection_background inactive_selection_background

    set current_foreground black
    set current_background "#FFFFEA"
    set sbar_color $current_background
    set sbar_background "#99994C"
    set tag_foreground black
    set tag_background "#EAFFFF"
    set selection_foreground black
    set selection_background "#eeee9e"
    set pseudo_selection_foreground $selection_foreground
    set pseudo_selection_background $selection_background
    set inactive_selection_background $selection_background
    ConfigureWindow
}

DefineKey <F$theme_counter> {
    Acme
    break
}

incr theme_counter
