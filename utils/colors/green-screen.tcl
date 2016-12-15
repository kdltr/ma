# Green Screen
# https://github.com/mkaito/base16-emacs


proc GreenScreen {} {
    global current_foreground current_background sbar_color
    global sbar_background tag_foreground tag_background 
    global selection_foreground
    global selection_background pseudo_selection_foreground
    global pseudo_selection_background inactive_selection_background

    set current_foreground "#00dd00"
    set current_background "#001100"
    set sbar_color "#004400"
    set sbar_background "#002200"
    set tag_foreground "#00bb00"
    set tag_background "#003300"
    set selection_foreground "#00bb00"
    set selection_background "#005500"
    set pseudo_selection_foreground "#00bb00"
    set pseudo_selection_background "#005500"
    set inactive_selection_background "#005500"
    ConfigureWindow
}

DefineKey <F$theme_counter> {
    GreenScreen
    break
}

incr theme_counter
