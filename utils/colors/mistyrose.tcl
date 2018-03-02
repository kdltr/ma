# mistyrose
# https://emacsthemes.com/themes/mistyrose-theme.html

proc Mistyrose {} {
    global current_foreground current_background sbar_color
    global sbar_background tag_foreground tag_background 
    global selection_foreground
    global selection_background pseudo_selection_foreground
    global pseudo_selection_background inactive_selection_background

    set current_foreground "black"
    set current_background "mistyrose"
    set sbar_color $current_background
    set sbar_background $current_foreground
    set tag_foreground "lawn green"
    set tag_background "royalblue4"
    set selection_foreground "light cyan"
    set selection_background "sienna"
    set pseudo_selection_foreground $selection_foreground
    set pseudo_selection_background $selection_background
    set inactive_selection_background $selection_background
    ConfigureWindow
}

DefineKey <F$theme_counter> {
    Mistyrose
    break
}

incr theme_counter