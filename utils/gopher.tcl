# gopher links and search

set gopher_history $env(HOME)/.gopher_history

proc GopherExecute {cmd ctxt} {
    if {[regexp {^⊳([^⊲]+)⊲$} $cmd]} {
        Plumb $cmd -a replace=1
        return 1
    }

    return ""
}

AddToHook execute_hook GopherExecute

DefineCommand {^History$} {
    global gopher_history
    Ma $gopher_history -post-eval ReverseLines
}


proc UpdatePage {title fname} {
    lassign [DeconsTag] old cmds rest
    MakeTag "[pwd]/+Gopher" $cmds " $title"
    Acme
    ReplaceText $fname
    UpdateCommand "History"
    ToggleFont fix
}


proc ReverseLines {} {
    set txt [.t get 1.0 end]
    .t delete 1.0 end
    set prev ""
    
    foreach ln [lreverse [split $txt "\n"]] {
        if {$ln != "" && $ln != $prev} {
            .t insert end "$ln\n"
            set prev $ln
        }
    }

    Unmodified
    .t mark set insert 1.0
    .t see 1.0
}
