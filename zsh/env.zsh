# Environment and tool initialization
# This file is automatically sourced by Oh My Zsh (ZSH_CUSTOM)

# Created by `pipx` on 2024-12-18 23:04:53
export PATH="$PATH:$HOME/.local/bin"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

export EDITOR="vim"

# Adds iterm2 utilities to the PATH
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

