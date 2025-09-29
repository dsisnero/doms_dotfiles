# Peco utility functions for interactive filtering
# Peco is a fuzzy finder for the command line

# Find files by extension and filter through peco
# Usage: peco_find_ext [extension]
peco_find_ext() {
  find . -name '*.'$1 | $FILTER_CMD
}

# Filter SSH hosts through peco (commented out as an example)
# peco_ssh() {
#   ls_sshhost | p ssh
# }
#

# Search through command history with peco
# Returns selected command without the timestamp and line number
peco_history() {
  history -E 1 | $FILTER_CMD | awk '{c="";for(i=4;i<=NF;i++) c=c $i" "; print c}'
}

# Select from modified git files using peco
# Shows git status short format and removes status prefixes
peco_gitmodified() {
  git status --short | $FILTER_CMD | sed s/"^..."//
}
