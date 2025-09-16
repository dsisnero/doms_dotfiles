### Introduction {{{
#
#  .zshrc - Z Shell Configuration File
#
#  This file is loaded for interactive shells after .zprofile
#  Contains settings for command line behavior, aliases, functions,
#  completion system, and prompt customization
#
#  Key sections:
#  1. Environment variables and tool setup (mise, zcompile)
#  2. Zsh completion system configuration
#  3. History settings
#  4. Key bindings and custom functions
#  5. Alias definitions
#  6. Plugin and utility loading
#  7. Prompt customization
#
#  Important functions:
#  - ls_and_git_status: Shows directory contents and git status on Enter
#  - do_enter: Custom Enter key behavior
#  - Various helper functions for git, docker, etc.
#
#  Note: Japanese comments were preserved for historical context
#************************************************************************** }}}

# Mise (formerly rtx) setup for tool versions and environment management
export MISE_SOPS_AGE_KEY_FILE=$HOME/.config/mise/age.txt
export SOPS_AGE_KEY_FILE=$HOME/.config/mise/age.txt
eval "$(mise activate zsh)"

# Compile .zshrc for faster loading if it's newer than the compiled version
if [ ! -f ~/.zshrc.zwc -o ~/.zshrc -nt ~/.zshrc.zwc ]; then
   zcompile ~/.zshrc
fi

#---------------------------------------------
# Basic Zsh Configuration
#---------------------------------------------
# ref) http://voidy21.hatenablog.jp/entry/20090902/1251918174

# Zsh Completion System Enhancement {{{
# http://qiita.com/PSP_T/items/ed2d36698a5cc314557d
# Enhanced completion with menu selection, caching, and descriptive formatting
# 補完候補のハイライト (completion highlighting)
zstyle ':completion:*:default' menu select=2
# 補完関数の表示を強化する
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' verbose yes
zstyle ':completion:*' completer _oldlist _expand _complete _match _prefix _approximate _list
zstyle ':completion:*:messages' format '%F{YELLOW}%d%f'
zstyle ':completion:*:warnings' format '%F{RED}No matches for:''%F{YELLOW} %d%f'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:descriptions' format '%F{yellow}Completing %B%d%b%f'
zstyle ':completion:*:processes' command "ps -u $USER -o pid,stat,%cpu,%mem,cputime,command"

# マッチ種別を別々に表示
zstyle ':completion:*' group-name ''

# path
zstyle ':completion:*:sudo:*' command-path \
  /usr/local/bin \
  /usr/sbin \
  /usr/bin \
  /sbin \
  /bin

# セパレータを設定する
zstyle ':completion:*' list-separator '-->'
zstyle ':completion:*:manuals' separate-sections true

# Initialize completion system after fpath is set
# ref : http://yonchu.hatenablog.com/entry/20120415/1334506855
# Enable completion
autoload bashcompinit && bashcompinit  # Bash compatibility for completion
autoload -Uz compinit && compinit -u   # Zsh completion initialization

typeset -U path PATH  # Ensure PATH entries are unique

# cdの関連
autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs
zstyle ':chpwd:*' recent-dirs-max 5000
zstyle ':chpwd:*' recent-dirs-default yes
zstyle ':completion:*' recent-dirs-insert both

## LS_COLORSを設定しておく
#export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
#
## ファイル補完候補に色を付ける
#zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# 小文字は大文字とごっちゃで検索できる
# 大文字は小文字と区別される
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# ディレクトリを切り替える時の色々な補完スタイル
#あらかじめcdpathを適当に設定しておく
cdpath=(~ ~/repos/)
# カレントディレクトリに候補がない場合のみ cdpath 上のディレクトリを候補に出す
zstyle ':completion:*:cd:*' tag-order local-directories path-directories
#cd は親ディレクトリからカレントディレクトリを選択しないので表示させないようにする (例: cd ../<TAB>):
zstyle ':completion:*:cd:*' ignore-parents parent pwd

