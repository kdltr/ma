set browser "x-www-browser"
set image_viewer "sxiv"
set pdf_viewer "mupdf"

# manual pages "page(section)"
Plumb {^(.+)\((.e+)\)$} {
    set manpage [GetArg 1].[GetArg 2]
    Run man $manpage | ma -stdin
}

# scheme documentation "(path to manual page)"
Plumb {^\((.+)\)$} {
    set page [split [GetArg 1]]
    exec chicken-doc {*}$page 2>&1 | ma -stdin
}

# image files
Plumb {^(.+)(.png|.jpg|.jpeg|.gif)$} {
    set fname [GetArg 0]
    if {[file exists $fname]} {
       global image_viewer
       Run $image_viewer $fname
       return 1
    }
    return 0
}

# PDF files
Plumb {^(.+).pdf$} {
    set fname [GetArg 0]
    if {[file exists $fname]} {
        global pdf_viewer
        Run $pdf_viewer $fname
        return 1
    }
    return 0
}
