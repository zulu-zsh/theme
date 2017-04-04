#!/usr/bin/env zsh

# Zulu default theme
# by James Dinsdale
# https://github.com/zulu-zsh/theme
# MIT License

# Largely based on Filthy by James Dinsdale <https://github.com/molovo/filthy>

# For my own and others sanity
# git:
# %b => current branch
# %a => current action (rebase/merge)
# prompt:
# %F => color dict
# %f => reset color
# %~ => current path
# %* => time
# %n => username
# %m => shortname host
# %(?..) => prompt conditional - %(condition.true.false)

# string length ignoring ansi escapes
prompt_zulu_string_length() {
  print ${#${(S%%)1//(\%([KF1]|)\{*\}|\%[Bbkf])}}
}

prompt_zulu_precmd() {
  local prompt_zulu_preprompt git_root current_path branch repo_status

  # Ensure prompt starts on a new line
  prompt_zulu_preprompt="\n"

  prompt_zulu_preprompt+="$(prompt_zulu_connection_info) "

  # Print the current path
  prompt_zulu_preprompt+="%F{209}%~%f"

  print -P $prompt_zulu_preprompt
}

prompt_zulu_rprompt() {
	# check if we're in a git repo, and show git info if we are
	if command git rev-parse --is-inside-work-tree &>/dev/null; then
		# Print the repository status
		branch=$(prompt_zulu_git_branch)
		repo_status=$(prompt_zulu_git_repo_status)
	fi

  print "${branch}${repo_status}"
}

prompt_zulu_git_repo_status() {
  # Do a fetch asynchronously
  git fetch > /dev/null 2>&1 &!

  local clean
  local rtn=""
  local count
  local up
  local down

  dirty="$(git diff --ignore-submodules=all HEAD 2>/dev/null)"
  [[ $dirty != "" ]] && rtn+=" %F{242}…%f"

  staged="$(git diff --staged HEAD 2>/dev/null)"
  [[ $staged != "" ]] && rtn+=" %F{242}*%f"

  # check if there is an upstream configured for this branch
  # exit if there isn't, as we can't check for remote changes
  if command git rev-parse --abbrev-ref @'{u}' &>/dev/null; then
    # if there is, check git left and right arrow_status
    count="$(command git rev-list --left-right --count HEAD...@'{u}' 2>/dev/null)"

    # Get the push and pull counts
    up="$count[(w)1]"
    down="$count[(w)2]"

    # Check if either push or pull is needed
    [[ $up > 0 || $down > 0 ]] && rtn+=" "

    # Push is needed, show up arrow
    [[ $up > 0 ]] && rtn+="%F{209}⇡%f"

    # Pull is needed, show down arrow
    [[ $down > 0 ]] && rtn+="%F{209}⇣%f"
  fi

  print $rtn
}

prompt_zulu_git_branch() {
  # get the current git status
  local branch git_dir_local rtn

  branch=$(git status --short --branch -uno --ignore-submodules=all | head -1 | awk '{print $2}' 2>/dev/null)
  git_dir_local=$(git rev-parse --git-dir)

  # remove reference to any remote tracking branch
  branch=${branch%...*}

  # check if HEAD is detached
  if [[ -d "${git_dir_local}/rebase-merge" ]]; then
    branch=$(git status | head -5 | tail -1 | awk '{print $6}')
    rtn="%F{197}rebasing interactively%f%F{242} → ${branch//([[:space:]]|\')/}%f"
  elif [[ -d "${git_dir_local}/rebase-apply" ]]; then
    branch=$(git status | head -2 | tail -1 | awk '{print $6}')
    rtn="%F{197}rebasing%f%F{242} → ${branch//([[:space:]]|\')/}%f"
  elif [[ -f "${git_dir_local}/MERGE_HEAD" ]]; then
    branch=$(git status | head -1 | awk '{print $3}')
    rtn="%F{197}merging%f%F{242} → ${branch//([[:space:]]|\')/}%f"
  elif [[ "$branch" = "HEAD" ]]; then
    commit=$(git status HEAD -uno --ignore-submodules=all | head -1 | awk '{print $4}' 2>/dev/null)

    if [[ "$commit" = "on" ]]; then
      rtn="%F{221}no branch%f"
    else
      rtn="%F{242}detached@%f"
      rtn+="%F{221}"
      rtn+="$commit"
      rtn+="%f"
    fi
  else
    rtn="%F{242}$branch%f"
  fi

  print "$rtn"
}

prompt_zulu_connection_info() {
  # show username@host if logged in through SSH
  echo '%(!.%B%F{197}%n%f%b.%F{221}%n%f)%F{221}@%m%f'
}

prompt_zulu_setup() {
  # prevent percentage showing up
  # if output doesn't end with a newline
  export PROMPT_EOL_MARK=''

  prompt_opts=(cr subst percent)

  autoload -Uz add-zsh-hook

  add-zsh-hook precmd prompt_zulu_precmd

  # prompt turns red if the previous command didn't exit with 0
  PROMPT='%(?.%F{221}❯%f%F{209}❯%f%F{197}❯%f .%F{197}❯❯❯%f '

  RPROMPT='$(prompt_zulu_rprompt)'
}

prompt_zulu_setup "$@"
