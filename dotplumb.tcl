set browser "x-www-browser"
set image_viewer "sxiv"
set pdf_viewer "mupdf"


Plumb {^(.+)(.png|.jpg|.jpeg|.gif)} {
    set fname [GetArg 0]
    if {[file exists $fname]} {
       global image_viewer
       exec $image_viewer $fname
       return 1
    }
    return 0
}

Plumb {^(.+).pdf} {
    set fname [GetArg 0]
    if {[file exists $fname]} {
        global pdf_viewer
        exec $pdf_viewer $fname
        return 1
    }
    return 0
}
