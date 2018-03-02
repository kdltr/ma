# diff marking


.t tag configure diff_added -foreground white -background darkgreen
.t tag configure diff_removed -foreground white -background darkred
.t tag lower diff_added sel
.t tag lower diff_removed sel


proc MarkDiff {} {
  set pos [.t search -regexp {^@@} 1.0 end]

  if {$pos == ""} return

  while 1 {
    set found [.t search -regexp {^([-+]+)} $pos end]

    if {$found == ""} return

    set line [.t get $found "$found lineend"]
    set pos "$found lineend + 1 chars"
    
    if {![regexp {^(---|\+\+\+)} $line]} {
      if {[string index $line 0] == "+"} {
        set tag diff_added
      } else {
        set tag diff_removed
      }

      .t tag add $tag $found "$found lineend"
    }
  }
}


AddFileHook {\.(diff|patch)$} MarkDiff
DefineCommand {^MarkDiff$} MarkDiff
