# run file-hook on matching name


set file_hooks {}


proc MatchFileHook {} {
    global file_hooks current_filename

    foreach hook $file_hooks {
        lassign $hook rx code

        if {[regexp $rx [file tail $current_filename]]} {
            eval $code
            return
        }
    }
}


AddToHook file_hook MatchFileHook


proc AddFileHook {rx code {before 0}} {
    global file_hooks
    set item [list $rx $code]

    if {$before} {
        set file_hooks [concat [list $item $file_hooks]]
    } else {
        lappend file_hooks $item
    }
}
