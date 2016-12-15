# "project" files


set project_file_name ".ma.p"
set project 0


proc SourceProjectFile {} {  
    global project project_file_name
    set fname [GetFilename]

    if {$fname == ""} return

    if {[file exists $fname]} {
        if {[file type $fname] == "directory"} {
            set dir $fname
        } else {
            set dir [file dirname $fname]
        }

        if {!$project} {
            while {$dir != "/"} {
                set pfile "$dir/$project_file_name"
    
                if {[file exists $pfile]} {
                    set project 1
    
                    if {[catch [list uplevel #0 source $pfile]]} {
                        Flash red
                    }
    
                    return
                }
    
                set dir [file dirname $dir]
            }
        }
    }
}


AddToHook name_hook SourceProjectFile
