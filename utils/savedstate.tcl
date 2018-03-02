# save current configuration when saving file and reload on open


set config_file_dir $env(HOME)/.ma_state
file mkdir $config_file_dir


proc SaveConfiguration {fname realname} {
    global current_background current_foreground current_font 
    global current_variable_font current_font_size current_font_style
    global tag_foreground tag_background selection_foreground 
    global selection_background indent_mode
    global sbar_color sbar_background pseudo_selection_foreground 
    global pseudo_selection_background
    global file_encoding file_translation
    global inactive_selection_background current_fixed_font
    global focus_color nonfocus_color tabwidth include_path
    set f [open $fname w]
    puts $f "# $realname"
    puts $f "set current_foreground \"$current_foreground\""
    puts $f "set current_background \"$current_background\""
    puts $f "set current_font \"$current_font\""
    puts $f "set current_variable_font \"$current_variable_font\""
    puts $f "set current_fixed_font \"$current_fixed_font\""
    puts $f "set current_font_size \"$current_font_size\""
    puts $f "set tag_foreground \"$tag_foreground\""
    puts $f "set tag_background \"$tag_background\""
    puts $f "set selection_foreground \"$selection_foreground\""
    puts $f "set selection_background \"$selection_background\""
    puts $f "set sbar_color \"$sbar_color\""
    puts $f "set sbar_background \"$sbar_background\""
    puts $f "set pseudo_selection_foreground \"$pseudo_selection_foreground\""
    puts $f "set pseudo_selection_background \"$pseudo_selection_background\""
    puts $f "set file_encoding $file_encoding"
    puts $f "set file_translation $file_translation"
    puts $f "set inactive_selection_background \"$inactive_selection_background\""
    puts $f "set focus_color \"$focus_color\""
    puts $f "set nonfocus_color \"$nonfocus_color\""
    puts $f "set tabwidth $tabwidth"
    puts $f "set include_path {$include_path}"
    puts $f "set indent_mode $indent_mode"
    close $f
}


proc LoadConfiguration {fname} {
    uplevel #0 source $fname
    ConfigureWindow 0
}


proc MangleConfigFilename {fname} {
    global config_file_dir
    return $config_file_dir/[MangleFilename $fname]
}


proc SaveCurrentConfig {} {
    global current_filename

    if {$current_filename != ""} {
        SaveConfiguration [MangleConfigFilename $current_filename] $current_filename
    }
}


proc LoadCurrentConfig {} {
    global current_filename 

    if {$current_filename != ""} {
        set fname [MangleConfigFilename $current_filename]

        if {[file exists $fname]} {
            LoadConfiguration $fname
        }
    }
}


AddToHook save_hook SaveCurrentConfig
AddToHook file_hook LoadCurrentConfig
