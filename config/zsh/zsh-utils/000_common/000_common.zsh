# Sum numbers from arguments or standard input
sum() {
  if [ -p /dev/stdin ]; then
    args=$(cat -)
  else
    args=$*
  fi

  _num=0
  for i in $args; do
    _num=$((_num+$i))
  done
  echo $_num
}

# List SSH host names from ~/.ssh/config
ls_sshhost() {
#   awk '
#   tolower($1)=="host" {
#   for (i=2; i<=NF; i++) {
#     if ($i !~ "[*?]") {
#       print $i
#     }
#   }
# }
# ' ~/.ssh/config | sort
  grep -E "^Host " ~/.ssh/config | sed -e 's/Host[ ]*//g'
}

# List IP addresses from network interfaces
ls_ip() {
  LANG=C ifconfig | grep 'inet ' | awk '{print $2;}' | cut -d: -f2
  #LANG=C ifconfig | grep 'inet addr' | awk '{print $2;}' | cut -d: -f2
}

# Display OS version by checking various system files
os_version() {
  VERSION_FILE_ARRAY=(\
    '/etc/redhat-release' \
    '/etc/fedora-release' \
    '/etc/debian_version' \
    '/etc/turbolinux-release' \
    '/etc/SuSE-release' \
    '/etc/mandriva-release' \
    '/etc/vine-release' \
    '/etc/issue' \
    )

  if [ 'Darwin' = $(uname) ]; then
    sw_vers
  else
    for file in $VERSION_FILE_ARRAY; do
      if [ -e $file ]; then
        cat $file; break
      fi
    done
  fi
}

# SSH wrapper that changes tmux pane colors and titles based on hostname
# When using tmux, it sets the pane title and changes foreground color based on host type:
#   prod- hosts: red
#   dev- hosts: yellow
#   IP addresses: green
ssh() {
  # Check if running inside tmux
  if [[ -n $(printenv TMUX) ]] ; then
    h=${@: -1}

    tmux select-pane -T "ssh: $h"  # Set pane title to hostname

    # Change pane foreground color based on hostname pattern
    if [[ `echo $h | grep 'prod-'` ]] ; then
      tmux select-pane -P 'fg=red'
    elif [[ `echo $h | grep 'dev-'` ]] ; then
      tmux select-pane -P 'fg=yellow'
    elif [[ `echo $h | sed 's/^.*@//g' | grep '[0-9.]*'` ]] ; then
      tmux select-pane -P 'fg=green'
    fi
    # Execute SSH command with xterm terminal type
    TERM=xterm command ssh $@

    # Reset pane title to current hostname
    tmux select-pane -T $(hostname)

    # Reset pane color to default
    tmux select-pane -P 'default'

  else
    # If not in tmux, just run SSH normally
    TERM=xterm command ssh $@
  fi
}

# Create directory and change into it
# Usage: mkcddir [options] directory_name
function mkcddir() {
  eval dirpath=$"$#"
  mkdir ${@} && cd $dirpath
}

# Preview all 256 terminal colors
function preview-termcolors () {
  for c in {000..255}; do echo -n "\e[38;5;${c}m $c" ; [ $(($c%16)) -eq 15 ] && echo;done;echo
}

# Preview powerline font characters by printing their Unicode values
function preview-powerlinefonts () {
  for i in {61545..62718}; do
    codepoint=$(printf '%x' $i)
    unicode=$(printf '\\u%x' $i)
    echo -n ${codepoint}:
    echo -e " ${unicode}"
  done
}

# Search for pattern in all files tracked by git
function grepall() { git ls-files | xargs grep -l $1 }

# Replace string in all files tracked by git that contain the pattern
function sedall()  { grepall $1 | xargs sed -i "s/$1/$2/g" }

# Rename files in git repository by replacing patterns in filenames
function renameall() { git ls-files | grep $1 | while read LINE; do mv $LINE `echo $LINE | sed s/$1/$2/g`; done }
