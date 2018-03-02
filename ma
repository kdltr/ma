#!/usr/bin/env wish
#### ma - a minimal variant of acme(1)
#
# (c)MMXV-MMXVII Felix L. Winkelmann
#
# Version: 5


set current_font_size 12
set tag_font_size $current_font_size
set current_fixed_font "Courier"
set fixed_font_size 12
set current_variable_font "Helvetica"
set variable_font_size 12
set current_font $current_variable_font
set current_font_style normal
set current_filename ""
set tag_marker_dirty "■"
set tag_marker_clean "□"
set password_char "∎"
set rcfile "$env(HOME)/.ma"
set wrap_mode char
set executing_pids {}
set search_string ""
set current_foreground black
set current_background "#FFFFEA"
set sbar_color $current_background
set sbar_background "#99994c"
set valid_match_background "#448844"
set invalid_match_background "#884444"
set tag_foreground black
set tag_background "#EAFFFF"
set tag_marker_color "#8888cc"
set selection_foreground black
set selection_background "#eeee9e"
set inactive_selection_background $selection_background
set pseudo_selection_foreground $selection_foreground
set pseudo_selection_background $selection_background
set b2sweep_foreground white
set b2sweep_background "#aa0000"
set b3sweep_foreground white
set b3sweep_background "#006600"
set focus_color white
set nonfocus_color black
set sbar_width 10
set file_hook {}
set name_hook {}
set tabwidth 4
set file_encoding utf-8
set file_translation lf
set dest_address ""
set command_arguments {}
set initial_tag " New Del Cut Paste Snarf Get Put Look Font Wrap | "
set indent_mode 0
set current_translation lf
set command_input_file ""
set any_output 0
set mailer "M"
set browser "firefox"
set b1_down 0
set b2_down 0
set b2_start ""
set b2_with_arg ""
set b2_abort 0
set b3_down 0
set b3_start ""
set shell "bash"
set win_mode 0
set win_file ""
set flashed_range_id ""
set output_window_rx {/[-+][^/]+$}
set eot_symbol "␄\n"
set last_opened ""
set exec_path [split $env(PATH) ":"]
set include_path {"/usr/include"}
set last_mouse_index "1.0"
set history_file ""
set withdrawn 0
set last_del_attempt 0
set exec_prefix ""
set configuration_hook {}
set termination_hook {}
set scroll 0
set focus_window ""
set has_focus 0
set save_hook {}
set password_input ""
set cut_unmodified ""
set position_stack {}


if {[info exists env(MA_INCLUDE_PATH)]} {
    set include_path [concat $include_path [split $env(MA_INCLUDE_PATH) ":"]]
}

if {[info exists env(MA_HISTORY)]} {
    set history_file $env(MA_HISTORY)
}

if {[info exists env(HERE)]} {
    set exec_prefix $env(HERE)/exec/
}

if {[info exists env(SHELL)]} {
    set shell $env(SHELL)
}

if {![regexp $output_window_rx [tk appname]]} { 
    tk appname "MA-[pid]" 
}

set env(MA) [tk appname]

fconfigure stdout -translation lf
fconfigure stderr -translation lf

set command_table {
    {{^New$} {Ma -cd [pwd]}}
    {{^New\s+(.+)$} { Ma [CanonicalFilename [GetArg]] }}
    {{^Delete$} { Terminate 1 }}
    {{^Del$} Terminate}
    {{^Get$} RevertFile}
    {{^Get\s+(.+)$} {OpenNewFile [GetArg]}}
    {{^Cut$} { tk_textCut .t }}
    {{^Paste$} { PasteSelection .t }}
    {{^Snarf$} { tk_textCopy .t }}
    {{^Put$} SaveChanges}
    {{^Put\s+(.+)$} { SaveFile [GetArg] }}
    {{^Wrap$} ToggleWrapMode}
    {{^Look$} {Search [GetSelection .t] "" 1}}
    {{^Look\s+(.+)$} {Search [GetArg] "" 1}}
    {{^Indent$} { 
        global indent_mode
        set indent_mode [expr !$indent_mode]
        Flash blue 
    }}
    {{^Replace\s+(.+)$} { Replace [GetArg] }}
    {{^Kill$} { KillExecuting 1 }}
    {{^Send$} SendToProcess}
    {{^Send\s+(\S.*)$} {SendToProcess [GetArg]}}
    {{^Tab$} { global tabwidth; LogInWindow "Tab width is $tabwidth\n" }}
    {{^Tab\s+(\d+)$} { global tabwidth; set tabwidth [GetArg]; Flash blue }}
    {{^Font$} {ToggleFont}}
    {{^Font\s+(fix|var)$} {ToggleFont [GetArg]}}
    {{^Tcl$} { Evaluate [GetSelection .t] }}
    {{^Tcl\s+(.+)$} { Evaluate [GetArg] }}
    {{^Undo$} { catch {[GetFocusWidget] edit undo}}}
    {{^Redo$} { catch {[GetFocusWidget] edit redo} }}
    {{^Scroll$} {ToggleScroll; Flash blue}}
    {{^Anchor$} InsertAnchor}
    {{^Withdraw$} WithdrawWindow}
    {{^Putall$} {SaveAllModified 0}}
    {{^Back$} PopMoveInsert}
    {{^Crnl$} {
        global current_translation
        set current_translation "crnl"
        Flash blue}
    }
}

