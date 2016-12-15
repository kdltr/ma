# goldenrod

proc Goldenrod {} {
    global current_foreground current_background sbar_color
    global sbar_background tag_foreground tag_background 
    global selection_foreground
    global selection_background pseudo_selection_foreground
    global pseudo_selection_background inactive_selection_background

    set current_foreground "goldenrod"
    set current_background "black"
    set sbar_color "DarkSlateGray"
    set sbar_background gray10
    set tag_foreground "lemon chiffon"
    set tag_background gray25
    set selection_foreground "DarkGoldenrod"
    set selection_background "dark olive green"
    set pseudo_selection_foreground $selection_foreground
    set pseudo_selection_background $selection_background
    set inactive_selection_background $selection_background
    ConfigureWindow
}

DefineKey <F$theme_counter> {
    Goldenrod
    break
}

incr theme_counter