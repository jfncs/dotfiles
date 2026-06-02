# functions.zsh

# ---- sesh
 function sesh-sessions() {
  {
    exec </dev/tty
    exec <&1
    local session
    session=$(sesh list -t -c | fzf --height 40% --reverse --border-label ' sesh ' --border --prompt '⚡  ')
    zle reset-prompt > /dev/null 2>&1 || true
    [[ -z "$session" ]] && return
    sesh connect $session
  }
}

zle     -N             sesh-sessions
bindkey -M emacs '\es' sesh-sessions
bindkey -M vicmd '\es' sesh-sessions
bindkey -M viins '\es' sesh-sessions
# -----

function uvrun() {
    uv run $1
}

function ipof() {
  getent hosts "$1" | awk '{print $1}'
}

function mkcd () {
  mkdir -p -- "$1" && cd -- "$1"
}

function mvip() {
  local src="$1"
  local newname="$2"
  mv -i -- "$src" "${src:h}/$newname"
}


function ca() {
    pick_local_env() {
        local env
        env=$(\ls /local/$USER/venv 2>/dev/null | fzf --height 40% --border)
        [[ -n "$env" ]] && source "/local/$USER/venv/$env/bin/activate" || echo "No environment selected."
    }

    pick_conda_env() {
        local env
        env=$(conda env list | sed '1,3d; s/ .*$//' | fzf --height 40% --border)
        [[ -n "$env" ]] && conda activate "$env" || echo "No environment selected."
    }

    case "$1" in
        --conda)
            pick_conda_env
            ;;
        --all|"")
            if [[ -d .venv ]]; then
                source .venv/bin/activate
            elif [[ -d venv ]]; then
                source venv/bin/activate
            elif [[ -d /local/$USER/venv ]]; then
                pick_local_env
            else
                pick_conda_env
            fi
            ;;
        *)
            if [[ -d "/local/$USER/venv/$1" ]]; then
                source "/local/$USER/venv/$1/bin/activate"
            elif conda env list | grep -q "^$1 "; then
                conda activate "$1"
            else
                echo "Environment '$1' not found."
                return 1
            fi
            ;;
    esac
}

function da() {
    if [[ "$CONDA_DEFAULT_ENV" != "" ]]; then
        conda deactivate # If conda env is active
    elif [[ "$VIRTUAL_ENV" != "" ]]; then
        deactivate
    else
        echo "No virtual environment is active."
    fi
}

# C-z for background/foreground processes
fancy-ctrl-z() {
    if [[ $#BUFFER -eq 0 ]]; then
        fg &>/dev/null
    else
        zle push-input
        zle clear-screen
    fi
}
zle -N fancy-ctrl-z
bindkey '^Z' fancy-ctrl-z

# yazi file viewer
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[[ "$cwd" != "$PWD" ]] && [[ -d "$cwd" ]] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

function claude-vllm() {
    CLAUDE_CONFIG_DIR="$HOME/.claude-vllm" command claude "$@"
}

