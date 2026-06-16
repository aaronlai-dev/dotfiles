# ======================================================
# Zinit
# ======================================================

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "$ZINIT_HOME/zinit.zsh"

# Plugins
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
zinit light Aloxaf/fzf-tab

# Oh My Zsh snippets, without loading full Oh My Zsh
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found

autoload -Uz compinit && compinit
zinit cdreplay -q


# ======================================================
# History
# ======================================================

HISTSIZE=5000
HISTFILE="$HOME/.zsh_history"
SAVEHIST=$HISTSIZE

setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups


# ======================================================
# Homebrew / Shell integrations
# ======================================================

eval "$(/opt/homebrew/bin/brew shellenv)"

command -v mise >/dev/null && eval "$(mise activate zsh)"
command -v zoxide >/dev/null && eval "$(zoxide init --cmd cd zsh)"
command -v direnv >/dev/null && eval "$(direnv hook zsh)"
command -v fzf >/dev/null && eval "$(fzf --zsh)"


# ======================================================
# PATH
# ======================================================

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$HOME/.bun/bin:$HOME/.local/bin:$PATH"


# ======================================================
# FZF
# ======================================================

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

export FZF_DEFAULT_OPTS=" \
  --color=fg:#F8F8F2,bg:#282A36,hl:#a277ff \
  --color=fg+:#F8F8F2,bg+:#44475A,hl+:#a277ff \
  --color=info:#82e2ff,prompt:#61ffca,pointer:#a277ff \
  --color=marker:#61ffca,spinner:#61ffca,header:#82e2ff"

# Better previews with bat
if command -v bat >/dev/null; then
  export FZF_CTRL_T_OPTS="
    --preview 'bat --style=numbers --color=always {}' "
fi

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview '
  eza --icons --tree --level=2 "$realpath" 2>/dev/null
'
zstyle ':fzf-tab:complete:*:*' fzf-preview '
  [[ -f "$realpath" ]] && bat --style=numbers --color=always "$realpath" 2>/dev/null
'

# ======================================================
# Aliases
# ======================================================

if command -v eza >/dev/null; then
  alias ls='eza --icons'
  alias ll='eza --icons -lah'
  alias la='eza --icons -a'
  alias lt='eza --icons --tree --level=2'
else
  alias ls='ls --color=auto'
  alias ll='ls -lah'
fi

if command -v bat >/dev/null; then
  alias cat='bat'
fi

alias ll='ls -lah'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gcane='git commit --amend --no-edit'
alias gp='git push'
alias gl='git pull'
alias fix='git absorb --and-rebase'

alias mr='mise run'

# ======================================================
# Functions
# ======================================================

mkcd() {
  mkdir -p "$1" && cd "$1"
}


# ======================================================
# Bun completions
# ======================================================

[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# ======================================================
# Starship Prompt
# ======================================================

eval "$(starship init zsh)"
eval "$(~/.local/bin/mise activate zsh)"

# ======================================================
# Zoxide
# ======================================================

eval "$(zoxide init zsh)"
