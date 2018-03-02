# another attempt at lisp-indentation
#
# Command: SchemeIndent


set block_forms {
    when unless let let\* letrec letrec\* for-each map case set! else
    with-input-from-file with-output-to-file call-with-values and-let\*
    call-with-current-continuation lambda call-with-input-file append-map
    call-with-output-file match match-let match-let\* match-lambda
    with-output-to-port handle-exceptions begin fluid-let parameterize
    match-lambda\* match-letrec define(-[a-z0-9]+)? receive syntax-rules
    er-macro-transformer ir-macro-transformer condition-case
}

set control_forms {
    cond and or if
}

set scheme_indent 0


proc ScanBackwards {pos} {
    set i 0

    while 1 {
        set c [.t get $pos]

        switch -exact -- $c {
            ")" {incr i}
            "(" {
                if {$i == 0} {return $pos}

                set i [expr $i - 1]
            }
        }

        if {$pos == "1.0"} {return $pos}

        set pos [.t index "$pos - 1 chars"]
    }
}


proc SchemeIndentBlock {rng} {
    lassign $rng from to
    regexp {^(\d+)\.} $from _ fromline
    regexp {^(\d+)\.} $to _ toline
    focus .t
    
    for {set line [expr $fromline + 1]} {$line <= $toline} {incr line} {
        .t mark set insert $line.0
        SchemeIndentLine
    }
}


proc SchemeIndentLine {} {
    global block_forms control_forms

    if {[GetFocusWidget] != ".t"} return

    set pos [.t index "insert linestart - 1 chars"]
    set front [ScanBackwards $pos]
    set pline [.t get "$front + 1 chars" "$front lineend"]
    set tab 0

    if {[regexp {^\s*(\(|\s*$)} $pline]} {
        set tab 1
    } else {
        foreach item $block_forms {
            if {[regexp "^\\s*${item}(\\M|\\s+|\$)" $pline]} {
                set tab 2
                break
            }
        }

        foreach item $control_forms {
            if {[regexp "^\\s*${item}(\\M|\\s+|\$)" $pline]} {
                set tab [expr 2 + [string length $item]]
                break
            }
        }

        if {!$tab} {
            if {![string match "*.0" $front]} {
                regexp {^\S*} $pline head
                set tab [expr [string length $head] + 2]
            }
        }
    }

    set line [.t get "insert linestart" "insert lineend"]

    if {![regexp {^\s+} $line head]} {
        set head ""
    }

    regexp {^\d+\.(\d+)$} $front _ col
    set len [string length $head]
    set nhead [string repeat " " [expr $col + $tab]]
    .t replace "insert linestart" "insert linestart + $len chars" $nhead
}


proc SchemeIndent {} {
    global indent_mode scheme_indent

    if {$scheme_indent} {
        set range [.t tag ranges sel]

        if {$range != ""} {
            SchemeIndentBlock $range
        }

        return
    }

    Flash blue
    set scheme_indent 1
    set indent_mode 1
    DefineKey <Tab> {SchemeIndentLine; break}
    DefineKey <Return> {    
        global current_translation
        set fw [GetFocusWidget]

        if {$current_translation == "crnl"} {
            set nl "\r\n"
        } else {
            set nl "\n"
        }

        if {$fw == ".t"} {
            Insert $nl
            SchemeIndentLine
        } else {
            $fw insert insert $nl
        }

        break
    }
}


DefineCommand {^SchemeIndent$} SchemeIndent
