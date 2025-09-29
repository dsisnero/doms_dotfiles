# Python utility functions and completions

# Display help for a Python module using Python 2
# Usage: py_help [module_name]
py_help() {
    target=$1
    python -c "import ${target}; help(${target})"
}

# Display help for a Python module using Python 3
# Usage: py3_help [module_name]
py3_help() {
    target=$1
    python3 -c "import ${target}; help(${target})"
}


# pip zsh completion start
# Enable tab completion for pip and pip3 commands
function _pip_completion {
  local words cword
  read -Ac words
  read -cn cword
  reply=( $( COMP_WORDS="$words[*]" \
             COMP_CWORD=$(( cword-1 )) \
             PIP_AUTO_COMPLETE=1 $words[1] ) )
}
compctl -K _pip_completion pip3
compctl -K _pip_completion pip
# pip zsh completion end

