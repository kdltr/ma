# glowfish (https://github.com/daylerees/colour-schemes)

proc Glowfish {} {
    global current_foreground current_background sbar_color
    global sbar_background tag_foreground tag_background 
    global selection_foreground
    global selection_background pseudo_selection_foreground
    global pseudo_selection_background inactive_selection_background

    set current_foreground "#6ea240"
    set current_background "#191f13"
    set sbar_color "#67854f"
    set sbar_background "#191f13"
    set tag_foreground "white"
    set tag_background $current_background
    set selection_foreground "#ffffff"
    set selection_background "#DB784D"
    set pseudo_selection_foreground $selection_foreground
    set pseudo_selection_background $selection_background
    set inactive_selection_background $selection_background
    ConfigureWindow
}

DefineKey <F$theme_counter> {
    Glowfish
    break
}

incr theme_counter