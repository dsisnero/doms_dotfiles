# Display manufacturer information for 15-inch MacBook Pro displays
# LP: LG display (less desirable)
# LSN: Samsung display (more desirable)
display_info_15inch()
{
    ioreg -lw0 | grep \"EDID\" | sed "/[^<]*</s///" | xxd -p -r | strings -6
}

# Refresh system memory by forcing disk activity
# This can help clear cached memory and improve performance
refresh_memory()
{
    du -sx / &> /dev/null & sleep 25 && kill $!
}

# Install fonts by copying them to the user's Fonts directory
install_font() {
    cp $@ ~/Library/Fonts/
}

# Toggle visibility of hidden files in Finder
# Usage: show_allfile_on_finder [on|off]
show_allfile_on_finder() {
    flag="$1"
    if [ "on" = $flag ]; then
        echo "Enable show all files on finder."
        defaults write com.apple.finder AppleShowAllFiles -boolean true
        killall Finder
    elif [ "off" = $flag ]; then
        echo "Reset show all files on finder."
        defaults delete com.apple.finder AppleShowAllFiles
        killall Finder
    else
        echo "usage:"
        echo "    show_allfile_on_finder [on|off]"
    fi
}

# Alias to compile PlantUML diagrams to SVG format with UTF-8 encoding
alias compile_plantuml="java -jar ~/local/bin/plantuml.jar  -charset UTF-8 -tsvg -nbthread auto $<"
