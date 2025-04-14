# MUST be first to setup PATH for other profile.d scripts
if [ -n "$BASH_VERSION" ]; then
  eval "$(mise activate bash)"
elif [ -n "$ZSH_VERSION" ]; then
  eval "$(mise activate zsh)"
else
  # Fallback for other shells
  export PATH="$HOME/.local/share/mise/shims:$PATH"
fi
