# dump archive contents


DefinePlumbing {^.+\.(zip|tgz|tar\.gz|tar\.bz2|tar)$} {
    set fname [CanonicalFilename [GetArg 0]]

    if {[file exists $fname]} {
        switch -exact [GetArg 1] {
            "tar" {set cmd "tar tf"}
            "tar.gz" {set cmd "tar tfz"}
            "tgz" {set cmd "tar tfz"}
            "zip" {set cmd "unzip -l"}
            "tar.bz2" {set cmd "tar tfj"}
            default {error "bad extension: [GetArg 1]"}
        }

        if {[catch [list eval exec $cmd $fname] lst]} {
            LogInWindow "unable to read archive: $fname\n\n$lst"
        } else {
            LogInWindow "$lst\n"
        }

        return 1
    }

    return 0
}