set plumbing_rules {
    {{^:(.+)} { GotoBodyAddress [GetArg 1] }}
    {{^[-A-Za-z0-9_.+]+@[-A-Za-z0-9_.+]+$} { 
        global mailer
        Flash blue
        exec $mailer [GetArg 0] < /dev/null & 
        return 1
    }}
    {{^(http|https|ftp)://[-A-Za-z0-9_.+%/&?=#~:]+$} { 
        global browser
        Flash blue
        exec $browser [GetArg 0] & 
        return 1
    }}
    {{^"([^"]+)"$} { GotoIncludeFile [GetArg] }}
    {{^<([^>]+)>$} { GotoIncludeFile [GetArg] }}
    {{^([^:]+):((\d+|//?[^/]+/?|\?[^?]+\??|\$|#\d+|\.)(,(\d+|/[^/]+/?|\?[^?]+\??|\$|#\d+|\.))?)} { 
        GotoFileAddress [file normalize [GetArg 1]] [GetArg 2] 
    }}
    {{^([^:]+):} { GotoFileAddress [file normalize [GetArg 1]] }}
    {{^(\S+)\((\d+)\)$} { 
        InvokeExternalCommandInWindow "man [GetArg 2] [GetArg 1]" 
    }}
}


tk_focusFollowsMouse
. configure -highlightthickness 2


proc Register {id fname} {
    global app_registry fname_registry
    set app_registry($fname) $id
    set fname [CanonicalFilename $fname]
    set fname_registry($id) $fname
    .t insert end "register: $id / $fname\n"
}


proc Unregister {id} {
    global fname_registry focus_window
    set fname_registry($id) ""
    
    if {$focus_window == $id} {
        .t insert end "unregister: $id\n"
        set focus_window ""
    }
}


proc StartRegistry {} {
    global withdrawn

    if {![catch {send MA-registry #}]} {
        puts stderr "registry already active"
        exit 1
    }

    tk appname MA-registry
    set withdrawn 1
}


proc SetFocusWindow {id} {
    global focus_window

    if {$focus_window != ""} {
        .t insert end "drop focus: $focus_window\n"
        catch [list send -async $focus_window DropFocus]
    }

    set focus_window $id
}


proc TakeFocus {} {
    global has_focus focus_color

    if {!$has_focus} {
        set has_focus 1

        if {![catch [list send -async MA-registry SetFocusWindow [tk appname]]]} {
            . configure -highlightcolor $focus_color -highlightbackground \
                $focus_color
        }
    }
}


proc DropFocus {} {
    global has_focus nonfocus_color
    set has_focus 0
    . configure -highlightcolor $nonfocus_color -highlightbackground \
        $nonfocus_color
}


proc Locate {fname {addr ""}} {
    global app_registry fname_registry
    set fname [CanonicalFilename $fname]
    
    if {[info exists app_registry($fname)]} {
        set id $app_registry($fname)

        if {$id != "" && $fname_registry($id) == $fname} {
            if {$addr == ""} {
                if {![catch [list send $id ActivateWindow]]} {
                    return $id
                }
            } else {
                if {![catch [list send $id GotoBodyAddress "{$addr}"]]} {
                    return $id
                }
            }
        }
    }
    
    return ""
}


proc SaveAllModified {regmode} {
    global app_registry fname_registry

    if {$regmode} {
        foreach fname [array names app_registry] {
            set id $app_registry($fname)

            if {$id != "" && $fname_registry($id) == $fname} {
                catch [list send -async $id SaveIfModified]
            }
        }
    } else {       
        if {[catch {send -async MA-registry SaveAllModified 1}]} {
            SaveIfModified
        }
    }
}


proc SaveChanges {} {
    global current_filename
    GetFilename
    SaveFile $current_filename
}


proc ActivateWindow {} {
    .t see insert
    WarpToIndex .t insert
    Flash blue
}


proc FindFile {fname {addr ""}} {
    set id [Locate $fname $addr]

    if {$id == ""} {
        Ma $fname -address $addr
    }
}


proc ListWindows {} {
    global fname_registry app_registry
    set wins {}

    foreach fname [array names app_registry] {
        if {$fname_registry($app_registry($fname)) == $fname} {
            lappend wins $app_registry($fname)
        }
    }

    return $wins
}


proc ToggleScroll {{m ""}} {
    global scroll sbar

    if {$m == ""} {set m [expr !$scroll]}

    set scroll $m

    if {$scroll} {
        Bottom
        .s itemconfigure $sbar -stipple gray50
    } else {
        .s itemconfigure $sbar -stipple ""
    }
}


proc Ma {args} {
    global exec_prefix
    eval exec ${exec_prefix}ma $args &
}


proc GotoFileAddress {fname {addr ""}} {
    set addr [string trim $addr]

    if {![regexp {^/} $fname]} {
        set dir [GetFileDir]
        set fname "$dir/$fname"
    } 

    if {[file exists $fname]} {
        if {[catch {send MA-registry Locate $fname "{$addr}"} result] || $result == ""} {
             Ma $fname -address $addr
        }

        return 1
    }

    return 0
}


proc SimpleRegex {str} {
    return [regsub -all -- {\(|\)|\||\+|\*|\.|\?|\[|\]} $str {\\\0}]
}


proc ParseAddr {addr} {
    # returns index + whole-line flag

    # this is silly - addresses should enclose ranges as in sam, and
    # explicit ranges as in "," should combine these.

    if {$addr == "0"} { return {1.0 0} }

    if {$addr == "\$"} { return {end 0} } 

    if {$addr == "."} { return {insert 0} }

    if {[regexp {^/(/?[^/]+)/?$} $addr _ rx]} {
        # hack for ctags: we need "simple" regexes, apparently...
        if {[regexp {^/} $rx]} {
            set rx [SimpleRegex [string range $rx 1 end]]
        }

        return [list [.t search -regexp $rx 1.0] 0]
    }

    if {[regexp {^\?([^?]+)\??$} $addr _ rx]} { 
        return [list [.t search -regexp -backwards $rx end] 0] 
    }

    if {[regexp {^#(\d+)$} $addr _ pos]} { 
        return [list "1.0 + $pos chars" 0] 
    }

    if {[regexp {^\d+$} $addr]} { return [list "$addr.0" 1] }

    return ""
}


proc AddrIndices {addr} {
    # validate by parsing the whole addr instead of doing this
    if {![regexp {^(\d+|//?[^/]+/?|\?[^?]+\??|\$|#\d+|\.)(,(\d+|/[^/]+/?|\?[^?]+\??|\$|#\d+|\.))?$} $addr _ from rng to]} {
        return ""
    }

    set p1 [ParseAddr $from]
    set p2 ""

    if {$rng != ""} {
        set p2 [ParseAddr $to]
        set p2i [lindex $p2 0]
        
        # if range of lines: select the latter fully
        if {[lindex $p2 1]} {
            set p2 "$p2i lineend + 1 chars"
        } else {
            set p2 $p2i
        }
    } elseif {[lindex $p1 1]} {
        # if only a line is given, select it fully
        set p2 "[lindex $p1 0] lineend + 1 chars"
    }

    return [list [lindex $p1 0] $p2]
}


proc GotoBodyAddress {addr {flash 0}} {
    RemoveSelection .t
    lassign [AddrIndices $addr] p1 p2

    if {$p1 == ""} {return 0}

    if {$p2 != ""} {
        set seltag sel
    
        if {[focus -displayof .] != ".t"} {
            set seltag pseudosel
        }

        .t tag add $seltag $p1 $p2
    } else {
        # flash, or we won't notice
        Flash blue
    }

    MoveInsert $p1
    WarpToIndex .t insert
    return 1
}


proc MoveInsert {pos {see 1}} {
    global position_stack
    lappend position_stack [.t index insert]
    .t mark set insert $pos

    if {$see} {.t see insert}
}


proc PopMoveInsert {{see 1}} {
    global position_stack

    if {$position_stack != ""} {
        RemoveSelection .t
        .t mark set insert [lindex $position_stack end]
        set position_stack [lrange $position_stack 0 end-1]

        if {$see} {.t see insert}
    }
}


proc PasteSelection {w} {
    set rng [$w tag ranges sel]

    if {$rng != ""} {
        set sel ""
        eval $w delete $rng
    } elseif {[catch {selection get -type UTF8_STRING} sel]} {
        set sel ""
    }

    if {$sel == ""} {
        tk_textPaste $w
    } else {
        $w insert insert $sel
    }
}

proc FindInPath {fname path} {
    set found {}

    foreach x $path {
        set fn [file join $x $fname]
    
        if {[file exists $fn]} {
            lappend found $fn
        }
    }

    return $found
}


proc FindExecutable {cmd} {
    global exec_path

    if {![regexp {^\s*(\S+)(.*)$} $cmd _ prg rest]} {
        set rest ""
    }

    set found [FindInPath $prg $exec_path]

    foreach x $found {
        if {[file type $x] != "directory" && [file executable $x]} {
            if {$rest != ""} {
                return "$x $rest"
            } else {
                return $x
            }
        }
    }

    return ""
}


proc GotoIncludeFile {fname} {
    global include_path
    set found [FindInPath $fname $include_path]

    if {$found != ""} {
        GotoFileAddress [lindex $found 0]
        return 1
    }

    return 0
}


proc InsertAnchor {} {
    set sel [.t tag ranges sel]

    if {$sel == ""} {
        set a "#[.t count -chars 1.0 insert]"
    } else {
        set p1 [.t count -chars 1.0 [lindex $sel 0]]
        set p2 [.t count -chars 1.0 [lindex $sel 1]]
        set a "#$p1,#$p2"
    }

    .tag insert "1.0 lineend" " :$a"
}


proc ToggleFont {{mode ""}} {
    global current_font current_fixed_font current_variable_font
    global current_font_size fixed_font_size variable_font_size
   
    switch $mode {
        fix {
            set current_font $current_fixed_font
            set current_font_size $fixed_font_size
        }
        var {
            set current_font $current_variable_font
            set current_font_size $variable_font_size
        }
        default {
            if {$current_font == $current_fixed_font} {
                ToggleFont var
            } else {
                ToggleFont fix
            }
        }
    }
    ResizeFont 0
}


proc DefineCommand {pat code} {
    global command_table
    lappend command_table [list $pat $code]
}


proc DefinePlumbing {pat code} {
    global plumbing_rules
    lappend plumbing_rules [list $pat $code]
}


proc GetArg {{i 1}} {
    global command_arguments
    return [lindex $command_arguments $i]
}


proc ReadFile {fname} {
    global file_translation file_encoding

    if {[catch [list open $fname r] in]} {
        LogInWindow "$in\n" 1
        return {"" ""}
    }

    fconfigure $in -translation $file_translation -encoding $file_encoding
    set text [read $in]
    close $in
    set tr lf

    if {[regexp "\r\n" $text] && ![regexp "\[^\r]\n" $text]} {
        set tr crnl
    }
        
    return [list $text $tr]
}


proc Top {} {.t see 1.0}
proc Bottom {} {.t see end}


proc Unmodified {} {
    global tag_marker_clean

    # hack, somehow just setting modified to 0 is sometimes not enough
    after 100 {
        .t edit modified 0
        SetTagMarker $tag_marker_clean
    }
}


proc AddToHook {hook cmd} {
    global $hook
    lappend $hook $cmd
}


proc RunHook {hook} {
    global $hook
    
    foreach h [set $hook] {
        eval $h
    }
}


proc DeconsTag {} {
    global tag_marker_clean tag_marker_dirty
    set text [.tag get 1.0 end]

    if {[regexp "^($tag_marker_clean|$tag_marker_dirty)" $text]} {
        set m [string range $text 0 0]
        set text [string range $text 1 end]
    } else {
        if {[.t edit modified]} {
            set m $tag_marker_dirty
        } else {
            set m $tag_marker_clean
        }
    }

    if {[regexp {^\s*'([^']*)'\s*([^|]*)\|(.*)$} $text _ fname cmds rest]} {
        return [list $m $fname $cmds $rest]
    }

    if {[regexp {^([^ ]+)\s+([^|]*)\|(.*)$} $text _ fname cmds rest]} {
        return [list $m $fname $cmds $rest]
    } 

    if {[regexp {^([^|]*)\|(.*)$} $text _ cmds rest]} {
        return [list $m "" $cmds $rest]
    }

    return [list $m "" text ""]
}


proc MakeTag {fname {c ""} {r ""}} {
    lassign [DeconsTag] m old cmds rest
    .tag delete 1.0 end

    if {[regexp {\s} $fname]} {
        set fname2 "'$fname'"
    } else {
	set fname2 $fname
    }

    if {$c != ""} {set cmds $c}

    if {$r != ""} {set rest $r}

    .tag insert 1.0 "$m" tagmark
    .tag insert end "$fname2 $cmds|[string trimright $rest] "

    if {$old != $fname} {
        RunHook name_hook
    }
}


proc SetTag {text} {
    .tag delete 1.1 end
    .tag insert 1.1 $text
}


proc SetTagMarker {m} {
    .tag delete 1.0
    .tag insert 1.0 $m tagmark
}


proc UpdateTag {{fname ""}} {
    global current_filename output_window_rx
    
    if {$fname != ""} {
        set fname [CanonicalFilename $fname]

        if {![regexp $output_window_rx $fname]} {
            set current_filename $fname
            set env(MA_LABEL) $current_filename
        }

        if {[regexp {/$} $fname]} {
            set dir $fname
        } else {
            set dir [file dirname $fname]
        }

        if {[file exists $dir]} {cd $dir}
    } else {
	set fname $current_filename
    }

    wm title . $fname
    MakeTag $fname
    .tag mark set insert "1.0 lineend"
    catch [list send -async MA-registry Register [tk appname] $fname]
}


proc GetFilename {} {
    global current_filename output_window_rx
    lassign [DeconsTag] _ name

    if {![regexp $output_window_rx $name]} {
        set current_filename $name
    }

    return $current_filename
}


proc GetFileDir {} {
    lassign [DeconsTag] _ name
    set name2 [FollowLink $name]

    if {[file exists $name2] && [file type $name2] == "directory"} {
        return [file normalize $name]
    } else {
        return [file normalize [file dirname $name]] 
    }

    return [pwd]
}


proc OpenNewFile {fname} {
    if {[CheckIfModified]} {
        if {[ModificationCheck]} return
    }

    OpenFile $fname
}


proc OpenFile {{name ""} {replace 1}} {
    global current_filename last_opened current_translation
    global position_stack

    if {$name == ""} {
	set init [GetFileDir]
	set name [tk_getOpenFile -initialdir $init]

	if {$name == ""} { return }
    }

    if {[file exists $name]} {
	set t [file type [FollowLink $name]]

	if {[file type $name] == "file"} {
	    Flash green
            set last_opened [list $name [file mtime $name]]
	    lassign [ReadFile $name] text tr
            UpdateTag $name
	    
	    if {$replace} {
                SetText $text
		.t mark set insert 1.0
		.t see insert
	    } else {
		Insert $text
	    }
	    
            set position_stack {}
            set current_translation $tr
	    Unmodified
            RunHook file_hook
	    return
	}

	LogInWindow "$name is not a regular file" 1
	return
    }

    LogInWindow "no such file: $name" 1
}


proc ReplaceText {fname} {
    global current_translation position_stack
    lassign [ReadFile $fname] text tr
    SetText $text
    .t mark set insert 1.0
    .t see insert
    set position_stack {}
    Unmodified
}


proc SetText {text {addr ""}} {
    if {$addr == ""} {
        set from 1.0
        set to end
    } else {
        lassign [AddrIndices $addr] from to

        if {$to == ""} {set to end}
    }

    .t delete $from $to
    .t insert $from $text
}


# not used here, only for "ma-eval"
proc GetText {{addr ""}} {
    if {$addr == ""} {
        set from 1.0
        set to end
    } else {
        lassign [AddrIndices $addr] from to

        if {$to == ""} {set to end}
    }

    return [.t get $from $to]
}


proc FollowLink {fname} {
    if {[file exists $fname] && [file type $fname] == "link"} {
        if {[catch [list file readlink $fname] fn2]} {
            puts stderr "dead link: $fname"
            return $fname
        }

        if {![regexp {^/} $fn2]} {
            set fn2 "[file dirname $fname]/$fn2"
        }

        return [FollowLink $fn2]
    }

    return $fname
}


proc NeedsQuoting {fname} {
    return [string match {*[ '()]*} $fname]
}


proc FormatColumnar {list} {
    global current_font current_font_size
    set zw [font measure [list $current_font $current_font_size] 0]
    set w [expr [winfo width .t] / $zw]
    set n [llength $list]
    set maxlen 0

    # compute maximal item length
    foreach x $list {
	set len [string length $x]

        if {[NeedsQuoting $x]} {incr len 2}

	if {$len > $maxlen} {set maxlen $len}
    }

    incr maxlen 2
    set cols [expr max(1, round($w / $maxlen))]
    set rows [expr ceil(double($n) / $cols)]
    set text ""

    for {set i 0} {$i < $rows} {incr i} {
	for {set j 0} {$j < $cols} {incr j} {
	    set f [lindex $list [expr $i * $cols + $j]]
            set flen [string length $f]

            if {[NeedsQuoting $f]} {
                set q "\'"

                if {[string first "\'" $f] != -1} {set q "\""}

                if {[string index $f end] == "/"} {
                    set f "$q[string range $f 0 "end-1"]$q/"
                } else {
                    set f "$q$f$q"
                }

                incr flen 2
            }

            if {$cols > 1} {
      	        set pad [string repeat " " [expr $maxlen - $flen]]
            } else {
                set pad ""
            }

	    append text $f $pad
	}

	append text "\n"
    }

    return $text
}


proc OpenDirectory {name} { 
    global current_translation position_stack
    set name [file normalize $name]
    Flash green

    if {[catch [list glob -tails -directory $name *] files]} {
        set files {}
    }

    set files [concat $files [glob -tails -types hidden -directory $name *]]
    set files [lsort -dictionary $files]
    set nfiles {}

    # add "/", if directory
    foreach f $files {
        if {$f != "." && $f != ".."} {
            if {[file type [FollowLink "$name/$f"]] == "directory"} {
                append f "/"
            }

            lappend nfiles $f
        }
    }

    set text [FormatColumnar $nfiles]
    UpdateTag "$name/"
    SetText $text
    .t mark set insert 1.0
    set position_stack {}
    Top
    ToggleFont fix
    set current_translation lf
    Unmodified
}


proc SaveFile {{name ""}} {
    global current_filename last_opened
    set name0 $current_filename
    GetFilename
    
    if {$name == ""} {
	set init [GetFileDir]
	set name [tk_getSaveFile -initialdir $init -initialfile $current_filename]

	if {$name == ""} { return 0 }
    }
    
    if {($name == $current_filename || $name == "") && \
        $name0 == $current_filename && [.t edit modified] == 0 && \
	    [file exists $current_filename]} { 
	return 1 
    }

    if {$last_opened != ""} {
        if {[lindex $last_opened 0] == $name && \
            [lindex $last_opened 1] != [file mtime $name]} {
            if {[tk_messageBox -message "$name has been modified. Save it anyway?" \
                -type okcancel -default cancel] == "cancel"} {
                return 0
            }
        }
    } elseif {[file exists $name]} {
        if {[tk_messageBox -message "Overwrite $name ?" -type okcancel -default cancel] \
            == "cancel"} {
            return 0
        }
    }

    Flash green
    set dir [file dirname $name]

    if {![file exists $dir]} {
	file mkdir $dir
    }

    set out [open $name w]
    set text [.t get 1.0 "end - 1 chars"]
    puts -nonewline $out $text
    close $out
    
    if {[string equal -length 3 $text "#!/"]} {
        file attribute $name -permissions a+x
    }

    set last_opened [list $name [file mtime $name]]
    Unmodified
    UpdateTag $name
    RunHook save_hook
    return 1
}


proc Flash {{color red}} {
    global current_background
    .t configure -background $color
    update
    after 100 {.t configure -background $current_background}
}


proc CheckIfModified {} {
    global current_filename
    GetFilename

    if {[.t edit modified] && $current_filename != "" && \
        ![regexp {/$} $current_filename]} { 
        return 1 
    }

    return 0
}


proc SaveIfModified {} {
    if {[CheckIfModified]} SaveChanges
}


proc WithdrawWindow {} {
    global withdrawn

    if {!$withdrawn} {
        wm withdraw .
        set withdrawn 1
    }
}


proc DeiconifyWindow {} {
    global withdrawn

    if {$withdrawn} {
        wm deiconify .
        set withdrawn 0
    }
}


proc Insert {text {tags ""}} {
    DeiconifyWindow
    .t insert insert $text $tags
    .t see insert
}


proc Append {text {sel 0}} {
    global win_mode scroll
    DeiconifyWindow
    set p1 [.t index "end - 1 chars"]
    .t insert end $text

    ScrollToBottom

    if {$sel} { 
        RemoveSelection .t
        .t tag add sel $p1 "end - 1 chars"
    }
}


proc ScrollToBottom {} {
    global win_mode scroll

    if {!$scroll} return

    if {$win_mode} {
        if {[catch {.t dlineinfo win_insert_point} result] || \
            $result != ""} {  
            Bottom
        }
    } else Bottom
}


proc AppendLine {text {sel 0}} {
    Append "$text\n" $sel
}


proc AppendFile {fname} {
    DeiconifyWindow
    set f [open $fname]
    set txt [read $f]
    close $f
    Append $txt
}


proc ModificationCheck {} {
    global current_filename last_del_attempt
    set cnt [.t count -chars 1.0 end]

    if {$last_del_attempt == 0 || $cnt != $last_del_attempt} {
        LogInWindow "$current_filename is modified\n" 1
       	Flash 
        set last_del_attempt $cnt
        return 1
    }

    return 0
}


proc Terminate {{force 0}} {
    global executing_pids current_filename last_del_attempt win_mode

    if {!$force && [CheckIfModified]} { 
        if {[ModificationCheck]} return
    }

#   not sure about this:
#
#    foreach pid $executing_pids {
#        catch [list exec kill -9 $pid]
#    }

    catch [list send -async MA-registry Unregister [tk appname]]
    RunHook termination_hook
    exit
}


proc ResizeFont {inc} {
    global current_font_size current_font current_font_style
    global fixed_font_size variable_font_size
    set current_font_size [expr $current_font_size + $inc]
    set fixed_font_size [expr $fixed_font_size + $inc]
    set variable_font_size [expr $variable_font_size + $inc]
    .t configure -font [list $current_font $current_font_size $current_font_style]
    RunHook configuration_hook
}


proc ConfigureWindow {{runhook 1}} {
    global current_background current_foreground current_font 
    global current_variable_font current_font_size current_font_style
    global tag_foreground tag_background selection_foreground 
    global selection_background
    global sbar_color sbar sbar_background wrap_mode b2sweep_foreground 
    global b2sweep_background 
    global b3sweep_foreground b3sweep_background pseudo_selection_foreground 
    global pseudo_selection_background tag_marker_color
    global win_mode tag_font_size 
    global inactive_selection_background 
    global has_focus focus_color nonfocus_color

    if {$has_focus} {
        . configure -highlightcolor $focus_color -highlightbackground \
            $focus_color
    } else {
        . configure -highlightcolor $nonfocus_color -highlightbackground \
            $nonfocus_color
    }

    .tag configure -background $tag_background -foreground $tag_foreground \
	-selectbackground $selection_background -selectforeground $selection_foreground \
	-inactiveselectbackground $inactive_selection_background \
	-insertbackground $tag_foreground -font [list $current_variable_font $tag_font_size] \
        -insertofftime 0 -relief ridge -highlightthickness 0 -wrap char \
        -borderwidth 1 -cursor arrow

    .tag tag configure tagmark -foreground $tag_marker_color

    .t configure -background $current_background -foreground $current_foreground  \
	-selectbackground $selection_background -selectforeground $selection_foreground \
	-inactiveselectbackground $inactive_selection_background \
	-insertbackground $current_foreground -font \
         [list $current_font $current_font_size $current_font_style] \
        -relief ridge -borderwidth 1 -highlightthickness 0 \
        -insertofftime 0 -insertwidth 3 -wrap $wrap_mode -cursor arrow
    .s configure -background $sbar_background -relief ridge -borderwidth 1 \
        -highlightthickness 0
    .s itemconfigure $sbar -fill $sbar_color -width 0 -stipple ""
    .t tag configure pseudosel -foreground $pseudo_selection_foreground -background $pseudo_selection_background
    .tag tag configure pseudosel -foreground $pseudo_selection_foreground -background $pseudo_selection_background
    .t tag configure b2sweep -foreground $b2sweep_foreground -background $b2sweep_background
    .tag tag configure b2sweep -foreground $b2sweep_foreground -background $b2sweep_background
    .t tag configure b3sweep -foreground $b3sweep_foreground -background $b3sweep_background
    .tag tag configure b3sweep -foreground $b3sweep_foreground -background $b3sweep_background
    .t tag lower pseudosel
    .tag tag lower pseudosel

    if {$win_mode} {.t configure -insertofftime 300}

    if {$runhook} {
        RunHook configuration_hook
    }
}


proc ToggleWrapMode {{mode ""}} {
    global wrap_mode
    
    if {$mode != ""} {
	set wrap_mode $mode
    } elseif {$wrap_mode == "none"} {
	set wrap_mode "char" 
    } else { 
	set wrap_mode "none"
    }

    .t configure -wrap $wrap_mode
    RunHook configuration_hook
}


proc DefineKey {event cmd} {
    bind .tag $event $cmd
    bind .t $event $cmd
}


proc DoRunCommand {cmd {inputfile ""}} {
    global command_input_file shell

    if {$inputfile != ""} {
        set command_input_file $inputfile
        return [open "| $shell -c {$cmd} < $inputfile 2>@1" r]
    } else {
        return [open "| $shell -c {$cmd} << {} 2>@1" r]
    }
}


proc RunExternalCommand {cmd {inputfile ""} {sender ""} {sender_label ""}} {
    global executing_pids command_input_file env scroll 

    if {!$scroll} {
        Bottom
    }

    if {$sender != ""} {
        set env(MA) $sender 
        set env(MA_LABEL) $sender_label
    }

    if {[catch [list DoRunCommand $cmd $inputfile] input]} {
	Append "\nCommand failed: $input\n"

        if {$command_input_file != ""} {
            file delete -force $command_input_file
        }

	return
    }

    lappend executing_pids [pid $input]
    fconfigure $input -blocking 0
    fileevent $input readable [list LogOutput $input]
}


proc RecordPosition {} {
    global last_mouse_index
    set last_mouse_index [.t index insert]
}


proc LogOutput {input} {
    global current_background command_input_file eot_symbol executing_pids 
    global any_output win_mode
    set data [read $input]
    set blocked [fblocked $input]

    if {$data != ""} {
        DeiconifyWindow
        set any_output 1
        set endpos [.t index "end - 1 chars"]

        # recognize + remove "bell" character
        if {[regexp "\x07" $data]} {
            Flash white
            regsub -all "\x07" $data "" data
        }

        Append "$data"
        
        if {$win_mode} {
            .t mark set win_insert_point "end - 1 chars"
            .t mark gravity win_insert_point left
        }
    } elseif {!$blocked} {
        set pid [pid $input]

        if {[catch [list close $input] result]} {
            Append "\nCommand failed: $result"
            set any_output 1
        } else {
            Append $eot_symbol
        }

        set i [lsearch -exact $pid $executing_pids]
        set executing_pids [lreplace $executing_pids $i $i] 

        if {$command_input_file != ""} {
           file delete -force $command_input_file
        }

        if {!$any_output} {Terminate 1}
            
        if {$executing_pids == ""} {
            set win_mode 0
        }
    }

    update idletasks
}


proc Evaluate {cmd} {
    if {[catch [list uplevel #0 $cmd] result]} {
        Flash red
    } else {
        Flash blue
    }
}


proc CanonicalFilename {str} {
    set dir [GetFileDir]

    if {![regexp {^\s*[~/]} $str]} {
	set fname "$dir/$str"
    } else {
	set fname $str
    }

    if {[file exists $fname]} {
        set fname [file normalize $fname]

        if {[file type $fname] == "directory"} {
            append fname "/"
        }
    }

    return $fname
}


proc Acquire {} {
    global search_string ma plumbing_rules command_arguments
    global tag_marker_clean tag_marker_dirty
    set fw [GetFocusWidget]

    # range: either what is swept with B3, or the selection (if the mouse is inside it)
    # or the word under the cursor:

    set range [$fw tag ranges b3sweep]

    if {$range == ""} {
        set range [$fw tag ranges sel]

        if {$range == "" || [lsearch -exact [$fw tag names current] sel] == -1} {
            set range ""
        }
    }

    if {$range == ""} {
        set dest [GetWordUnderCursor $fw]
        set start [$fw index "current + [string length $dest] chars"]
    } else {
        set start "[lindex $range 0] + 1 chars"
        set dest [$fw get [lindex $range 0] [lindex $range 1]]        
    }

    RemoveTaggedRange $fw b3sweep
    set dest [string trim $dest]

    if {$dest == ""} return

    foreach r $plumbing_rules {
        set command_arguments [regexp -inline -- [lindex $r 0] $dest]

        if {$command_arguments != ""} {
            set r [eval [lindex $r 1]]
    
            if {$r != 0} return
        }
    }

    lassign [DeconsTag] m name

    if {"$name" == $dest} {
        RemoveSelection .t
        .t tag add sel 1.0 end
        return
    }

    if {[regexp "^$tag_marker_clean|$tag_marker_dirty" $dest]} {
        set fname [string range $dest 1 end]
    } else {
        set fname $dest
    }

    set fname [CanonicalFilename $fname]

    if {[file exists $fname]} {
        RemoveSelection
        set fname [FollowLink $fname]
        GotoFileAddress $fname
	return
    }

    # force search in body
    if {$range == "" && $fw != ".t"} {set start [.t index insert]}

    Search $dest $start
}


proc Search {{str ""} {start ""} {case 0}} {
    global search_string

    if {$str != ""} {
        set search_string $str
    } else {
        return
    }

    set range [.t tag ranges sel]

    if {$start == ""} {
        if {$range != ""} {
            set start "[lindex $range 0] + 1 chars"
        } else {
            set start "insert + 1 chars"
        }
    }

    if {$case} {
        set found [.t search -- $search_string $start]
    } else {
        set found [.t search -nocase -- $search_string $start]
    }
    
    if {$found != ""} {
        # keep selection in case it was in tag
        if {[GetFocusWidget] == ".tag"} {
            SaveSelection .tag
        }

        RemoveSelection .t
	set len [string length $search_string]
	set end "$found + $len chars"
	.t tag add sel $found $end
        MoveInsert $end
        WarpToIndex .t $found
    }
}


proc WarpToIndex {fw index} {
    set info [.t bbox $index]
    
    if {$info != ""} {
        set x [expr [lindex $info 0] + [lindex $info 2] / 2]
        set y [expr [lindex $info 1] + [lindex $info 3] / 2]
        event generate .t <Motion> -x $x -y $y -warp 1
    }
}


proc GetFocusWidget {} {
    set fw [focus -displayof .]

    if {$fw == ""} {
	return .t
    }

    return $fw
}


proc GetWordUnderCursor {{fw ""}} {
    set ixs [GetWordUnderIndex $fw current]

    if {$ixs == ""} {
        return ""
    }

    return [eval $fw get $ixs]
}


proc GetWordUnderIndex {fw idx} {
    global tag_marker_dirty tag_marker_clean
    set startx [$fw index "$idx linestart"]
    regexp {^(\d+)\.} $startx _ lnum
    set endx [$fw index "$idx lineend"]
    set posx [$fw index $idx]
    set start [$fw get $startx $posx]
    set end [$fw get $posx $endx]
    regexp {\.(\d+)$} $posx _ col

    if {[regexp -indices "(\[^ $tag_marker_dirty$tag_marker_clean\t\r\"'()\\\[\\\]{}\]+)\$" $start _ pos]} {
        set w0 [lindex $pos 0]
        
        if {[regexp -indices "^(\[^ \t\r\"'()\\\[\\\]{}\]+)" $end _ pos]} {
            return [list "$lnum.$w0" "$lnum.[expr $col + [lindex $pos 1] + 1]"]
        }

        return [list "$lnum.$w0" "$lnum.[expr [lindex $pos 1] + 1]"]
    }

    if {[regexp -indices "^(\[^ \t\r\"'()\\\[\\\]{}\]+)" $end _ pos]} {
        return [list $posx "$lnum.[expr $col + [lindex $pos 1] + 1]"]
    }
    
    return ""
}


proc KillExecuting {{parent 0}} {
    global executing_pids win_mode

    if {$executing_pids != ""} {
        # shell may have exec'd or may have forked subprocesses

        foreach pid $executing_pids {
            foreach cpid [ChildPids $pid] {
                catch [list exec kill -9 $cpid]
            }

            if {$parent || !$win_mode} {
                catch [list exec kill -9 $pid]
                set executing_pids {}
                Append "\n*** KILLED\n"
                set win_mode 0
            }
        }
    }
}


proc InvokeExternalCommandInWindow {cmd {input ""}} {
    global current_filename
    set myname [tk appname]
    ExecuteInWindow [list RunExternalCommand $cmd $input $myname $current_filename]
    return 1
}


proc ExecuteInWindow {cmd {tag ""}} {
    global ma 
    set dir [GetFileDir]
    set name "$dir/+Errors"

    if {[catch [list send $name #]]} {
        if {$tag == ""} {
            set tag "$dir/+Errors New Kill Del Cut Paste Snarf Look Font Wrap Scroll | "
        }

        Ma -name $name -cd $dir -tag $tag -withdrawn -post-eval $cmd
    } else {
        catch [list send $name $cmd]
    }
}


proc SendToProcess {{cmd ""}} {
    global win_file win_mode
    set range [GetEffectiveSelection .t]
        
    if {$cmd == ""} {
        if {$range != ""} {
            set cmd [.t get [lindex $range 0] [lindex $range 1]]
        } else return
    }

    RemoveSelection .t
    Append "$cmd\n"
    .t mark set insert end

    if {$win_mode} {
        puts $win_file $cmd
        flush $win_file
        AddToHistory $cmd
    }
}


proc LogInWindow {msg {sel 0}} {
    ExecuteInWindow [list Append $msg $sel]
}


proc SmartIndent {} {
    global tabwidth indent_mode

    if {[GetFocusWidget] != ".t"} return

    set pos [.t index insert]
    regexp {(\d+)\.(\d+)} $pos all row col

    if {$row > 1 && $indent_mode} {
	set rowup [expr $row - 1]
	set above [.t get $rowup.0 "$rowup.0 lineend"]
	set uplen [string length $above]

	if {$uplen > $col} {
	    set i $col

	    # first skip non-ws chars
	    while {$i < $uplen && [string index $above $i] != " "} {
		incr i
	    }

	    while {$i < $uplen} {
		if {[string index $above $i] != " "} {
		    Insert [string repeat " " [expr $i - $col]]
		    return
		}

		incr i
	    }
	}
    }
    
    set tcol [expr (($col / $tabwidth) + 1) * $tabwidth]
    Insert [string repeat " " [expr $tcol - $col]]
}


proc TempFile {} {
    global env
    set tmpdir "/tmp"

    if {[info exists env(TMPDIR)]} {
	set tmpdir $env(TMPDIR)
    }

    return "$tmpdir/0.[pid].[expr rand()]"
}


proc RevertFile {{force 0}} {
    global current_filename

    if {[GetFilename] != ""} {
        if {!$force && [CheckIfModified]} {
            if {[ModificationCheck]} return
	}

        set current_filename [FollowLink $current_filename]

        if {[file type $current_filename] == "directory"} {
            OpenDirectory $current_filename
            cd $current_filename
        } else {
            OpenFile $current_filename
        }
    }
}


proc Execute {fw {arg ""}} {
    global has_focus
    # range: either what is swept with B2, or the selection (if the mouse is inside it)
    # or the word under the cursor:

    set range [$fw tag ranges b2sweep]

    if {$range == ""} {
        set range [$fw tag ranges sel]

        if {$range == "" || [lsearch -exact [$fw tag names current] sel] == -1} {
            set range ""
        }
    }

    if {$range == ""} {
        set cmd [GetWordUnderCursor $fw]
    } else {
        set cmd [$fw get [lindex $range 0] [lindex $range 1]]
    }

    RemoveTaggedRange $fw b2sweep
    set cmd [string trim $cmd]

    if {$cmd == ""} return

    if {$arg != ""} {
        append cmd " $arg"
    }

    if {$fw == ".tag" || $has_focus || [catch [list send MA-registry FocusExecute "{$cmd}"] result] \
        || !$result} {
        DoExecute $cmd
    }
}


proc FocusExecute {cmd} {
    global focus_window
    
    if {$focus_window != ""} {
        .t insert end "focus execute: $focus_window : $cmd\n"

        if {![catch [list send $focus_window DoExecute "{$cmd}"]]} {
            return 1
        }
    }

    return 0
}


proc DoExecute {cmd} {
    global command_table command_arguments shell win_mode
    set sel [GetEffectiveSelection .t]
    set tsel 1

    if {$sel == ""} {
        set sel [GetEffectiveSelection .tag]
        set tsel 0
    }

    switch -regexp -- $cmd {
        {^$} return
        {^\|} {
            if {$sel == ""} {
                set start 1.0
                set end end
            } else {
                set start [lindex $sel 0]
                set end [lindex $sel 1]
            }

            set input [.t get $start $end]                
            set cmd [string range $cmd 1 [string length $cmd]]
            set outf [TempFile]
            Flash blue
            set output ""
            
            if {[catch [list exec $shell -c $cmd << $input > $outf] result]} {
                LogInWindow $result 1
                return
            } else {
                .t delete $start $end
                .t mark set insert $start

                if {[file exists $outf]} {
                    lassign [ReadFile $outf] output
                    file delete -force $outf
                }
            }

            Insert $output
            return
        }
        {^<} {
            set outf [TempFile]
            set cmd [string range $cmd 1 [string length $cmd]]
            set output ""
            Flash blue
            
            if {[catch [list exec $shell -c $cmd < /dev/null > $outf] result]} {
                LogInWindow $result 1
            } else {
                if {[file exists $outf]} {
                    lassign [ReadFile $outf] output
                    file delete -force $outf
                }
            }

            if {$sel != "" && $tsel} {eval .t delete $sel}

            Insert $output
            return
        }
        {^>} {
            if {$sel == ""} {
                set input [.t get 1.0 end]
            } else {
                set input [.t get [lindex $sel 0] [lindex $sel 1]]
            }

            set cmd [string range $cmd 1 [string length $cmd]]
            set inf [TempFile]
            set f [open $inf w]
            puts -nonewline $f $input
            close $f
            InvokeExternalCommandInWindow $cmd $inf
            return
        }
    }

    if {$cmd == ""} return

    foreach opr $command_table {
        set command_arguments [regexp -inline -- [lindex $opr 0] $cmd]

        if {$command_arguments != ""} {
            eval [lindex $opr 1]
            return
        }
    }

    set cmd1 [FindExecutable $cmd]

    if {$cmd1 == ""} return

    InvokeExternalCommandInWindow $cmd1
    AddToHistory $cmd
}


proc AddToHistory {cmd} {
    global history_file

    if {$history_file != ""} {
        set f [open $history_file a]
        puts $f $cmd
        close $f
        file attributes $history_file -permissions go-rw
    }
}


proc Scrolling {start end} {
    global sbar
    set w [winfo width .s]
    set h [winfo height .s]
    set y1 [expr $h * $start]
    set y2 [expr $h * $end]

    if {($y2 - $y1) < 3} {set y2 [expr $y1 + 3]}

    .s coords $sbar 0 $y1 $w $y2
}


proc ScrollUp {p} {
    .t yview scroll [expr -$p] pixels
}


proc ScrollDown {p} {
    .t yview scroll $p pixels
}


proc ScrollTo {p} {
     set h [winfo height .s]
     set f [expr double($p) / $h]
     .t yview moveto $f
}


proc Replace {arg} {
    set sel [GetEffectiveSelection .t]

    if {$sel == ""} {
        set start 1.0
        set end end
    } else {
        set start [lindex $sel 0]
        set end [lindex $sel 1]
    }

    if {![regexp {^\s*"([^"]+)"\s*"([^"]*)"\s*$} $arg _ from to]} {
        if {![regexp {^\s*([^ ]+)\s+(.+)$} $arg _ from to]} {
            Flash red
            return
        }
    }

    while 1 {
        set p1 [.t search -regexp -count len -- $from $start $end]

        if {$p1 == ""} break        

        regsub -line -- $from [.t get $p1 "$p1 + $len chars"] $to rpl
        .t replace $p1 [.t index "$p1 + $len chars"] $rpl
        set start [.t index "$p1 + [string length $rpl] chars"]
    }
}


proc GetSelection {{fw ""}} {
    if {$fw == ""} {
	set fw [GetFocusWidget]
    }

    set range [GetEffectiveSelection $fw]

    if {$range == ""} {
	return [$fw get {insert linestart} {insert lineend}]
    }

    return [$fw get [lindex $range 0] [lindex $range 1]]
}


proc GetEffectiveSelection {w} {
    if {$w == [focus -displayof .]} {
        return [$w tag ranges sel]
    }

    return [$w tag ranges pseudosel]
}


proc GetSelectedLines {} {
    set range [GetEffectiveSelection .t]

    if {$range == ""} {
	return [.t get {insert linestart} {insert lineend}]
    }

    return [.t get "[lindex $range 0] linestart" "[lindex $range 1] lineend"]
}


proc RemoveSelection {{fw ""}} {
    set rfw [focus -displayof .]

    if {$fw == ""} {
        set fw $rfw
    }

    foreach tag {sel pseudosel b2sweep b3sweep} {
        set old [$fw tag ranges $tag]
	
        if {$old != ""} {
            eval $fw tag remove $tag $old
        }   
    }

    return $fw
}


proc RemovePseudoSelection {fw} {
    foreach tag {pseudosel b2sweep b3sweep} {
        set old [$fw tag ranges $tag]

        if {$old != ""} {
            eval $fw tag remove $tag $old
        }
    }
}


proc RestoreSelection {fw} {
    set old [$fw tag ranges sel]

    if {$old == ""} {
        set old [$fw tag ranges pseudosel]

        if {$old != ""} {
            eval $fw tag add sel $old
            eval $fw tag remove pseudosel $old
        }
    }
}


proc SaveSelection {fw} {
    set old [$fw tag ranges sel]

    if {$old != ""} {
        eval $fw tag add pseudosel $old
    }
}


proc SetTaggedRange {fw tag from to} {
    set old [$fw tag ranges $tag]
    
    if {$old != ""} {
        eval $fw tag remove $tag $old
    }

    if {[$fw compare $from > $to]} {
        set tmp $from
        set from $to
        set to $tmp
    }

    $fw tag add $tag $from $to
}


proc RemoveTaggedRange {fw tag} {
    set old [$fw tag ranges $tag]
    
    if {$old != ""} {
        eval $fw tag remove $tag $old
    }
}


proc ChildPids {ppid} {
    if {[catch [list open "| pgrep -P $ppid"] f]} {return {}}

    set cpids {}

    while {[gets $f line] > 0} {
        lappend cpids $line
    }

    catch [list close $f]
    return $cpids
}


proc EnterWinMode {{cmd ""}} {
    global win_mode executing_pids win_file exec_prefix env shell scroll

    if {$cmd == ""} {set cmd $shell}

    if {[catch [list open "| ${exec_prefix}pty $cmd 2>@1" r+] win_file]} {
	Append "\nCommand failed: $win_file\n"
        return
    }

    set win_mode 1
    ToggleScroll 1
    ToggleWrapMode char
    eval lappend executing_pids [ChildPids [pid $win_file]]
    fconfigure $win_file -blocking 0
    fileevent $win_file readable [list LogOutput $win_file]
    .t configure -insertofftime 300

    bind .t <Return> {
        global win_file win_mode password_input password_char

        # win-mode may be off, when process was killed
        if {$win_mode} {
            if {[catch {.t index win_insert_point} ip]} {
                set ip 1.0
            }

            if {[.t compare [.t index insert] > $ip]} {
                set text [.t get $ip "insert lineend"]
            } else {
                set text [.t get "insert linestart" "insert lineend"]
            }

            .t mark set insert "end - 1 chars"

            if {$password_input != ""} {
                regsub "$password_char+" $text $password_input rtext
                set password_input ""
            } else {
                set rtext $text
            }

            puts $win_file $rtext
            flush $win_file
            AddToHistory $text
            Insert "\n"
            .t mark set win_insert_point insert
            break
        }
    }

    bind .t <KeyPress> {
        global password_input password_char
        set char %A
        TakeFocus

        if {[string is print -strict $char]} {
            set txt [.t get "insert linestart" insert]
    
            if {[regexp -nocase {pass(word|phrase).*:} $txt]} {
                Insert $password_char
                append password_input $char
                break
            }
        }
    }

    bind .t <BackSpace> {
        global password_input password_char
        TakeFocus
        set txt [.t get "insert linestart" insert]
    
        if {[regexp -nocase "pass(word|phrase).*:\\s*(${password_char}*)\$" \
            $txt _ _ pw]} {
            if {[string length $pw] >= 1} {
                .t delete "insert - 1 chars"
                set password_input [string range $password_input 0 end-1]
                break
            } else break
        }
    }
}


proc PolishCompletion {file {qp ""}} {
    set slash ""

    if {[file exists $file]} {
        if {[file type $file] == "directory" && [string index $file end] != "/"} {
            set slash "/"
        }
    }

    if {$qp == "" && [string first " " $file] != -1 && [string index $file 0] != "'"} {
        set file "'$file'"
    } else {
        set file "$file$slash"
    }

    return $file
}


proc FilenameCompletion {} {
    set fw [GetFocusWidget]

    set qp1 [$fw search -backwards "'" insert "insert linestart"]
    set qp2 [$fw search "'" insert "insert lineend"]

    if {$qp1 != "" && $qp2 != ""} {
        set ixs [list [$fw index "$qp1 + 1 chars"] [$fw index "$qp2"]]
    } else {
        set ixs [GetWordUnderIndex $fw insert]
    }

    if {$ixs == ""} return

    set name [eval $fw get $ixs]
    set prefix ""

    if {[regexp {^([`"'\(\[\{<>|;:,=]+)(.+)$} $name _ prefix name2]} {
        set name $name2
    }

    set files [glob -nocomplain -- "$name*"]
    set flen [llength $files]
    set nlen [string length "$name"]

    if {$flen == 0} return

    if {$flen > 1} {
        set i [string length $name]
        set scan 1
        set f0 [lindex $files 0]

        while {$scan} {
            set c [string index $f0 $i]

            foreach f $files {
                # includes f0, but will succeed
                if {[string index $f $i] != $c} {
                    set scan 0
                    incr i -1
                    break
                }
            } 

            if {$scan} { incr i }
        }
    
        if {$i > $nlen} {
            set name2 [PolishCompletion [string range $f0 0 $i] $qp1]
            $fw mark set insert [lindex $ixs 1]
            $fw replace [lindex $ixs 0] [lindex $ixs 1] "$prefix$name2"
            return
        }

        LogInWindow "Completions:\n[FormatColumnar $files]" 1
        return
    }
    
    set file [PolishCompletion [lindex $files 0] $qp1]
    $fw mark set insert [lindex $ixs 1]
    $fw replace [lindex $ixs 0] [lindex $ixs 1] "$prefix$file"
}


proc MatchDelimitedForward {start {fw ""}} {
    if {$fw == ""} {
        set fw [GetFocusWidget]
    }

    set i 0
    set p $start
    set done 0
    set ok 0
    set quotes ""
    set c1 [$fw get $start]

    if {$c1 == "\"" || $c1 == "'"} {
        set quotes $c1
    }

    while {!$done} {
        set p [$fw search -regexp {\[|\]|\(|\)|\{|\}|"|'} $p end]

        if {$p == ""} {
            set p end
            break
        }

        set c [$fw get $p]
        # puts "p=$p, i=$i, c=$c"; # XXX

        switch -glob -- $c {
            "(" { set stack($i) ")"; incr i }
            "\\[" { set stack($i) "\]"; incr i }
            "\{" { set stack($i) "\}"; incr i }
            "[\"']" {
                while 1 {
                    set p2 [$fw search $c "$p + 1 chars" end]
                    
                    if {$p2 == ""} {
                        set done 1
                        break                    
                    }

                    set p $p2
                    
                    if {[$fw get "$p - 1 chars"] != "\\"} {
                        if {$quotes != ""} {
                            set done 1
                            set ok 1
                        }

                        break
                    }
                }
            }
            default {
                if {$c == $stack([expr $i - 1])} {
                    incr i -1

                    if {$i == 0} { 
                        set done 1 
                        set ok 1
                    }
                } else break
            }
        }

        set p [$fw index "$p + 1 chars"]
    }

    if {$done} {
        return [list 1 $start $p]
    }

    return [list 0 $start $p]
}


proc MatchDelimitedBackwards {start {fw ""}} {
    if {$fw == ""} {
        set fw [GetFocusWidget]
    }

    set i 0
    set p $start
    set done 0
    set ok 0

    while {!$done} {
        set p [$fw search -regexp -backwards {\[|\]|\(|\)|\{|\}|"} $p 1.0]

        if {$p == ""} {
            set p 1.0
            break
        }

        set c [$fw get $p]
        # puts "p=$p, i=$i, c=$c"; # XXX

        switch -- $c {
            ")" { set stack($i) "("; incr i }
            "\]" { set stack($i) "\["; incr i }
            "\}" { set stack($i) "\{"; incr i }
            "\"" {
                while 1 {
                    set p2 [$fw search -backwards "\"" $p 1.0]
                    
                    if {$p2 == ""} {
                        set done 1
                        break                    
                    }

                    set p $p2

                    if {[$fw get "$p - 1 chars"] != "\\"} break
                }
            }
            default {
                # this is to catch a strange situation where fast typing can
                # lead to "insert" being _before_ the currently added closing delimiter
                # (a bug in Tcl/Tk, perhaps, or a race condition)
                if {$i == 0} break

                if {$c == $stack([expr $i - 1])} {
                    incr i -1

                    if {$i == 0} {
                        set done 1
                        set ok 1
                        break
                    }
                } else break
            }
        }
    }

    if {$done} {
        return [list 1 $p $start]
    }

    return [list 0 $p $start]
}


proc FlashParenRange {fw ok start end} {
    global flashed_range_id valid_match_background invalid_match_background

    if {$ok} {
        set bg $valid_match_background
    } else {
        set bg $invalid_match_background
    }

    RemoveTaggedRange $fw flashed_range
    $fw tag configure flashed_range -background $bg
    $fw tag add flashed_range $start "$start + 1 chars" "$end - 1 chars" $end
    after cancel $flashed_range_id
    set flashed_range_id [after 1000 [list RemoveTaggedRange $fw flashed_range]]
}


proc ExecButtonRelease {} {
    global b1_down b2_abort b2_with_arg cut_unmodified
    set fw [GetFocusWidget]

    if {$b2_abort} {
        set b2_abort 0
        return
    }

    if {$b1_down} {
        if {$fw == ".t" && [.t edit modified] == 0} {
            lassign [.t tag ranges sel] cut_unmodified
        }

        tk_textCut $fw
        return
    }

    Execute $fw $b2_with_arg
    set b2_with_arg ""
}


proc ExecButtonPress {fw x y} {
    global b2_down b2_abort b2_start
    set b2_down 1
    set b2_abort 0
    set b2_start ""
    
    if {![catch [list $fw index "@$x,$y"] result]} {
        set b2_start $result
    }

    RecordPosition
}


proc UpdateSelectionOnClick {fw} {
    # drop selection, unless click is inside it
    if {[lsearch -exact [$fw tag names current] sel] == -1} {
        RemoveSelection $fw
    }
}


text .tag -wrap char -undo 1 -height 1
canvas .s -width $sbar_width
text .t -wrap none -undo 1 -yscrollcommand Scrolling
pack .tag -side top -fill x
pack .s -fill y -side left
pack .t -fill both -expand 1
set sbar [.s create rectangle 0 0 0 0]

wm protocol . WM_DELETE_WINDOW Terminate


# key events

DefineKey <KeyPress> {TakeFocus; set cut_unmodified ""}
DefineKey <Control-plus> { ResizeFont 1 }
DefineKey <Control-minus> { ResizeFont -1 }
DefineKey <Control-c> { tk_textCopy [GetFocusWidget]; break }
DefineKey <Control-x> { tk_textCut [GetFocusWidget]; break }
DefineKey <Control-v> { PasteSelection [GetFocusWidget]; break }
DefineKey <Delete> { KillExecuting; break }
DefineKey <Control-f> { FilenameCompletion; break }

DefineKey <Return> {
    TakeFocus
    set fw [GetFocusWidget]

    if {$fw == ".t" && $current_translation == "crnl"} {
        if {[.t get "insert - 1 chars"] == "\r"} {
            Insert "\n"
        } else {
            Insert "\r\n"
        }

        break
    }
}

DefineKey <Control-s> SaveChanges
DefineKey <Home> { Top; break }
DefineKey <End> { Bottom; break }

DefineKey <Control-u> {
    set fw [GetFocusWidget]
    RemoveSelection $fw
    $fw tag add sel "insert linestart" insert
    tk_textCut $fw
    break
}

DefineKey <Control-k> {
    set fw [GetFocusWidget]
    RemoveSelection $fw

    if {[.t get insert] == "\n"} {
        $fw tag add sel insert "insert + 1 lines linestart"
    } else {
        $fw tag add sel insert "insert lineend"
    }

    tk_textCut $fw
    break
}

DefineKey <Control-w> {
    set fw [GetFocusWidget]
    set i [$fw search -regexp -backwards {\m\w*} insert 1.0]

    if {$i != ""} {
        RemoveSelection $fw
        $fw tag add sel $i insert
        tk_textCut $fw
    }

    break
}

DefineKey <Tab> { SmartIndent; break }
DefineKey <Control-Tab> { Insert "\t"; break }

DefineKey <Control-KeyPress-1> {
    if {[GetFocusWidget] == ".t"} {
        focus .tag
    } else {focus .t}
}

DefineKey <Control-KeyPress-2> {
    set fw [GetFocusWidget]
    set rng [GetEffectiveSelection $fw]

    if {$rng != ""} {
        RemoveSelection $fw
        eval SetTaggedRange $fw b2sweep $rng
        Execute $fw
    } else {
        set ixs [GetWordUnderIndex $fw insert]

        if {$ixs != ""} {
            eval SetTaggedRange $fw b2sweep $ixs
            Execute $fw
        }
    }
}

DefineKey <Control-KeyPress-3> {
    set fw [GetFocusWidget]
    set rng [GetEffectiveSelection $fw]

    if {$rng != ""} {
        RemoveSelection $fw
        eval SetTaggedRange [GetFocusWidget] b3sweep $rng
        Acquire
    } else {
        set ixs [GetWordUnderIndex $fw insert]

        if {$ixs != ""} {
            eval SetTaggedRange $fw b3sweep $ixs
            Acquire
        }
    }
}

DefineKey <KeyRelease> {
    if {[string first "%A" ")\]\}"] != -1} {
        set fw [GetFocusWidget]
        set result [MatchDelimitedBackwards [$fw index insert] $fw]
        eval FlashParenRange $fw $result
    }
}

bind .t <Prior> {
    ScrollUp [expr [winfo height .t] / 2]
    break
}

bind .t <Next> {
    ScrollDown [expr [winfo height .t] / 2]
    break
}

bind .tag <KeyRelease> { 
    set old [.tag cget -height]
    set new [.tag count -displaylines 1.0 end]

    if {$old != $new} {
        .tag configure -height $new
    }

    .tag see 1.0
    set last_del_attempt 0
}

DefineKey <Escape> {
    set fw [GetFocusWidget]
    set sel [$fw tag ranges sel]

    if {$sel != ""} {
        tk_textCut $fw
    } else {
        $fw tag add sel $last_mouse_index insert
    }
}


# mouse events

DefineKey <Double-ButtonPress-1> {
    set fw [GetFocusWidget]
    TakeFocus

    if {![catch [list $fw index "@%x,%y"] ind]} {
        set c [$fw get $ind]
        RecordPosition

        if {[string first $c "\{(\[\"'"] != -1} {
            set result [MatchDelimitedForward $ind $fw]
        
            if {[lindex $result 0]} {
                RemoveSelection $fw
                $fw tag add sel "[lindex $result 1] + 1 chars" "[lindex $result 2] - 1 chars"
                $fw mark set insert "[lindex $result 1] + 1 chars"
                break
            }
        } elseif {[string first $c "\})\]"] != -1} {
            set result [MatchDelimitedBackwards "$ind + 1 chars" $fw]
        
            if {[lindex $result 0]} {
                RemoveSelection $fw
                $fw tag add sel "[lindex $result 1] + 1 chars" "[lindex $result 2] - 1 chars"
                $fw mark set insert "[lindex $result 2] - 1 chars"
                break
            }
        }

        if {[regexp {\.0$} $ind]} {
            RemoveSelection $fw
            $fw tag add sel $ind "$ind lineend + 1 chars"
            break
        } else {
            lassign [$fw dlineinfo "@%x,%y"] px _ pw

            if {%x > [expr $px + $pw]} {
                set p [$fw index "@%x,%y"]
                $fw tag add sel "$p linestart" "$p lineend + 1 chars"
                break
            }
        }
    }
}

DefineKey <ButtonPress-1> {
    set b1_down 1
    set fw [GetFocusWidget]
    RecordPosition
    TakeFocus

    if {$b2_down} {
        set fw .t
        set range [GetEffectiveSelection .t]

        if {$range == ""} {     
            set fw .tag
            set range [GetEffectiveSelection .tag]
        }
            
        if {$range != ""} {
            set txt [$fw get [lindex $range 0] [lindex $range 1]]
            set b2_with_arg [regsub -all {\s+} $txt " "]
            break
        }
    } else {
        RemovePseudoSelection %W
    }
}

DefineKey <ButtonRelease-1> {
    set b1_down 0
}

DefineKey <ButtonPress-2> {
    ExecButtonPress %W %x %y
}

DefineKey <ButtonRelease-2> {
    set b2_down 0
    ExecButtonRelease
    break
}

DefineKey <Shift-ButtonPress-3> {
    UpdateSelectionOnClick %W
    ExecButtonPress %W %x %y
}

DefineKey <Shift-ButtonRelease-3> {
    set b2_down 0
    ExecButtonRelease
    break
}

DefineKey <ButtonPress-3> {
    UpdateSelectionOnClick %W
    set b3_down 1
    set b3_start ""
    
    if {![catch {%W index "@%x,%y"} result]} {
        set b3_start $result
    }

    RecordPosition
}

DefineKey <ButtonRelease-3> {
    set b3_down 0

    if {$b1_down} {
        set fw [GetFocusWidget]
        set p [$fw index insert]
        PasteSelection $fw
        RemoveTaggedRange %W b3sweep

        if {$fw == ".t" && $p == $cut_unmodified} {
            Unmodified
        }

        break
    }

    if {$b2_down} {
        set b2_abort 1
        set b2_start ""
        RemoveTaggedRange %W b2sweep
        RemoveTaggedRange %W b3sweep
        break
    }

    Acquire 
    break
}

bind .s <1> { ScrollUp %y }
bind .s <ButtonPress-2> { set b2_down 1; ScrollTo %y }
bind .s <ButtonRelease-2> { set b2_down 0 }
bind .s <Shift-ButtonPress-3> { set b2_down 1; ScrollTo %y }
bind .s <Shift-ButtonRelease-3> { set b2_down 0 }
bind .s <3> { ScrollDown %y }

bind .s <Motion> {
    if {$b2_down} {
        ScrollTo %y
    }
}

DefineKey <Motion> {
    if {$b2_down} {
        set p "@%x,%y"

        if {![catch [list %W index $p] result]} {
            if {$b2_start != "" && $b2_start != $result} {
                SetTaggedRange %W b2sweep $b2_start $result
            }
        }

        break
    } elseif {$b3_down} {
        set p "@%x,%y"

        if {![catch [list %W index $p] result]} {
            if {$b3_start != "" && $b3_start != $result} {
                SetTaggedRange %W b3sweep $b3_start $result
            }
        }

        break
    }
}


DefineKey <<Selection>> { 
    set fw %W
    set sel [$fw tag ranges sel]

    if {$sel != ""} { 
        RemovePseudoSelection $fw
    }
}

DefineKey <Enter> { RestoreSelection %W }
DefineKey <Leave> { SaveSelection %W }

bind .t <<Modified>> { 
    set f [.t edit modified]
    set last_del_attempt 0

    if {$current_filename != ""} { 
        if {$f} {
            set m $tag_marker_dirty
        } else {
            set m $tag_marker_clean
        }

        SetTagMarker $m
    }
}

proc RelayoutTag {} {
    set lines [.tag count -displaylines 1.0 end]
    .tag configure -height $lines
}

bind .tag <Configure> {
    RelayoutTag
    ScrollToBottom
}

set mapped 0

# not sure about this one
bind .t <Map> {
    if {!$withdrawn && !$mapped} {
        WarpToIndex .t 1.0
    }

    set mapped 1
}


# initialization

if {[file exists $rcfile]} { source $rcfile }

set clear_filename 0
set post_eval ""

for {set i 0} {$i < $argc} {incr i} {
    set arg [lindex $argv $i]

    switch -- $arg {
        "-cd" {
            incr i
            cd [lindex $argv $i]
        }
        "-who" {puts [tk appname]}
	"-eval" { 
	    incr i
	    eval [lindex $argv $i]
	}
	"-background" { 
	    incr i
	    set current_background [lindex $argv $i]
	}
	"-foreground" { 
	    incr i
	    set current_foreground [lindex $argv $i]
	}
	"-fixedfontname" { 
	    incr i
	    set current_fixed_font [lindex $argv $i]
	}
	"-variablefontname" { 
	    incr i
	    set current_variable_font [lindex $argv $i]
	}
        "-font" {
            incr i
            
            switch [lindex $argv $i] {
                fixed { set current_font $current_fixed_font }
                variable { set current_font $current_variable_font }
                default {
                    puts stderr "invalid font"
                    exit 1
                }
            }        
        }
	"-fontsize" { 
	    incr i
	    set current_font_size [lindex $argv $i]
	}
	"-fontstyle" { 
	    incr i
	    set current_font_style [lindex $argv $i]
	}
	"-execute" {
	    incr i
	    source [lindex $argv $i]
	}
	"-unnamed" { 
	    set clear_filename 1
	}
	"-file-encoding" {
	    incr i
	    set file_encoding [lindex $argv $i]
	}
	"-file-translation" {
	    incr i
	    set file_translation [lindex $argv $i]
	}
	"-post-eval" {
	    incr i
	    lappend post_eval [lindex $argv $i]
	}
	"-stdin" {
	    .t insert 1.0 [read stdin]
	}
	"-directory" {
	    incr i
	    lappend post_eval [list OpenDirectory [lindex $argv $i]]
	}
	"-address" {
	    incr i
	    set dest_address [lindex $argv $i]
	}
	"-tag" {
	    incr i
	    set initial_tag [lindex $argv $i]
	}
        "-withdrawn" {set withdrawn 1}
        "-registry" StartRegistry
        "-scroll" ToggleScroll
        "-win" {
            incr i

            if {$i >= $argc} {
                set cmd $shell
            } else {              
                set cmd [lrange $argv $i [llength $argv]]
            }

            set name [file rootname [file tail [lindex $cmd 0]]]
            set dir [pwd]
            set initial_tag "$dir/-$name New Kill Del Cut Paste Snarf Send Look Font Wrap Scroll | "
            lappend post_eval [list EnterWinMode $cmd]
            set i $argc
        }
	"--" {}
	default { 
	    set current_filename [CanonicalFilename [lindex $argv $i]]
	}
    }
}

ConfigureWindow 0

if {$initial_tag != ""} {
    .tag insert 1.0 $tag_marker_clean tagmark
    SetTag $initial_tag
}

if {$current_filename != ""} { 
    set current_filename [FollowLink $current_filename]

    if {[file exists $current_filename]} {
        if {[file type $current_filename] == "directory"} {
            OpenDirectory $current_filename
        } else {
            OpenFile $current_filename
        }
    }

    if {$clear_filename} { 
	set current_filename ""
        UpdateTag
    }
}

if {$dest_address != ""} {
    GotoBodyAddress $dest_address
} else {
    .t mark set insert 1.0
}

if {$withdrawn} {
    wm withdraw .
}

if {$post_eval != ""} {
    foreach cmd $post_eval {
        eval $cmd
    }
}

set env(MA_LABEL) $current_filename
TakeFocus
RelayoutTag
