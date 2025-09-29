# ZSH utility functions for file path manipulation and other helpers

# Get project root directory - if in a git repo, use git prjroot, else current directory
prjroot()
{
  git rev-parse --is-inside-work-tree > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    git prjroot # see .gitconfig
  else
    pwd
  fi
}

# Extract filename from full path (equivalent to basename command)
filename()
{
  # equal basename
  echo ${${1}##*/}
}

# Extract parent directory from full path (equivalent to dirname command)
parentpath()
{
  # equal dirname
  echo ${${1}%/*}
}

# Extract file extension from filename
ext()
{
  echo ${${1}##*.}
}

# Extract filename without extension
filename_wo_ext()
{
  echo ${${1}%.*}
}

# Display a spinning progress indicator
# Useful for showing progress during long-running operations
spinner() {
  chars='/-\|'

  while :; do
    for (( i=0; i<${#chars}; i++ )); do
      usleep 300000
      echo -en "${chars:$i:1}" "\r"
    done
  done
}
