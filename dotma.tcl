set current_fixed_font "terminus"
set current_variable_font "Liberation Sans"

set image_viewer "sxiv"
set pdf_viewer "mupdf-x11"

DefinePlumbing {^(.+)(.png|.jpg|.jpeg|.gif)} {
    global image_viewer
    exec $image_viewer [GetArg 0]
}

DefinePlumbing {^(.+).pdf} {
    global pdf_viewer
    exec $pdf_viewer [GetArg 0]
}
