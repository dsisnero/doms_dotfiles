# Disable Apple laptop keyboard on Linux systems
# Useful when using an external keyboard and want to avoid accidental key presses
disable_laptop_keyboard()
{
  # get id $(xinput list)
  id=$(xinput list|grep Apple|sed 's/.*id=\([0-9]*\).*$/\1/g')
  xinput float $id
}

# Re-enable Apple laptop keyboard on Linux systems
enable_laptop_keyboard()
{
  id=$(xinput list|grep Apple|sed 's/.*id=\([0-9]*\).*$/\1/g')
  xinput reattach $id 3
}

# Run pacman with recovery options for fixing broken packages
# Bypasses normal checks to allow recovery of a corrupted package database
recovery-pacman() {
    sudo pacman "$@"  \
    --log /dev/null   \
    --noscriptlet     \
    --dbonly          \
    --overwrite       \
    --nodeps          \
    --needed
}

# Install fonts for the current user and update font cache
# Fonts are copied to ~/.local/share/fonts and system font cache is refreshed
install_font () {
  dir=~/.local/share/fonts
  test -e $dir || mkdir -p $dir
  cp $@ $dir
  fc-cache -f
  sudo fc-cache -f
}
