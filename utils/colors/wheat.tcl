# wheat
# https://emacsthemes.com/themes/wheat-theme.html

proc Wheat {} {
    global current_foreground current_background sbar_color
    global sbar_background tag_foreground tag_background 
    global selection_foreground
    global selection_background pseudo_selection_foreground
    global pseudo_selection_background inactive_selection_background

    set current_foreground "black"
    set current_background "wheat"
    set sbar_color $current_background
    set sbar_background $current_foreground
    set tag_foreground "white"
    set tag_background "black"
    set selection_foreground $current_foreground
    set selection_background "gray"
    set pseudo_selection_foreground $selection_foreground
    set pseudo_selection_background $selection_background
    set inactive_selection_background $selection_background
    ConfigureWindow
}

DefineKey <F$theme_counter> {
    Wheat
    break
}

incr theme_counter