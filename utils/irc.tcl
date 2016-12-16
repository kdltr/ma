set irc_input_file [open in w]

wm title . [file tail [pwd]]
text .e -height 1
pack .e -fill x

bind .e <Return> {
    set input [.e get @0,0 @0,1024]

    if {[regexp {^/me (.*)} $input _ text]} {
        puts $irc_input_file "\x01ACTION $text\x01"
    } else {
        puts $irc_input_file $input
    }

    flush $irc_input_file
    .e delete @0,0 end
}

