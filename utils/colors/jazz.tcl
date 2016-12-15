# jazz
# https://github.com/donderom/jazz-theme/blob/master/jazz-theme.el


proc Jazz {} {
    global current_foreground current_background sbar_color
    global sbar_background tag_foreground tag_background 
    global selection_foreground
    global selection_background pseudo_selection_foreground
    global pseudo_selection_background inactive_selection_background

    set current_foreground "#c6a57b"
    set current_background "#151515"
    set sbar_color $current_background
    set sbar_background "#303030"
    set tag_foreground $current_foreground
    set tag_background "#202020"
    set selection_foreground "#385e6b"
    set selection_background $current_foreground
    set pseudo_selection_foreground $selection_foreground
    set pseudo_selection_background $selection_background
    set inactive_selection_background $selection_background
    ConfigureWindow
}

DefineKey <F$theme_counter> {
    Jazz
    break
}

incr theme_counter