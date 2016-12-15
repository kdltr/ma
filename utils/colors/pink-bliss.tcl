#
# a Port of the pink-bliss emacs color theme
#
# originally by Alex Schroeder
# http://www.emacswiki.org/emacs/PinkBliss
#

proc PinkBliss {} {
    global current_foreground current_background sbar_color
    global sbar_background tag_foreground tag_background 
    global selection_foreground
    global selection_background

    set current_foreground magenta4
    set current_background "misty rose"
    set sbar_color pink
    set sbar_background "hot pink"
    set tag_foreground "violet red"
    set tag_background pink
    set selection_foreground magenta4
    set selection_background seashell
    ConfigureWindow
}

DefineKey <F$theme_counter> {
    PinkBliss
    break
}

incr theme_counter
