# basic git(1) interface - status/branch window


set git_status_mode diff
set git_root [Git_FindRoot]
set git_hook ""
set git_branch_op checkout
set git_mode status


if {[info exists env(HERE)]} {
    set git_hook $git_lib_dir/post-commit

    if {![file exists $git_hook]} {
        set git_hook ""
    }
}

if {$git_root != ""} {
    tk appname $git_root/+Git
}


proc Git_UpdateBranch {} {
    global git_mode

    if {$git_mode == "branch"} {
        ActivateWindow
        Git_Branch
    }
}


proc Git_UpdateStatus {} {
    global git_root git_mode

    if {$git_mode == "status"} {
        ActivateWindow
        Git_Status
        catch [list send $git_root/+GitLog Git_Update]
    }
}


# invoked externally to update
proc Git_Update {} {
    Git_UpdateStatus
    Git_UpdateBranch
}


proc Git_Status {} {
    global git_status_mode git_root git_hook
    .t delete 1.0 end

    if {[catch {exec git rev-parse --short HEAD} rev]} {
        set rev "<initial>"
    }

    if {![regexp {\* (\S+)} [exec git branch] _ b]} {
        set b "<none>"
    }

    Insert "\nGit status [pwd]:\nbranch: $b, rev: $rev\n\n"
    set f [open "|git status --porcelain"]
    
    while {[gets $f line] >= 0} {
        if {[regexp {^(..)\s+(.+)$} $line _ status files]} {
            set handle " diff"
    
            if {$git_status_mode == "revert"} {
                set handle revert
            }

            switch -exact $status {
                "??" {set handle "  add"}
                "M " {set handle "reset"}
                "A " {set handle "unadd"}
            }

            Insert "$status $handle:$files\n"
        }
    }

    close $f
    .t mark set insert 1.0
    Top
    Unmodified

    if {![file exists $git_root/.git/hooks/post-commit]} {
        file link -symbolic $git_root/.git/hooks/post-commit \
            $git_hook
    }
}


proc Git_Branch {} {
    global git_branch_op 
    .t delete 1.0 end
    regexp {\* (\S+)} [exec git branch] _ cb

    if {$git_branch_op == "merge"} {
        set txt [exec git branch -a --no-merged $cb]
    } else {
        set txt [exec git branch -a]
    }

    set rev [exec git rev-parse --short HEAD]
    Insert "\nGit branch [pwd]: $cb, rev: $rev\n\n"
    
    foreach b [split $txt "\n"] {
        if {[regexp {^([* ])\s(\S+)$} $b _ current name]} {
            if {$current == "*"} {
                Insert "* $name\n"
            } elseif {[regexp {^remotes/} $name]} {
                Insert "  checkout:$name\n"
            } else {
                Insert "  $git_branch_op:$name\n"
            }
        }
    }

    Top
    Unmodified
}


proc Git_FName {str} {
    if {[regexp {^"([^"]+)"$} $str _ newname]} {
        return $newname
    }

    return $str
}


proc Git_UpdateStatus args {
    global git_status_mode git_branch_op git_mode

    if {$git_mode == "branch"} {
        set git_branch_op checkout
        UpdateCommand CO Merge
        Git_Branch
    } else {
        set git_status_mode diff
        Git_Status
    }
}

AddToHook revert_hook Git_UpdateStatus


DefineCommand {^Log$} {
    global git_root git_lib_dir

    if {[catch [list send $git_root/+GitLog Git_Update]]} {
        Ma -cd $git_root -execute $git_lib_dir/git-log.tcl \
            -post-eval "Git_Log" -temporary \
            -tag "$git_root/+GitLog New Del Cut Paste Snarf Get Look Stat | "
    }    
}


DefineCommand {^Amend$} {
    global exec_prefix
    exec env GIT_EDITOR=$exec_prefix/ma git commit --amend &
}


DefineCommand {^Commit$} {
    global exec_prefix
    exec env GIT_EDITOR=$exec_prefix/ma git commit &
}


DefineCommand {^CommitAll$} {
    global exec_prefix
    exec env GIT_EDITOR=$exec_prefix/ma git commit -a &
}


DefineCommand {^Branch$} {
    global git_mode git_branch_op
    set git_mode "branch"
    set git_branch_op checkout
    UpdateCommand Status Branch
    UpdateCommand Merge
    UpdateCommand Push
    UpdateCommand Pull
    Git_Branch
}


DefineCommand {^Status$} {
    global env git_mode
    set git_mode "status"
    UpdateCommand Branch Status 
    UpdateCommand "" Merge
    UpdateCommand "" Push
    UpdateCommand "" Pull
    Git_Status
}


DefineCommand {^Revert$} {
    global git_status_mode
    set git_status_mode revert
    UpdateCommand Diff Revert
    Git_Status
}


DefineCommand {^Diff$} {
    global git_status_mode
    set git_status_mode diff
    UpdateCommand Revert Diff
    Git_Status
}


DefinePlumbing {^diff:(.*)$} {
    global env
    set fname [Git_FName [GetArg 1]]
    set dir [GetFileDir]
    Ma -cd $dir -execute $env(HERE)/lib/ma/git-diff.tcl \
        -post-eval "Git_Diff {$fname} 1" -temporary \
        -tag "$dir/+Diff New Del Cut Paste Snarf Look Font Commit Add Invert | " 
    return 1
}


DefinePlumbing {^reset:(.*)$} {
    global env
    set fname [Git_FName [GetArg 1]]
    exec git reset -q -- $fname
    Git_Status
    return 1
}


DefinePlumbing {^revert:(.*)$} {
    global env
    set fname [Git_FName [GetArg 1]]
    exec git checkout -- $fname
    Git_Status
    return 1
}


DefinePlumbing {^add:(.*)$} {
    global env
    set fname [Git_FName [GetArg 1]]
    exec git add -- $fname
    Git_Status
    return 1
}


DefinePlumbing {^unadd:(.*)$} {
    global env
    set fname [Git_FName [GetArg 1]]
    exec git reset -q -- $fname
    Git_Status
    return 1
}


DefineCommand {^Push$} {
    regexp {\* (\S+)} [exec git branch] _ b    
    InvokeExternalCommandInWindow "git push origin $b" 
    Flash blue
}


DefineCommand {^Pull$} {
    regexp {\* (\S+)} [exec git branch] _ b    
    InvokeExternalCommandInWindow "git pull origin $b"
    Flash blue
}


DefineCommand {^Merge$} {
    global git_branch_op
    UpdateCommand CO Merge
    set git_branch_op merge
    Git_Branch
}


DefineCommand {^CO$} {
    global git_branch_op
    UpdateCommand Merge CO
    set git_branch_op checkout
    Git_Branch
}


DefinePlumbing {^checkout:(.*)$} {
    set name [GetArg 1]
    InvokeExternalCommandInWindow "git checkout $name"
    after 500 Git_Branch
}


DefinePlumbing {^merge:(.*)$} {
    set name [GetArg 1]
    InvokeExternalCommandInWindow "git merge $name"
    after 500 Git_Branch
}
