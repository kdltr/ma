# paper
# https://github.com/cadadr/paper-theme/blob/master/paper-theme.el

proc Paper {} {
    global current_foreground current_background sbar_color
    global sbar_background tag_foreground tag_background 
    global selection_foreground
    global selection_background pseudo_selection_foreground
    global pseudo_selection_background inactive_selection_background

    set current_foreground "#070a01"
    set current_background "#fafafa"
    set sbar_color white
    set sbar_background $current_background
    set tag_foreground "#eeeeee"
    set tag_background "#8c0d40"
    set selection_foreground $tag_background
    set selection_background "#eeeeee"
    set pseudo_selection_foreground $selection_foreground
    set pseudo_selection_background $selection_background
    set inactive_selection_background $selection_background
    ConfigureWindow
}

DefineKey <F$theme_counter> {
    Paper
    break
}

incr theme_counter