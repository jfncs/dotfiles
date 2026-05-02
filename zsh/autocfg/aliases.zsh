# aliases.zsh

alias LL="eza -1lF --icons=always --color --long --git -s modified --total-size -o"
alias l="eza --color -l --icons=always --no-user --no-permissions -s type -s modified --group-directories-first -o --time-style relative" # --git
alias ll="eza --color -l --icons=always --no-permissions -s type -s name --all --group-directories-first -o --time-style relative" # --git
alias lt="eza -1T"
alias ls="ls -l"
alias rp="realpath"

alias gp="git pull --rebase"
alias gP="git push"
alias gs="git status"
alias gd="git diff"
alias ga="git add -u ."
alias gsP="git stash push"
alias gsp="git stash pop"

alias vim="nvim"
alias zz="vim ~/.zshrc"
alias python="python3"
alias py="ipython"
alias help="tldr"

# Shortcuts
alias gg="lazygit"
alias lzd="lazydocker"
alias k="kubectl"

alias dfh="df -H --output=source,fstype,size,used,avail,pcent,target"

alias tmx="tmux -CC new -A -s main"
alias tmxa="tmux -CC attach -t main"
alias cat="bat"

alias brewup='brew update && brew upgrade && brew upgrade --cask --greedy && brew cleanup'
alias aliases="nvim ~/.dotfiles/zsh/autocfg/aliases.zsh"

alias gdrive="cd ~/Google\ Drive/My\ Drive/"
alias work="cd ~/work/"
alias pers="cd ~/personal/"
alias dev="cd ~/dev"

# Move and Edit
alias dots="cd ~/.dotfiles/; vim zsh/zshrc"
alias obs="cd ~/Obs; vim"

alias jup="jupyter lab --autoreload --no-browser . &!"


sj() {
  if [[ "$1" == "." ]]; then
    sesh connect "$(basename "$PWD")"
  else
    sesh connect "$(sesh list | fzf --preview 'bat --color=always {}')"
  fi
}

nsj() {
  nvim "$(fzf --preview 'bat --color=always {}')"
}
