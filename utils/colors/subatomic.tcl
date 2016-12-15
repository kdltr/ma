# subatomic
# https://emacsthemes.com/themes/subatomic-theme.html

proc Subatomic {} {
    global current_foreground current_background sbar_color
    global sbar_background tag_foreground tag_background 
    global selection_foreground
    global selection_background pseudo_selection_foreground
    global pseudo_selection_background inactive_selection_background

    set current_foreground "#e5e5e5"
    set current_background "#303347"
    set sbar_color gray50
    set sbar_background "#303347"
    set tag_foreground white
    set tag_background "#232533"
    set selection_foreground white
    set selection_background "#696e92"
    set pseudo_selection_foreground $selection_foreground
    set pseudo_selection_background $selection_background
    set inactive_selection_background $selection_background
    ConfigureWindow
}

DefineKey <F$theme_counter> {
    Subatomic
    break
}

incr theme_counter