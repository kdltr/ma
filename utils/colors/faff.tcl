# emacs "faff" theme
# https://github.com/WJCFerguson/emacs-faff-theme/blob/master/faff-theme.el


proc Faff {} { 
    global current_foreground current_background sbar_color
    global sbar_background tag_foreground tag_background 
    global selection_foreground
    global selection_background pseudo_selection_foreground
    global pseudo_selection_background inactive_selection_background

    set current_foreground black
    set current_background ivory3
    set tag_foreground black
    set tag_background gold
    set selection_foreground white
    set selection_background DarkOrange
    set sbar_color white
    set sbar_background lightsteelblue
    set pseudo_selection_foreground $selection_foreground
    set pseudo_selection_background $selection_background
    set inactive_selection_background $selection_background
    ConfigureWindow
}

DefineKey <F$theme_counter> {
    Faff
    break
}

incr theme_counter
