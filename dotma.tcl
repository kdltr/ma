set fixed_font { "Roboto Mono Medium" 9 normal }
set variable_font { "Roboto Medium" 10 normal }
set current_font $variable_font
set tag_font $variable_font
set tag_clean_font $tag_font
set tag_dirty_font { "Roboto Medium" 10 italic }
set rc_style_quoting 1

## File hooks

source /my/library/code/ma/utils/hooks.tcl

proc SchemeFileHook {} {
    uplevel #0 { source /my/library/code/ma/utils/scheme-indent.tcl }
    SchemeIndent
    ToggleFont fix
}
AddFileHook {\.(sc.?|meta|k|l)$} SchemeFileHook
AddFileHook {\.(setup|egg)$} {SchemeFileHook}

## Color schemes

set theme_counter 1
foreach x "acme autumn-light blue-sea crisp electric faff
                   glowfish goldenrod relaxed solarized subatomic zenburn" {
    source /my/library/code/ma/utils/colors/$x.tcl
}

source /my/library/code/ma/utils/gopher.tcl
