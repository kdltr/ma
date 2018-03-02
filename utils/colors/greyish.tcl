#
# found somewhere...
#

proc Greyish {} {
    global current_foreground current_background sbar_color
    global sbar_background tag_foreground tag_background 
    global selection_foreground
    global selection_background pseudo_selection_foreground
    global pseudo_selection_background inactive_selection_background

    set current_foreground "black"
    set current_background "#fdf6e3"
    set tag_foreground "#546f76"
    set tag_background "#d0d0d0"
    set sbar_color $current_background
    set sbar_background $tag_background
    set selection_foreground $tag_background
    set selection_background "#5f87af"
    set pseudo_selection_foreground $selection_foreground
    set pseudo_selection_background $selection_background
    set inactive_selection_background $selection_background
    ConfigureWindow
}

DefineKey <F$theme_counter> {
    Greyish
    break
}

incr theme_counter
