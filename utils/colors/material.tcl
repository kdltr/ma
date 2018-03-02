# "material" color scheme
#
# https://github.com/cpaulik/emacs-material-theme/


proc Material {} {
    global current_foreground current_background sbar_color
    global sbar_background tag_foreground tag_background 
    global selection_foreground
    global selection_background pseudo_selection_foreground
    global pseudo_selection_background inactive_selection_background

    set current_foreground "#ffffff"
    set current_background "#263238"
    set sbar_color gray50
    set sbar_background $current_background
    set tag_foreground $current_foreground
    set tag_background "#1c1f26"
    set selection_foreground $current_foreground
    set selection_background "#555555"
    set pseudo_selection_foreground $selection_foreground
    set pseudo_selection_background $selection_background
    set inactive_selection_background $selection_background
    ConfigureWindow
}

DefineKey <F$theme_counter> {
    Material
    break
}

incr theme_counter
