# execute particular files specially


AddToHook execute_hook SpecialFileExecute

proc SpecialFileExecute {cmd ctxt} {
    set ex ""

    if {![file exists $cmd]} {return ""}

    switch -regexp -- $cmd {
        {^(GNU)?[Mm]akefile$} {
            set ex "make -f $cmd"
        }
        {\.zip$} {
            set ex "unzip '$cmd'"
        }
        {\.tar$} {
            set ex "tar xf '$cmd'"
        }
        {\.(tgz|tar.gz)$} {
            set ex "tar xzf '$cmd'"
        }
        {\.(tbz|tar.bz)$} {
            set ex "tar xjf '$cmd'"
        }
        {\.gz$} {
            set ex "gunzip '$cmd'"
        }
        {\.bz$} {
            set ex "bunzip '$cmd'"
        }
        {\.[1-8]$} {
            set ex "man [file normalize $cmd]"
        }
        default {return ""}
    }

    InvokeExternalCommandInWindow $ex
    return 1
}
