# gopher links and search
#
# Patterns: ⊳...⊲
#           gopher://...


DefinePlumbing {^⊳([^:=/?]+)(:(\d+))?(=(.))?(/(.*))?⊲$} {
    global exec_prefix browser
    set host [GetArg 1]
    set port 70
    set type 1
    set sel [GetArg 7]

    if {[GetArg 2] != ""} {set port [GetArg 3]}

    if {[GetArg 4] != ""} {set type [GetArg 5]}

    if {[regexp {^URL:(.+)$} $sel _ url]} {
        Flash blue
        exec $browser $url & 
        return 1
    }

    exec ${exec_prefix}gopher -type $type $sel $host $port &
    return 1
}


DefinePlumbing {^gopher://([^/:]+)(:(\d+))?(/(.))?(.*)?$} {
    global exec_prefix
    set host [GetArg 1]
    set type 1
    set port 70
    set sel [GetArg 6]

    if {[GetArg 4] != ""} {
        set type [GetArg 5]

        if {$type == "/"} {
            set sel "/$sel"
            set type 1
        }
    }

    if {[GetArg 2] != ""} {set port [GetArg 3]}

    exec ${exec_prefix}gopher -type $type $sel $host $port &
    return 1
}


# search
DefinePlumbing {^⊳([^:=/?]+)(:(\d+))?\?([^?]+)\?(.*)⊲$} {
    global exec_prefix
    set host [GetArg 1]
    set port 70
    set sel [GetArg 4]
    set str [GetArg 5]

    if {[GetArg 2] != ""} {set port [GetArg 3]}

    exec ${exec_prefix}gopher "$sel\t$str" $host $port &
    return 1
}
