# Node.js version management utilities for nvm (Node Version Manager)
# This provides automatic Node version switching when changing directories
# based on .nvmrc files. Uncomment to enable automatic version switching.

# Note: This code should be placed after nvm initialization in your zsh configuration

# Automatically switch Node versions when a directory contains an .nvmrc file
# Uncomment the following lines to enable automatic version switching:

# Load zsh hook system for directory change events
# autoload -U add-zsh-hook

# Function to load the correct Node version when changing directories
# load-nvmrc() {
#   local node_version="$(nvm version)"  # Get current Node version
#   local nvmrc_path="$(nvm_find_nvmrc)" # Find .nvmrc file in current or parent directories
#
#   if [ -n "$nvmrc_path" ]; then
#     # Read the required version from .nvmrc file
#     local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")
#
#     # If the required version is not installed, install it
#     if [ "$nvmrc_node_version" = "N/A" ]; then
#       nvm install
#     # If current version doesn't match required version, switch to required version
#     elif [ "$nvmrc_node_version" != "$node_version" ]; then
#       nvm use
#     fi
#   # If no .nvmrc found and we're not using the default version, revert to default
#   elif [ "$node_version" != "$(nvm version default)" ]; then
#     echo "Reverting to nvm default version"
#     nvm use default
#   fi
# }

# Add the load-nvmrc function to be called whenever the directory changes
# add-zsh-hook chpwd load-nvmrc

# Load the correct version for the initial directory
# load-nvmrc
