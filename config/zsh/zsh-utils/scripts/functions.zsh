# Zsh Utility Functions - Script Loading System
# This file provides a function to dynamically source zsh scripts based on OS type
# Used for organizing and loading platform-specific zsh configurations

# Function: source_scripts_in_tree
# Description: Recursively finds and sources all .zsh files in a directory tree,
#              filtering out platform-specific files that don't match current OS
# Parameters: 
#   $1 - Root directory to search for .zsh scripts
source_scripts_in_tree()
{
  local script_root=${1}
  # Find all .zsh files recursively in the script root directory
  local utilities=($(find -L ${script_root} -type f -name "*.zsh"))

  # Platform-specific file suffix definitions
  local osx_suffix=_osx.zsh
  local win_suffix=_win.zsh
  local linux_suffix=_linux.zsh

  # Filter utilities based on current operating system
  # This ensures only relevant platform-specific scripts are loaded
  case ${OSTYPE} in
    darwin*)
      # macOS: Exclude Windows and Linux specific scripts
      utilities=($(for ut in ${utilities}; echo ${ut}|grep -v $win_suffix|grep -v $linux_suffix))
      ;;
    linux*)
      # Linux: Exclude Windows and macOS specific scripts
      utilities=($(for ut in ${utilities}; echo ${ut}|grep -v $win_suffix|grep -v $osx_suffix))
      ;;
    cygwin*|msys*)
      # Windows (Cygwin/MSYS): Exclude macOS and Linux specific scripts
      utilities=($(for ut in ${utilities}; echo ${ut}|grep -v $osx_suffix|grep -v $linux_suffix))
      ;;
  esac
  
  # Export the filtered utilities array (optional - for debugging)
  export utilities
  
  # Source each filtered utility script
  for utility in ${utilities}; do
    source ${utility}
  done
}
