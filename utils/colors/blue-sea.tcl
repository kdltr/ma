# color-theme based on BlueSea (or something like that, from emacs)
#

proc BlueSea {} {
    global current_foreground current_background sbar_color
    global tag_foreground tag_background 
    global selection_foreground
    global selection_background sbar_background
    global pseudo_selection_foreground
    global pseudo_selection_background inactive_selection_background

    set current_foreground white
    set current_background "#102e4e"
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
    BlueSea
    break
}

incr theme_counter
