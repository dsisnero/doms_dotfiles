# Minimal role - no additional cookbooks beyond platform defaults
include_cookbook "dotfiles"
include_cookbook "mise"

mise "rg"
mise "rclone"
mise "bottom"
mise "fd"
mise "yazi"
mise "fzf"

include_cookbook "ruby" # git hookスクリプトで必要なので先にインストールする'
include_cookbook "python"
include_cookbook "yarn"
include_cookbook "nodejs"
