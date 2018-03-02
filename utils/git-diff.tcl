# basic git(1) interface - diff window


set git_diff_fname ""
set git_enabled_hunks {}
set git_hunk_count 0
set git_mode WORKING
set git_root [Git_FindRoot]
set git_binary 0


.t tag configure git_added -foreground white -background darkgreen
.t tag configure git_removed -foreground white -background darkred
.t tag configure git_disabled -foreground gray70 -background gray10
.t tag configure git_enabled


proc Git_Diff {{fname ""} {new 0} {mode ""}} {
    global git_diff_fname git_enabled_hunks git_mode
    global git_hunk_count git_binary

    if {$mode != ""} {
        set git_mode $mode
    }

    if {$fname == ""} {
        set fname $git_diff_fname
    } else {
        set git_diff_fname $fname
    }

    if {$git_mode == "WORKING"} {
        set diff [exec git diff -- $fname]
    } else {
        set diff [exec git diff --cached -- $fname]
    }

    .t delete 1.0 end
    regexp {\* (\S+)} [exec git branch] _ b
    set rev [exec git rev-parse --short HEAD]
    Insert "\nGit diff [pwd] ($git_mode):\nbranch: $b, rev: $rev, file: $fname\n\n"
    set tag ""
    set hunk 0

    if {$new} {set git_enabled_hunks {}}

    foreach dl [split $diff "\n"] {
        if {[regexp {^(@@[-+ 0-9,]+@@)(.*)$} $dl _ head rest]} {
            if {$new || [lsearch -exact $git_enabled_hunks \
                $hunk] != -1} {
                set tag git_enabled
            } else {
                set tag git_disabled
            }

            if {$new} {lappend git_enabled_hunks $hunk}
        
            Insert "$head hunk:$hunk $rest\n" $tag
            incr hunk
            continue
        }

        if {[regexp {^Binary files} $dl]} {
            Insert "$dl\n"
            set git_binary 1
            continue
        }

        set dltag $tag

        if {$tag != "git_disabled" && ![regexp {^(---|\+\+\+)} $dl]} {
            if {[regexp {^([-+])} $dl _ addrem]} {
                if {$addrem == "+"} {
                    set dltag git_added
                } else {
                    set dltag git_removed
                }
            }
        }

        Insert "$dl\n" $dltag
    }

    set git_hunk_count $hunk
    .t mark set insert 1.0
    Top
    Unmodified
}


proc Git_Apply {cmd {end_if_all 1}} {
    global git_enabled_hunks git_diff_fname git_root git_binary
    set input ""
    set hunks [lsort -integer $git_enabled_hunks]
    set all 1

    if {!$git_binary} {
        for {set h 0} {$hunks != ""} {incr h} {
            set hd [lindex $hunks 0]
    
            if {$h == $hd} {
                append input "y\n"
                set hunks [lrange $hunks 1 end]
            } else {
                append input "n\n"
                set all 0
            }
        }
    
        append input "q\n"
        exec git $cmd -p -- $git_diff_fname > /dev/null 2> \
            /dev/null << $input
    } else {
        exec git $cmd -- $git_diff_fname > /dev/null 2> /dev/null
    }

    catch [list send $git_root/+Git Git_Update]

    if {$all && $end_if_all} {
        Terminate
    } else {
        Git_Diff
    }
}


DefineCommand {^Add$} {Git_Apply add}


DefineCommand {^Commit$} {
    global env
    Git_Apply add 0
    exec env GIT_EDITOR=$env(HERE)/exec/ma git commit &
    Terminate
}


DefineCommand {^Invert$} {
    global git_enabled_hunks git_hunk_count
    set newlist {}

    for {set i 0} {$i < $git_hunk_count} {incr i} {
        if {[lsearch $git_enabled_hunks $i] == -1} {
            lappend newlist $i
        }
    }

    set git_enabled_hunks $newlist
    Git_Diff
}


DefinePlumbing {^hunk:(\d+)$} {
    global git_enabled_hunks
    set h [GetArg 1]
    set p [lsearch -exact $git_enabled_hunks $h]
    
    if {$p == -1} {
        lappend git_enabled_hunks $h
    } else {
        set git_enabled_hunks [lreplace $git_enabled_hunks $p $p]
    }

    Git_Diff
    return 1
}
