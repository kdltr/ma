set current_fixed_font "Liberation Mono"
set current_variable_font "Liberation Sans"
set current_font $current_variable_font

set image_viewer "sxiv"
set pdf_viewer "mupdf-x11"


## File hooks

source ~/code/ma/utils/hooks.tcl

proc SchemeFileHook {} {
    uplevel #0 { source ~/code/ma/utils/scheme-indent.tcl }
    SchemeIndent
    ToggleFont fix
}
AddFileHook {\.sc.?$} SchemeFileHook


## Color schemes

set theme_counter 1
foreach x "acme autumn-light blue-sea crisp electric faff
                   glowfish goldenrod relaxed solarized subatomic zenburn" {
    source ~/code/ma/utils/colors/$x.tcl
}


## Plumbing rules

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
