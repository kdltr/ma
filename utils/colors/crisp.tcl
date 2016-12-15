# Crisp (https://github.com/daylerees/colour-schemes)

proc Crisp {} {
    global current_foreground current_background sbar_color
    global sbar_background tag_foreground tag_background 
    global selection_foreground
    global selection_background pseudo_selection_foreground
    global pseudo_selection_background inactive_selection_background

    set current_foreground "#ffffff"
    set current_background "#221a22"
    set sbar_color "#776377"
    set sbar_background $current_background
    set tag_foreground "white"
    set tag_background gray25
    set selection_foreground "#ffffff"
    set selection_background "#FC6A0F"
    set pseudo_selection_foreground $selection_foreground
    set pseudo_selection_background $selection_background
    set inactive_selection_background $selection_background
    ConfigureWindow
}

DefineKey <F$theme_counter> {
    Crisp
    break
}

incr theme_counter