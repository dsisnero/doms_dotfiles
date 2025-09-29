# Cygwin Zsh Prompt Theme with Vi Mode Support
# This theme provides a custom prompt that changes color based on Vi mode (insert/normal)
# Originally designed for Cygwin but can be used on other platforms

# Zsh Prompt Expansion Codes:
# %# : Regular user shows %, superuser shows #
# %H : Full hostname
# %m : Hostname up to first dot
# %d : Current directory path
# %~ : Current directory path (home dir shown as ~)
# %n : Username
# %D : Date (year-month-day)
# %* : Time (hour:minute:second)

# Normal Mode Prompt (Vi command mode) - magenta background for prompt char
NORMAL_MODE_PROMPT="%{${fg[green]}%}${USER}@${HOST%%.*}%{${reset_color}%} %{${fg[yellow]}%}%~%{${reset_color}%}
%{$bg_bold[magenta]%}%(!.#.$)%{$reset_color%} "

# Insert Mode Prompt (Vi insert mode) - default colors
INSERT_MODE_PROMPT="%{${fg[green]}%}${USER}@${HOST%%.*}%{${reset_color}%} %{${fg[yellow]}%}%~%{${reset_color}%}
%{$reset_color%}%(!.#.$)%{$reset_color%} "

# Start with insert mode prompt by default
PROMPT=${INSERT_MODE_PROMPT}

# Vi Mode Detection and Prompt Updates
# These functions change the prompt appearance based on current Vi mode

# Update prompt based on current Vi mode (insert vs normal)
function update_vi_mode () {
  case $KEYMAP in
    vicmd)
      PROMPT=${NORMAL_MODE_PROMPT}  # Command mode - colored prompt char
      ;;
    main|viins)
      PROMPT=${INSERT_MODE_PROMPT}  # Insert mode - default prompt char
      ;;
  esac
  zle reset-prompt  # Refresh prompt to show changes
}

# Initialize line with current Vi mode
function zle-line-init {
  # auto-fu-init  # Commented out - was for auto-fu plugin
  update_vi_mode
}

# Handle keymap changes (Vi mode switching)
function zle-keymap-select {
  update_vi_mode
}

# Register functions as zsh widgets for Vi mode handling
zle -N zle-line-init
zle -N zle-keymap-select


