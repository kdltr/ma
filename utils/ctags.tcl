# use "ctags" information to locate definitions
#
# Commands: Tag [IDENTIFIER]


set tagfiletime 0
set tagfile ""


proc LoadTags {} {
    global tagmap tagfile tagfiletime

    if {$tagfile == ""} {
        if {[file exists "tags"]} {
            set tagfile [file normalize "tags"]
        }
    }

    if {$tagfiletime == 0 || [file mtime $tagfile] > $tagfiletime} {
        set f [open $tagfile]
        
        while {[gets $f line] >= 0} {
            if {[regexp {^(\S+)\s+(\S+)\s+(\d+)$} $line _ name file ln]} {
                set tagmap($name) [list $file $ln]
            } elseif {[regexp {^(\S+)\s+(\S+)\s+/(\^?)(.+)(\$)?/$} $line _ name \
                file c str d]} {
                set tagmap($name) [list $file "//$c$str$d/"]
                # puts "$name:$tagmap($name)"
            }
        }

        close $f
    }
}


proc LocateTag {str} {
    global tagmap
    LoadTags

    if {[info exists tagmap($str)]} {
        lassign $tagmap($str) fname addr
        GotoFileAddress $fname $addr
    }
}


DefineCommand {^Tag\s+(\S+)$} {LocateTag [GetArg]}\

DefineCommand {^Tag$} {
    set range [GetEffectiveSelection .t]
    
    if {$range == ""} {
        set range [GetWordUnderIndex .t insert]
    }

    if {$range != ""} {
        LocateTag [eval .t get $range]
    }
}