zstyle ':completion:*:' ignore-parents parent pwd

# 補完で表示しない例外設定
zstyle ':completion:*:*:cd:*' ignored-patterns '.svn|.git'
zstyle ':completion:*:*files' ignored-patterns '*?.o' '*?.pyc' '*\~'
# ls,rmはすべてを補完
zstyle ':completion:*:ls:*' ignored-patterns
zstyle ':completion:*:rm:*' ignored-patterns

# aws cli
if (test -e /usr/local/bin/aws_completer); then
  complete -C '/usr/local/bin/aws_completer' aws
fi

# }}}

setopt nobeep               # ビープ音なし
setopt ignore_eof           # C-dでログアウトしない
setopt no_auto_param_slash  # 自動で末尾に/を補完しない
setopt auto_pushd           # cd履歴を残す
setopt pushd_ignore_dups    # 重複cd履歴は残さない

# History Configuration {{{
# Large history size for extensive command recall
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt appendhistory extendedglob notify
setopt extended_history

# Ignore duplicate history entries
setopt hist_ignore_dups
# Ignore commands starting with space (for sensitive commands)
setopt hist_ignore_space

# Share history between sessions
setopt share_history

# Verify history expansion before execution
setopt hist_verify

# Remove extra blanks from history entries
setopt hist_reduce_blanks

# Ignore duplicates when saving history
setopt hist_save_no_dups

# Expand history during completion
setopt hist_expand

# Incremental history appending (instead of on exit)
setopt inc_append_history

# Incremental search bindings
bindkey "^R" history-incremental-search-backward
bindkey "^S" history-incremental-search-forward

# Display entire history
function history-all { history -i 1 }

# Smart insert last word functionality
autoload -Uz smart-insert-last-word
# Pattern for words to insert: at least 2 chars including letters, /, or \
zstyle :insert-last-word match '*([[:alpha:]/\\]?|?[[:alpha:]/\\])*'
zle -N insert-last-word smart-insert-last-word
bindkey '^]' insert-last-word
#}}}

# Command line stack for multi-line command editing
# http://qiita.com/ikm/items/1f2c7793944b1f6cc346
show_buffer_stack() {
  POSTDISPLAY="
  stack: $LBUFFER"
  zle push-line-or-edit
}
zle -N show_buffer_stack


# Key bind
bindkey -e # emacs風バインド

# bindkey -v # vi風バインド
# bindkey $'\e' vi-cmd-mode

# 履歴表示
# 履歴から入力の続きを補完
bindkey "^[[A" history-beginning-search-backward
bindkey "^[[B" history-beginning-search-forward
bindkey "^P" history-beginning-search-backward
bindkey "^N" history-beginning-search-forward

bindkey " " magic-space

# コマンドラインスタックをviバインドで使用できるように
setopt noflowcontrol
bindkey '^Q' show_buffer_stack

