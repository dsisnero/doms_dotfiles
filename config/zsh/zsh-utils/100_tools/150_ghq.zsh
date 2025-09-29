# GHQ utility functions for working with git repositories
# GHQ is a tool for managing remote git repositories

# Get full paths for all repositories matching a pattern
# Usage: ghq_path [repository_pattern]
ghq_path()
{
  repo=${1}
  root_path=$(ghq root ${repo})
  ghq list ${repo} | xargs -Isub_path echo ${root_path}/sub_path
}

# Change directory to a repository using fuzzy finder (peco/fzf)
# If an argument is provided, pre-filter the list with that query
cd_repos()
{
  if [ -n "$1" ]; then
    pth=$(ghq list --full-path | sed "s#${HOME}#~#"| $FILTER_CMD -q $1 | sed "s#~#${HOME}#") # fzf -q querystring
  else
    pth=$(ghq list --full-path | sed "s#${HOME}#~#"| $FILTER_CMD | sed "s#~#${HOME}#")
  fi
  if [ -n "$pth" ]; then
    eval "cd $pth"
  fi
}
