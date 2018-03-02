# basic git(1) interface - log window


set git_log_len 25
set git_enable_stats 1
set git_root [Git_FindRoot]


if {$git_root != ""} {
    tk appname $git_root+GitLog
}


proc Git_Update {} {
    ActivateWindow
    Git_Log
}


proc Git_Log {} {
    global git_log_len git_enable_stats
    .t delete 1.0 end
    set rev [exec git rev-parse --short HEAD]
    set args {--graph}

    if {$git_enable_stats} {lappend args "--stat"}

    regexp {\* (\S+)} [exec git branch] _ b
    Insert "\nGit log [pwd]: branch: $b\n\n"
    set txt [exec git log -$git_log_len {*}$args]
    Insert $txt
    Insert "\n\nMore\n\n"
    Top
}


DefineCommand {^Update$} Git_Log

DefineCommand {^More$} {
    global git_log_len
    incr git_log_len 50
    Git_Log
}

DefineCommand {^Stat$} {
    global git_enable_stats
    set git_enable_stats [expr !$git_enable_stats]
    Git_Log
}
