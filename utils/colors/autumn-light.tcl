#
# autumn light
# https://github.com/aalpern/emacs-color-theme-autumn-light/blob/master/autumn-light-theme.el
#

proc AutumnLight {} {
    global current_foreground current_background sbar_color
    global sbar_background tag_foreground tag_background 
    global selection_foreground
    global selection_background

    set current_foreground black
    set current_background wheat
    set sbar_color white
    set sbar_background grey
    set tag_foreground white
    set tag_background firebrick
    set selection_foreground gray90
    set selection_background DarkSlateBlue
    ConfigureWindow
}

DefineKey <F$theme_counter> {
    AutumnLight
    break
}

incr theme_counter
