# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="af-magic"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git fzf z)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Stop zsh from piping some commands into `less`
unset LESS

alias kc="kubectl"

# Ensures that any tools installed with brew are available on the PATH
eval "$(/opt/homebrew/bin/brew shellenv)"

# Adds iterm2 utilities to the PATH
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Ensures that any tools installed with mise are available on the PATH
eval "$(mise activate zsh)"

# Created by `pipx` on 2024-12-18 23:04:53
export PATH="$PATH:/Users/don.nguyen/.local/bin"

# pnpm
export PNPM_HOME="/Users/don.nguyen/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

export EDITOR="vim"

# Jujutsu (jj) prompt support for af-magic theme
function jj_prompt_info() {
  if (( ! $+commands[jj] )); then
    return
  fi

  # Check if we're in a jj repo
  if ! jj root --quiet &>/dev/null; then
    return
  fi

  local PREFIX="${ZSH_THEME_JJ_PROMPT_PREFIX:-$ZSH_THEME_GIT_PROMPT_PREFIX}"
  local SUFFIX="${ZSH_THEME_JJ_PROMPT_SUFFIX:-$ZSH_THEME_GIT_PROMPT_SUFFIX}"
  local DIRTY="${ZSH_THEME_JJ_PROMPT_DIRTY:-$ZSH_THEME_GIT_PROMPT_DIRTY}"
  local CLEAN="${ZSH_THEME_JJ_PROMPT_CLEAN:-$ZSH_THEME_GIT_PROMPT_CLEAN}"

  # Get parent bookmark names or commit hash
  # Use map(|b| b.name()) to ensure we get just the names without status markers like *
  local parent_info=$(jj log -r @- -n 1 --no-graph --color=never -T 'if(bookmarks, bookmarks.map(|b| b.name()).join(", "), commit_id.short())' 2>/dev/null)
  
  # Check if working copy (@) is dirty (not empty)
  # jj returns "true" if the commit is empty, "false" otherwise
  local is_empty=$(jj log -r @ -n 1 --no-graph --color=never -T 'empty' 2>/dev/null)

  local jj_status=""
  if [[ "$is_empty" == "false" ]]; then
    jj_status="$DIRTY"
  else
    jj_status="$CLEAN"
  fi

  echo "${PREFIX}${parent_info}${jj_status}${SUFFIX}"
}

# Match af-magic colors for jj
ZSH_THEME_JJ_PROMPT_PREFIX=" ${FG[075]}(${FG[078]}"
ZSH_THEME_JJ_PROMPT_CLEAN=""
ZSH_THEME_JJ_PROMPT_DIRTY="${FG[214]}*%{$reset_color%}"
ZSH_THEME_JJ_PROMPT_SUFFIX="${FG[075]})%{$reset_color%}"

# A wrapper to choose between JJ and Git/Hg prompts to avoid double parens
function vcs_prompt_info() {
  if jj root --quiet &>/dev/null; then
    jj_prompt_info
  else
    echo "$(git_prompt_info)$(hg_prompt_info)"
  fi
}

# Override PS1 to use our vcs_prompt_info wrapper
# Note: We must do this after sourcing oh-my-zsh.sh
PS1="${FG[237]}\${(l.\$(afmagic_dashes)..-.)}%{$reset_color%}
${FG[032]}%~\$(vcs_prompt_info) ${FG[105]}%(!.#.»)%{$reset_color%} "
