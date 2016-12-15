# support for marks
#
# Command: Mark [:ADDR|REGEX]
#
# TODO: add unmarking


proc MarkConfiguration {conf} {
    eval .t tag configure mark $conf
}


MarkConfiguration "-background magenta -foreground black"
.t tag lower mark


proc MarkRegexp {rx} {
    set pos 1.0

    while 1 {
        set pos2 [.t search -regexp -- $rx $pos end]

        if {$pos2 == ""} return
        
        # XXX currently only considers whole line
        if {[regexp -indices -- $rx [.t get $pos2 "$pos2 lineend"] all]} {
            set len [expr 1 + [lindex $all 1]]
            set fin "$pos2 + $len chars"
            .t tag add mark $pos2 $fin
            set pos $fin
        } else return
    }
}


proc MarkAt {{addr "."}} {
    set sel [GetEffectiveSelection .t]

    if {$sel != ""} {
        eval .t tag add mark $sel
        RemoveSelection .t
    } else {
        lassign [AddrIndices $addr] p1 p2

        if {$p1 != ""} {
            if {$p2 == ""} {
                set p2 "$p1 lineend"
            }

            .t tag add mark $p1 $p2
        }
    }
}


DefineCommand {^Mark\s+([^:].+)$} {MarkRegexp [GetArg]}
DefineCommand {^Mark\s+:(.+)$} {MarkAt [GetArg]}
DefineCommand {^Mark$} MarkAt
