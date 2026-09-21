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
# ----

function uvrun() {
    uv run "$@"
}

function ipof() {
  if (( $+commands[dig] )); then
    dig +short "$1"
  else
    getent hosts "$1" | awk '{print $1}'
  fi
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

# local (todo extend grok/codex/hermes/oc)
function claude-vllm() {
    CLAUDE_CONFIG_DIR="$HOME/.claude-vllm" command claude "$@"
}

# back to the repo's main checkout, from any worktree
gwm() {
    cd "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")" || return 1
}

# vendors: init this worktree's submodules borrowing objects from the main checkout
# usage: gws [name]   (no args = all submodules from .gitmodules)
gws() {
    local main sub
    local -a ref
    main=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)") || return 1
    if [ -n "$1" ]; then
        ref=()
        [ -e "$main/vendors/$1/.git" ] && ref=(--reference "$main/vendors/$1")
        git submodule update --init $ref "vendors/$1"
        return
    fi
    for sub in $(git config --file .gitmodules --get-regexp '\.path$' | awk '{print $2}'); do
        ref=()
        [ -e "$main/$sub/.git" ] && ref=(--reference "$main/$sub")
        git submodule update --init $ref "$sub"
    done
}

# shared delete: remove worktree, prompt about leftovers, optionally delete branch
function _gwt_remove() {
    local dest="$1" branch="$2" do_branch="$3" ans
    # --force: worktrees with submodules refuse removal otherwise
    git worktree remove --force "$dest" || true
    # git can leave files behind (ignored files, submodule internals, NFS)
    # or fail with "Directory not empty"; confirm before wiping leftovers
    if [ -d "$dest" ]; then
        echo "files remain in $dest:"
        ls -A "$dest" | sed 's/^/  /'
        read "ans?Delete the leftovers? [Y/n] "
        if [[ -z "$ans" || "$ans" == [Yy]* ]]; then
            rm -rf "$dest"
            git worktree prune
        else
            echo "left $dest in place; remove it manually when ready" >&2
            return 1
        fi
    fi
    if [[ "$do_branch" = "1" && -n "$branch" ]]; then
        git branch -d "$branch"
    fi
    return 0
}

# worktree: hop into existing, check out existing branch, or create from base
function gwt() {
    local main repo parent branch base dest
    main=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)") || return 1
    repo=$(basename "$main")
    parent=$(dirname "$main")

    if [ "$1" = "rm" ]; then
        branch="$2"
        dest="$parent/$repo.worktrees/$branch"
        [ -n "$branch" ] || { echo "usage: gwt rm <branch> [-d]" >&2; return 1; }
        [ -d "$dest" ] || { echo "no worktree for $branch" >&2; return 1; }
        local do_branch=0
        [[ "$3" = "-d" ]] && do_branch=1
        _gwt_remove "$dest" "$branch" "$do_branch"
        return $?
    fi

    # gwt -d → pick a worktree to delete; selecting starts the delete process
    if [ "$1" = "-d" ]; then
        local sel
        sel=$(git worktree list | awk -v m="$main" '$1 != m' \
            | fzf --height=40% --layout=reverse --prompt='delete worktree> ') || return 0
        dest=$(awk '{print $1}' <<<"$sel")
        branch=$(git -C "$dest" rev-parse --abbrev-ref HEAD 2>/dev/null)
        [[ "$branch" = "HEAD" || -z "$branch" ]] && branch=""
        echo "deleting worktree $dest"
        _gwt_remove "$dest" "$branch" 1
        return $?
    fi

    branch="$1"
    # default base: whatever branch the main checkout is on, else origin/main
    local hub_branch
    hub_branch=$(git -C "$main" rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ -n "$hub_branch" && "$hub_branch" != "HEAD" ]]; then
        base="${2:-origin/$hub_branch}"
    else
        base="${2:-origin/main}"
    fi

    # no args → pick an existing worktree via fzf
    if [ -z "$branch" ]; then
        local sel
        sel=$(git worktree list | fzf --height=40% --layout=reverse --prompt='worktree> ') || return 0
        cd "$(awk '{print $1}' <<<"$sel")" || return 1
        return 0
    fi
    dest="$parent/$repo.worktrees/$branch"

    # worktree already exists → just hop in
    if [ -d "$dest" ]; then
        cd "$dest" || return 1
        return 0
    fi

    if git show-ref --verify --quiet "refs/heads/$branch"; then
        git worktree add "$dest" "$branch" || return 1
    elif git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
        git worktree add "$dest" -b "$branch" "origin/$branch" || return 1
    else
        git worktree add "$dest" -b "$branch" "$base" || return 1
    fi

    # hint: submodules don't materialize in new worktrees
    [ -f "$dest/.gitmodules" ] && echo "hint: run 'gws' to init vendors from the main checkout"

    # share harness skills from the main checkout (AGENTS.md is branch-tracked)
    if [ -d "$main/.focus/skills" ]; then
        [ -d "$dest/.focus" ] || mkdir -p "$dest/.focus"
        [ ! -e "$dest/.focus/skills" ] && ln -s "$main/.focus/skills" "$dest/.focus/skills"
    fi
    cd "$dest" || return 1
}

# sesh connect with fzf
sj() {
  if [[ "$1" == "." ]]; then
    sesh connect "$(basename "$PWD")"
  else
    sesh connect "$(sesh list | fzf --preview 'bat --color=always {}')"
  fi
}

# opencode2 session picker with fzf
oc2s() {
  if ! (( $+commands[opencode2] )); then
    echo "opencode2 not found" >&2
    return 1
  fi
  if ! (( $+commands[jq] )); then
    echo "jq not found" >&2
    return 1
  fi
  if ! (( $+commands[fzf] )); then
    echo "fzf not found" >&2
    return 1
  fi

  local selected session_id
  selected=$(
    opencode2 session list --format json |
      jq -r '.[] | [.id, (.title // "Untitled"), ((.updated / 1000) | strftime("%Y-%m-%d %H:%M")), (.directory // "")] | @tsv' |
      fzf \
        --height 60% \
        --layout=reverse \
        --border \
        --header='Session ID	Title	Updated' \
        --prompt='opencode session> ' \
        --delimiter=$'\t' \
        --with-nth=1,2,3 \
        --preview='printf "id: %s\ntitle: %s\nupdated: %s\ndirectory: %s\n" {1} {2} {3} {4}'
  ) || return 0

  session_id="${selected%%$'\t'*}"
  [[ -n "$session_id" ]] && opencode2 -s "$session_id" "$@"
}

# nvim with fzf
nsj() {
  nvim "$(fzf --preview 'bat --color=always {}')"
}
