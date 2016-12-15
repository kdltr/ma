set current_fixed_font "terminus"
set current_variable_font "Liberation Sans"
set image_viewer "sxiv"
set pdf_viewer "mupdf-x11"

source ~/code/ma/utils/hooks.tcl

proc SchemeFileHook {} {
    uplevel #0 { source ~/code/ma/utils/scheme-indent.tcl }
    SchemeIndent
}
AddFileHook {\.scm$} SchemeFileHook

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
