# organic-green
# https://emacsthemes.com/themes/organic-green-theme.html

proc OrganicGreen {} {
    global current_foreground current_background sbar_color
    global sbar_background tag_foreground tag_background 
    global selection_foreground
    global selection_background pseudo_selection_foreground
    global pseudo_selection_background inactive_selection_background

    set current_foreground "#326B6B"
    set current_background "#F0FFF0"
    set sbar_color $current_background
    set sbar_background $current_foreground
    set tag_foreground "#2e3436"
    set tag_background "#d3d7cf"
    set selection_foreground $current_foreground
    set selection_background "#EEEEA0"
    set pseudo_selection_foreground $selection_foreground
    set pseudo_selection_background $selection_background
    set inactive_selection_background $selection_background
    ConfigureWindow
}

DefineKey <F$theme_counter> {
    OrganicGreen
    break
}

incr theme_counter