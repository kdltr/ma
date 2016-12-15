# monochrome theme

proc Mono {} {
    global current_foreground current_background sbar_color
    global sbar_background tag_foreground tag_background 
    global selection_foreground
    global selection_background pseudo_selection_foreground
    global pseudo_selection_background inactive_selection_background

    set current_foreground black
    set current_background white
    set sbar_color white
    set sbar_background "#a0a0a0"
    set tag_foreground white
    set tag_background black
    set selection_foreground black
    set selection_background "#a0a0a0"
    set pseudo_selection_foreground $selection_foreground
    set pseudo_selection_background $selection_background
    set inactive_selection_background $selection_background
    ConfigureWindow
}

DefineKey <F$theme_counter> {
    Mono
    break
}

incr theme_counter