#########################################
# Function: Show directory listing and git status when Enter is pressed with empty command line
function ls_and_git_status() {
  echo
  ls -FG  # Colorized directory listing with file type indicators
  # If inside a git repository, show brief git status
  if [ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" = 'true' ]; then
    echo
    echo -e "\e[0;33m--- git status ---\e[0m"  # Yellow header
    git status -sb  # Short branch status
  fi

  echo
  echo
}

# expand global aliases by space
# http://blog.patshead.com/2012/11/automatically-expaning-zsh-global-aliases---simplified.html
# globalias() {
#   if [[ $LBUFFER =~ ' [A-Z0-9]+$' ]]; then
#     zle _expand_alias
#     # zle expand-word
#   fi
#   zle self-insert
# }
#
# zle -N globalias
#
# bindkey " " globalias
#
# function expand_alias() {
#   zle _expand_alias
#   zle expand-word
# }

# Enter key callback - custom behavior when Enter is pressed
# ref) http://qiita.com/yuyuchu3333/items/e9af05670c95e2cc5b4d
function do_enter() {
  # If there's input, execute it normally
  if [ -n "$BUFFER" ]; then
    zle accept-line
    return 0
  fi

  # If command line is empty, show directory and git status
  ls_and_git_status

  zle reset-prompt  # Refresh the prompt
  return 0
}

zle -N do_enter    # Register as a widget
bindkey '^m' do_enter  # Bind to Enter key


#########################################
# Alias Definitions
#########################################

# Cross-platform open command for non-macOS systems
if [[ $OSTYPE != darwin* ]]; then
  open() {
    which xdg-open > /dev/null 2>&1 && xdg-open $@
    which gnome-open > /dev/null 2>&1 && gnome-open $@
    echo $@ # TODO: not implement
  }
fi

# Edit git-tracked files with default editor
function edit {
  local editor_cmd
  editor_cmd=($EDITOR)  # Split EDITOR into array to handle spaces
  local files
  files=$(git ls-files | $FILTER_CMD)  # Select files using filter command
  if [ -n "$files" ]; then
    local file_array
    file_array=()
    # Read files into array to handle spaces in filenames
    while IFS= read -r line; do
      file_array+=("$line")
    done <<< "$files"
    # Open all selected files with editor
    "${editor_cmd[@]}" "${file_array[@]}"
  fi
}

# Generic pipe function for filtering commands through $FILTER_CMD (like fzf/peco)
p() {
  local pecoopts=()
  while [[ "$#" -gt 0 ]]; do case $1 in
    -*) pecoopts+=($1);;
    *) break;;
  esac; shift; done

  $FILTER_CMD $pecoopts | while read LINE; do $@ $LINE; done
}

# Use exa for modern ls replacement on all platforms
if command -v exa &> /dev/null; then
  # exa is available, set up aliases
  alias ls='exa --group-directories-first'  # Basic ls replacement
  alias l='exa -l --group-directories-first --git'  # Long format with git status
  alias ll='exa -la --group-directories-first --git'  # Long format including hidden files
  alias la='exa -a --group-directories-first'  # Show all including hidden files
  alias lt='exa -T --group-directories-first --git-ignore'  # Tree view
  alias lT='exa -T --group-directories-first -L 2'  # Tree view limited to 2 levels
else
  # Fallback to standard ls if exa is not available
  alias l='ls -FG'  # List files with colors and type indicators
  alias ll='ls -lFG'  # Long list format
  alias la='ls -lFGa'  # Long list including hidden files
fi

# Common command aliases for productivity
alias ls_font='fc-list'  # List installed fonts
alias o='git ls-files | p open'  # Interactive selection and opening of git-tracked files
alias c='ghq list -p | p cd'  # Change to repository directory
alias h='history -i'; compdef h=history  # Show history with timestamps
alias pd=popd; compdef pd=popd  # Pop directory from stack
alias history='history -i'  # History with timestamps

# Enhanced OCaml REPL with readline support
alias ocaml='rlwrap ocaml'

# Reload zsh configuration
alias reload_zshrc='source ~/.zshrc'

# Find vim backup files
alias find-vimbackup='find **/*~'

# Silver searcher with smart case by default
alias ag='ag -S'

# Docker and docker-compose aliases
alias d='docker'; compdef d=docker
alias dc='UID=$(id -u) GID=$(id -g) docker compose'  # Docker compose with current user permissions
alias docker_rm_images='docker images -qf dangling=true | xargs docker rmi'  # Remove dangling images
alias docker_rm_containers='docker ps -aqf status=exited | xargs docker rm -v'  # Remove exited containers with volumes
alias docker_rm_volumes='docker volume ls -qf dangling=true | xargs docker volume rm'  # Remove dangling volumes
alias docker_rm_compose_containers='docker compose rm -fv'  # Force remove docker compose containers

