# zenburn
# https://github.com/bbatsov/zenburn-emacs/blob/master/zenburn-theme.el

proc Zenburn {} {
    global current_foreground current_background sbar_color
    global sbar_background tag_foreground tag_background 
    global selection_foreground
    global selection_background pseudo_selection_foreground
    global pseudo_selection_background inactive_selection_background

    set current_foreground "#dcdccc"
    set current_background "#2b2b2b"
    set sbar_color "#383838"
    set sbar_background black
    set tag_foreground "#8fb28f"
    set tag_background black
    set selection_foreground "#2b2b2b"
    set selection_background "#8cd0d3"
    set pseudo_selection_foreground $selection_foreground
    set pseudo_selection_background $selection_background
    set inactive_selection_background $selection_background
    ConfigureWindow
}

DefineKey <F$theme_counter> {
    Zenburn
    break
}

incr theme_counter