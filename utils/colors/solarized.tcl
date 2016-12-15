# "solarized" color scheme
#
# http://ethanschoonover.com/solarized


set solarized(base03) "#002b36"
set solarized(base02) "#073642"
set solarized(base01) "#586e75"
set solarized(base00) "#657b83"
set solarized(base0) "#839496"
set solarized(base1) "#93a1a1"
set solarized(base2) "#eee8d5"
set solarized(base3) "#fdf6e3"
set solarized(yellow) "#b58900"
set solarized(orange) "#cb4b16"
set solarized(red) "#dc322f"
set solarized(magenta) "#d33682"
set solarized(violet) "#6c71c4"
set solarized(blue) "#268bd2"
set solarized(cyan) "#2aa198"
set solarized(green) "#859900"


proc SolarizedLight {} {
    global current_foreground current_background sbar_color
    global sbar_background tag_foreground tag_background 
    global selection_foreground
    global solarized
    global selection_background pseudo_selection_foreground
    global pseudo_selection_background inactive_selection_background

    set current_foreground $solarized(base00)
    set current_background $solarized(base2)
    set sbar_color $solarized(base00)
    set sbar_background $solarized(base1)
    set tag_foreground $solarized(base2)
    set tag_background $solarized(base03)
    set selection_foreground black
    set selection_background yellow
    set pseudo_selection_foreground $selection_foreground
    set pseudo_selection_background $selection_background
    set inactive_selection_background $selection_background
    ConfigureWindow
}

proc SolarizedDark {} {
    global current_foreground current_background sbar_color
    global sbar_background tag_foreground tag_background 
    global tag_background_dirty selection_foreground
    global solarized
    global selection_background pseudo_selection_foreground
    global pseudo_selection_background inactive_selection_background

    set current_foreground $solarized(base1)
    set current_background $solarized(base03)
    set sbar_color $solarized(base02)
    set sbar_background $solarized(base01)
    set tag_foreground $solarized(base2)
    set tag_background $solarized(base02)
    set tag_background_dirty $solarized(base01)
    set selection_foreground black
    set selection_background yellow
    set pseudo_selection_foreground $selection_foreground
    set pseudo_selection_background $selection_background
    set inactive_selection_background $selection_background
    ConfigureWindow
}

# SolarizedLight is not used

DefineKey <F$theme_counter> {
    SolarizedDark
    break
}

incr theme_counter