# Attach to docker container with tmux integration
function dcattach() {
  service=$1
  container_name=$(docker compose ps ${service} | sed '1d' | awk '{print $1}')

  how_to_detach=$(cat << EOUSAGE
Attaching: ${container_name}!
How to Detach: Ctrl+P, Ctrl+Q
EOUSAGE
)
  echo $how_to_detach

  if [ -n "$TMUX" ]; then
    # Set tmux pane title and attach to container
    tmux select-pane -T "🐳 ${container_name}: C+p,C+q"
    docker attach $container_name

    tmux select-pane -T $(hostname)  # Reset pane title after detach
  else
    docker attach $container_name
  fi
}

# Git aliases and functions
function g() {
  if [[ $# -gt 0 ]]; then
    git "$@"
  else
    git status  # Default to status if no arguments
  fi
}
compdef g=git
alias gittaglist="git for-each-ref --sort=-taggerdate --format='%(taggerdate:short) %(tag) %(taggername) %(subject)' refs/tags"  # List tags with details
alias gf='git flow'; compdef gf=git-flow  # Git flow extension

# Docker-based tool aliases
alias dockviz="docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock nate/dockviz"  # Docker visualization
alias marp='docker run --rm --init -v $(pwd):/workdir -w /workdir -e LANG=$LANG -p 8080:8080 marpteam/marp-cli'  # Markdown presentation tool
alias mysql='mycli'  # MySQL CLI with autocomplete
alias owasp='docker run -v $(pwd):/zap/wrk/:rw -t --rm owasp/zap2docker-stable zap-baseline.py '  # OWASP ZAP security scanning
alias pandoc='docker run --rm --volume "`pwd`:/data" --user `id -u`:`id -g` pandoc/core'  # Document conversion
alias gixy='docker run --rm -v $(pwd):/workdir -w /workdir yandex/gixy'  # Nginx configuration analysis
alias dive='docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock -v  "$(pwd)":"$(pwd)" -w "$(pwd)" -v "$HOME/.dive.yaml":"$HOME/.dive.yaml" wagoodman/dive:latest'  # Docker image analysis

# File type associations - automatically open files with appropriate programs
alias -s html=chrome  # Open HTML files in Chrome
alias -s rb=ruby  # Run Ruby files
alias -s py=python  # Run Python files

# Global aliases for piping common commands
alias -g LL='| less'  # Pipe to less
alias -g HH='| head'  # Pipe to head
alias -g TT='| tail'  # Pipe to tail
alias -g GG='| grep'  # Pipe to grep
alias -g WW='| wc'  # Pipe to word count
alias -g SS='| sed'  # Pipe to sed
alias -g AA='| awk'  # Pipe to awk
alias -g XX='| xargs'  # Pipe to xargs
alias -g PP='| peco'  # Pipe to peco

# Git-specific global aliases for filtering branches, tags, commits, etc.
alias -g B='`git branch | sort -r | $FILTER_CMD | sed -e "s/^\*[ ]*//g"`'  # Select local branch
alias -g BR='`git branch -r | sort -r | $FILTER_CMD| sed -e "s/^\*[ ]*//g"`'  # Select remote branch
alias -g BALL='`git branch -a | sort -r | $FILTER_CMD| sed -e "s/^\*[ ]*//g"`'  # Select any branch
alias -g T='`git tag | $FILTER_CMD`'  # Select tag
alias -g C='`git log --oneline | $FILTER_CMD| sed -e "s/^.*\* *\([a-f0-9]*\) .*/\1/g" -e "s/^[\|/ ]*$//g"`'  # Select commit from current branch
alias -g CALL='`git log --decorate --branches --all --graph --oneline --all | $FILTER_CMD| sed -e "s/^.*\* *\([a-f0-9]*\) .*/\1/g" -e "s/^[\|/ ]*$//g"`'  # Select commit from all branches
alias -g F='`git ls-files | $FILTER_CMD`'  # Select file from git repository
alias -g R='`git reflog | $FILTER_CMD| cut -d" " -f1`'  # Select commit from reflog
alias -g TM='`tmux list-sessions`'  # Select tmux session
alias -g HIST='`peco_history`'  # Select command from history

# Vagrant function with status as default
function va() {
  if [[ $# -gt 0 ]]; then
    vagrant "$@"
  else
    vagrant status  # Default to status if no arguments
  fi
}
alias v_restart="vagrant halt; vagrant up"  # Restart vagrant machine

# Use local neofetch if available
if [[ -f ~/repos/github.com/dylanaraps/neofetch/neofetch ]]; then
  alias neofetch='~/repos/github.com/dylanaraps/neofetch/neofetch'
fi
## Zsh Manual Utilities {{{
## ref) http://qiita.com/yuyuchu3333/items/67630d597c7700a51b95
## Search zshall manual pages for specific terms
# zman [search word]
zman() {
  if [[ -n $1 ]]; then
    PAGER="less -g -s '+/"$1"'" man zshall  # Search for term in zshall manual
    echo "Search word: $1"
  else
    man zshall  # Show full zshall manual if no search term
  fi
}

# Search for zsh terminology in manual
# http://qiita.com/mollifier/items/14bbea7503910300b3ba
zwman() {
  zman "^       $1"  # Search for exact terminology matches
}

# Search for zsh flag documentation in manual
zfman() {
  local w='^'
  w=${(r:8:)w}  # Pad to 8 characters
  w="$w${(r:7:)1}|$w$1(\[.*\].*)|$w$1:.*:|$w$1/.*/.*"  # Build regex pattern for flags
  zman "$w"  # Search with constructed pattern
}

# Colorized man pages with better readability
function man (){
  env \
    LESS_TERMCAP_mb=$(printf "\e[1;31m") \  # Begin blink (red)
    LESS_TERMCAP_md=$(printf "\e[1;31m") \  # Begin bold (red)
    LESS_TERMCAP_me=$(printf "\e[0m") \     # End mode
    LESS_TERMCAP_se=$(printf "\e[0m") \     # End stand-out
    LESS_TERMCAP_so=$(printf "\e[1;44;33m") \  # Begin stand-out (yellow on blue)
    LESS_TERMCAP_ue=$(printf "\e[0m") \     # End underline
    LESS_TERMCAP_us=$(printf "\e[1;32m") \  # Begin underline (green)
    LANG=C \
    man "$@"  # Run man with colorized environment
}
#}}}

# Key binding for inserting current date with Ctrl+x then d
function print_date() {
  zle -U `date "+%Y%m%d"`  # Insert YYYYMMDD format date
}
zle -N print_date
bindkey "^Xd" print_date

# Change neovim's current directory using neovim-remote
function nvcd (){
  nvr -c "cd $(realpath $@)"  # Send cd command to running neovim instance
}

# Report time for commands taking longer than 3 seconds
REPORTTIME=3

# Characters considered part of a word for word-based navigation and deletion
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

# Tmux integration utilities {{{
# Pane split on startup
# ref) http://qiita.com/ken11_/items/1304c2eecc2657ac6265
alias t='tmux_start'    # Start or attach to tmux session
alias tm='tmux_multissh'  # Multi-ssh with tmux
#}}}

# Plugin system - load local plugin configurations
if [ -f ${PERSONAL_ZSH_DIR}/.zshrc.plugin ]; then
  source ${PERSONAL_ZSH_DIR}/.zshrc.plugin  # Load personal plugin settings
fi

# Load utility scripts (commented out) {{{
# utils_dir=~/repos/github.com/bundai223/dotfiles/config/zsh/zsh-utils
# source ~/repos/github.com/bundai223/dotfiles/config/zsh/zsh-utils/scripts/functions.zsh
# source_scripts_in_tree $utils_dir
# }}}

# Prompt configuration {{{
# Enable color support for prompts
autoload -Uz colors && colors

# Powerline prompt setup
# Dynamically find powerline installation and source its zsh bindings
export PIP_SITE_LOCATION=$(mise exec -- pip show -f powerline-status | grep Location | awk '{print $2}')
source ${PIP_SITE_LOCATION}/powerline/bindings/zsh/powerline.zsh

#}}}

# Note: z (directory jumping) has been replaced with zoxide
# Historical reference: http://d.hatena.ne.jp/naoya/20130108/1357630895
# _Z_DATA=${XDG_CONFIG_HOME:-$HOME/.config}/zsh/z/.z
# if [[ $OSTYPE == darwin* ]]; then
#   . `brew --prefix`/etc/profile.d/z.sh
# else
#   # . ~/repos/github.com/rupa/z/z.sh
# fi
# precmd_z () {
#   z --add "$(pwd -P)"
# }
# add-zsh-hook precmd precmd_z

# Tmux integration: Update tmux environment with current directory when using powerline
if [ -n "$TMUX" ]; then
  # tmux用powerlineのcwd更新
  update_tmux_cwd() {
    tmux setenv TMUXPWD_$(tmux display -p "#D" | tr -d %) "$PWD"
  }
  add-zsh-hook chpwd update_tmux_cwd
fi

# OPAM configuration (commented out)
# . ~/.opam/opam-init/init.zsh > /dev/null 2> /dev/null || true

# Direnv: Load environment variables based on .envrc files
which direnv >/dev/null && eval "$(direnv hook zsh)"

# Starship: Cross-shell prompt
eval "$(starship init zsh)"

# Zoxide: Smarter directory navigation
eval "$(zoxide init zsh)"

# True color support detection
[[ "$COLORTERM" == (24bit|truecolor) || "${terminfo[colors]}" -eq '16777216' ]] || zmodload zsh/nearcolor

# Zsh profiler utility for performance analysis
function zsh-profiler() {
  ZSHRC_PROFILE=1 zsh -i -c zprof
}

# Change to directory using custom cdd command
# 配下のdirectoryに移動するcd
alias cdd='source $(which cdd_cmd)'

# Change to repository directory using ghq and fzf/peco
cd_repos() {
  if [ -n "$1" ]; then
    # Search repositories with query string using fzf
    pth=$(ghq list --full-path | sed "s#${HOME}#~#"| fzf -q $1 | sed "s#~#${HOME}#") # fzf -q querystring
    # Alternative using peco:
    # pth=$(ghq list --full-path | sed "s#${HOME}#~#"| peco --query $1 | sed "s#~#${HOME}#") # fzf -q querystring
  else
    # Interactive repository selection
    pth=$(ghq list --full-path | sed "s#${HOME}#~#"| $FILTER_CMD | sed "s#~#${HOME}#")
  fi
  if [ -n "$pth" ]; then
    eval "cd $pth"
  fi
}

# Network utilities
# https://qiita.com/Rasukarusan/items/61f435bf899dc99d7e79#%E3%82%AB%E3%83%AC%E3%83%B3%E3%83%88%E3%83%87%E3%82%A3%E3%83%AC%E3%82%AF%E3%83%88%E3%83%AA%E3%82%92finder%E3%81%A7%E9%96%8B%E3%81%8Foo%E3%82%B3%E3%83%9E%E3%83%B3%E3%83%89
# Get public IPv4 address
alias myip='curl ifconfig.io -4'
# Weather forecast for Kanagawa
alias tenki='curl -4 http://wttr.in/kanagawa'

# Environment variables
export PATH=~/.local/bin:$PATH  # Add local bin to PATH
export EDITOR=hx                # Set Helix as default editor
export OLLAMA_MODELS=/Volumes/extreme_ssd/ollama_models  # Ollama model storage location
