# Git prompt customization
# This file is automatically sourced by Oh My Zsh (ZSH_CUSTOM)
# It overrides the default git_prompt_info to show tags/branches when in detached HEAD.

function git_prompt_info() {
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    return
  fi

  local dirty=$(parse_git_dirty)
  local ref=$(git symbolic-ref --short HEAD 2>/dev/null)

  if [[ -n "$ref" ]]; then
    # On a branch: (branch*)
    # The prefix starts the green color (078)
    echo "${ZSH_THEME_GIT_PROMPT_PREFIX}${ref}${dirty}${ZSH_THEME_GIT_PROMPT_SUFFIX}"
  else
    # Detached HEAD - display: (hash*, tags, branches (detached))
    local hash=$(git rev-parse --short HEAD 2>/dev/null)
    local hash_color="%F{078}"
    
    # Re-apply green color after dirty asterisk
    local first_part="${hash}${dirty}${hash_color}"

    # Get tags and branches, splitting by line and joining with comma+space
    local tags=$(git tag --points-at HEAD 2>/dev/null)
    tags="${(j:, :)${(f)tags}}"
    
    local branches=$(git branch --points-at HEAD --format='%(refname:short)' 2>/dev/null | grep -v "(HEAD detached")
    branches="${(j:, :)${(f)branches}}"

    # Define the yellow detached label
    # The word "detached" is yellow, the parens match the theme's prefix color (075)
    local detached_label=" %F{075}(%F{226}detached%F{075})%f"

    local second_part=""
    if [[ -n "$tags" && -n "$branches" ]]; then
      second_part=", ${tags}, ${branches}"
    elif [[ -n "$tags" ]]; then
      second_part=", ${tags}"
    elif [[ -n "$branches" ]]; then
      second_part=", ${branches}"
    fi

    echo "${ZSH_THEME_GIT_PROMPT_PREFIX}${first_part}${second_part}${detached_label}${ZSH_THEME_GIT_PROMPT_SUFFIX}"
  fi
}
