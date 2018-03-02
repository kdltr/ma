# loader for minimal git(1) interface


if {![info exists git_lib_dir]} {
    set git_lib_dir $env(HERE)/lib/ma
}


proc Git_FindRoot {} {
    set dir [pwd]

    while {![file exists $dir/.git]} {
        if {$dir == "/"} {return ""}

        set dir [file dirname $dir]
    }

    return $dir
}


DefineCommand {^Git$} {
    global git_lib_dir
    set dir [Git_FindRoot]

    if {$dir == ""} return

    if {![catch [list send $dir/+Git Git_Update]]} return

    Ma -cd $dir -execute $git_lib_dir/git-status.tcl -post-eval \
        Git_Status -temporary \
        -tag "$dir/+Git New Del Cut Paste Snarf Look Update Log Branch Commit CommitAll Amend Revert | "
}
