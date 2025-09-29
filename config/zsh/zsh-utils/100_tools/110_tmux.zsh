# tmux utility functions for session management and multi-server operations

# Start or attach to tmux session
# This function intelligently handles tmux session creation and attachment:
# - Checks if tmux is available
# - Prevents nested tmux sessions
# - Attaches to existing detached sessions if available
# - Creates new sessions with OS-specific configurations
tmux_start()
{
  # Check if tmux command exists
  if ! type tmux >/dev/null 2>&1; then
    echo 'Error: tmux command not found' 2>&1
    return 1
  fi

  # Prevent nested tmux sessions
  if [ -n "$TMUX" ]; then
    # echo "Error: tmux session has been already attached" 2>&1
    return 1
  fi

  # Check for existing detached sessions and attach to them
  if tmux has-session >/dev/null 2>&1 && tmux list-sessions | grep -v attached > /dev/null 2>&1; then
    # detached session exists - attach to it
    tmux -2 attach -d && echo "tmux attached session "
  else
    # No detached sessions - create a new one
    if [[ ( $OSTYPE == darwin* ) && ( -x $(which reattach-to-user-namespace 2>/dev/null) ) ]]; then
      # On macOS, configure tmux to work with the user's namespace for clipboard access
      tmux_config=$(cat $HOME/.tmux.conf <(echo 'set-option -g default-command "reattach-to-user-namespace -l $SHELL"'))
      tmux -2 -f <(echo "$tmux_config") new-session $* && echo "tmux created new session supported OS X"
    else
      # On other systems, create a standard new session
      tmux -2 new-session $* && echo "tmux created new session"
    fi
  fi
}

# Create a multi-pane tmux session for SSH connections to multiple hosts
# All panes are synchronized so commands are sent to all hosts simultaneously
# Usage: tmux_multissh host1 host2 host3 ...
tmux_multissh()
{
  # Create unique session name with timestamp
  session=multi-ssh-`date +%s`
  window=multi-ssh

  # Start tmux session if not already in one
  if [ -z "$TMUX" ]; then
    tmux_start -d -n $window -s $session
  fi
#   tmux rename-window $window

  ### SSH to multiple hosts in separate panes
  # First host uses the initial pane
  tmux send-keys "ssh $1" C-m
  shift

  # Determine layout based on number of panes
  pane_num=$#
  layout=tiled
  if [ $pane_num -lt 6 ]; then
    layout=even-vertical
  fi
  
  # Create additional panes for remaining hosts
  for i in $*;do
    tmux split-window
    tmux send-keys "ssh $i" C-m
    tmux select-layout $layout
  done

  ### Select the first pane as active
  tmux select-pane -t 0

  ### Enable synchronized panes - commands typed in one pane are sent to all
  tmux set-window-option synchronize-panes on

  # Attach to the newly created session
  tmux attach -t $session
}


# Uncomment the following section to enable dynamic pane titles based on current command
# This sets the pane title to the first word of the command being executed
#if [ -n "$TMUX" ]; then
#  _tmux_pane_preexec() {
#    tmux select-pane -T "local: ${1%% *}"
#  }
#  add-zsh-hook preexec _tmux_pane_preexec
#fi
