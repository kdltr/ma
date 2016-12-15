#
# slightly more relaxed colors
#

proc Relaxed {} {
    global current_foreground current_background sbar_color
    global sbar_background tag_foreground tag_background 
    global selection_foreground
    global selection_background pseudo_selection_foreground
    global pseudo_selection_background inactive_selection_background

    set current_foreground "#b6b6b6"
    set current_background "#222222"
    set sbar_color "#333333"
    set sbar_background black
    set tag_foreground white
    set tag_background black
    set selection_foreground black
    set selection_background yellow
    set pseudo_selection_foreground $selection_foreground
    set pseudo_selection_background $selection_background
    set inactive_selection_background $selection_background
    ConfigureWindow
}

DefineKey <F$theme_counter> {
    Relaxed
    break
}

incr theme_counter
