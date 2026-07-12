_GAT_VERSION="1.0.0"
_GAT_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/theme.yml"

# ── Reset to Ghostty config defaults ─────────────────────────
_gat_reset() {
  printf '\e]110\e\\\e]111\e\\\e]112\e\\\e]104\e\\'
  if [[ -n "$TMUX" ]]; then
    tmux select-pane -P "bg=default"
  fi
}

# ── Locate a Ghostty theme file by name ──────────────────────
# Prints path on stdout. Returns 1 if not found.
_gat_find_theme() {
  local name="$1"
  local search_dirs=(
    "${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/themes"
    "/Applications/Ghostty.app/Contents/Resources/ghostty/themes"
  )
  if [[ -n "$XDG_DATA_DIRS" ]]; then
    local dir
    for dir in ${(s/:/)XDG_DATA_DIRS}; do
      search_dirs+=("$dir/ghostty/themes")
    done
  fi
  local d
  for d in "${search_dirs[@]}"; do
    if [[ -f "$d/$name" ]]; then
      printf '%s' "$d/$name"
      return 0
    fi
  done
  return 1
}

# ── Parse a Ghostty theme file into OSC escape sequences ─────
# When skip_bg=1, background is omitted from OSC (for tmux pane-style usage).
_gat_parse_theme() {
  local theme_file="$1" skip_bg="${2:-0}"
  awk -v skip_bg="$skip_bg" '
    BEGIN { FS = " = " }
    /^foreground/   { printf "\\e]10;%s\\e\\\\", $2 }
    /^background/   { if (!skip_bg) printf "\\e]11;%s\\e\\\\", $2 }
    /^cursor-color/ { printf "\\e]12;%s\\e\\\\", $2 }
    /^palette/ {
      split($2, a, "=")
      printf "\\e]4;%s;%s\\e\\\\", a[1], a[2]
    }
  ' "$theme_file"
}

# ── Parse config and create wrapper functions ────────────────
_gat_init() {
  if [[ ! -f "$_GAT_CONFIG" ]]; then
    return 0
  fi

  local pairs
  pairs=$(awk '
    /^  [a-zA-Z0-9_-]+:/ {
      tool = $1; gsub(/:/, "", tool)
    }
    /^    theme:/ {
      t = $0
      sub(/^    theme: *"?'\''?/, "", t)
      sub(/"?'\''? *$/, "", t)
      print tool "\t" t
    }
  ' "$_GAT_CONFIG")

  local tool theme_name theme_file osc_seq _invoke
  while IFS=$'\t' read -r tool theme_name; do
    [[ -z "$tool" ]] && continue

    theme_file=$(_gat_find_theme "$theme_name")
    if [[ $? -ne 0 ]]; then
      printf 'ghostty-ai-themes: theme "%s" not found for "%s", skipping\n' \
        "$theme_name" "$tool" >&2
      continue
    fi

    if [[ -n "$TMUX" ]]; then
      # Theme fg/cursor/palette only. Any explicit bg -- OSC 11 or a tmux
      # pane-style -- makes cells opaque and punches a solid rectangle through
      # Ghostty's background-opacity/blur. Leaving cells on the default bg keeps
      # the pane translucent.
      osc_seq=$(_gat_parse_theme "$theme_file" 1)
    else
      osc_seq=$(_gat_parse_theme "$theme_file" 0)
    fi

    if (( $+functions[$tool] )); then
      eval "functions[_gat_orig_${tool}]=\"\$functions[$tool]\""
      _invoke="_gat_orig_${tool}"
    else
      _invoke="command ${tool}"
    fi

    eval "${tool}() {
      printf '${osc_seq}'
      {
        ${_invoke} \"\$@\"
      } always {
        _gat_reset
      }
    }"
  done <<< "$pairs"
}

# ── Auto-initialize, deferred to first prompt ────────────────
# Ghostty's shell integration injects its ssh wrapper via precmd
# after .zshrc finishes. Deferring ensures we can capture it.
_gat_deferred_init() {
  precmd_functions=(${precmd_functions:#_gat_deferred_init})
  _gat_init
  unfunction _gat_deferred_init 2>/dev/null
}
precmd_functions+=(_gat_deferred_init)
