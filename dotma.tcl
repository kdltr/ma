set current_fixed_font "Terminus"
set current_variable_font "Terminus"
#set current_font $current_variable_font
set current_font_size 10
set fixed_font_size 10
set variable_font_size 10
set tag_font_size 10

## File hooks

source /my/library/code/ma/utils/hooks.tcl

proc SchemeFileHook {} {
    uplevel #0 { source /my/library/code/ma/utils/scheme-indent.tcl }
    SchemeIndent
    ToggleFont fix
}
AddFileHook {\.(sc.?|meta)$} SchemeFileHook
AddFileHook {\.(setup|egg)$} {SchemeFileHook; .tag insert "1.0 lineend" " chicken-install"}

## Color schemes

set theme_counter 1
foreach x "acme autumn-light blue-sea crisp electric faff
                   glowfish goldenrod relaxed solarized subatomic zenburn" {
    source /my/library/code/ma/utils/colors/$x.tcl
}

source /my/library/code/ma/utils/gopher.tcl
