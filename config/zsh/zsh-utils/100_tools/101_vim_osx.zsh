# 
# Function to open MacVim with specific behavior
# Opens Vim in a single window setup by default
# If arguments start with - or +, pass them directly to mvim
# Otherwise, open files in new tabs in existing MacVim instance
# 
mvim() {
    if [[ -z $1 || $1 =~ "^[-+]" ]]; then
        # Directly pass flags or no arguments to mvim
        /Applications/MacVim.app/Contents/MacOS/mvim $*
    else
        # Open files in new tabs in existing MacVim instance
        /Applications/MacVim.app/Contents/MacOS/mvim --remote-tab-silent $*
    fi
}


