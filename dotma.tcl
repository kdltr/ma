set current_fixed_font "Source Code Pro"
set current_variable_font "Source Code Pro"
#set current_font $current_variable_font

set browser "x-www-browser"
set image_viewer "sxiv"
set pdf_viewer "mupdf"


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


## Plumbing rules

source /my/library/code/ma/utils/gopher.tcl

DefinePlumbing {^(.+)(.png|.jpg|.jpeg|.gif)} {
    set fname [CanonicalFilename [GetArg 0]]
    if {[file exists $fname]} {
       global image_viewer
       exec $image_viewer $fname
       return 1
    }
    return 0
}

DefinePlumbing {^(.+).pdf} {
    set fname [CanonicalFilename [GetArg 0]]
    if {[file exists $fname]} {
        global pdf_viewer
        exec $pdf_viewer $fname
        return 1
    }
    return 0
}
