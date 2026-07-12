#!/usr/bin/env bash

get_tmux_option() {
    local option=$1
    local default_value="$2"

    local option_value
    option_value=$(tmux show-options -gqv "$option")

    if [ "$option_value" != "" ]; then
        echo "$option_value"
        return
    fi
    echo "$default_value"
}

default_color="#[bg=default,fg=default,bold]"

# theme options
bg=$(get_tmux_option "@minimal-tmux-bg" '#698DDA')
fg=$(get_tmux_option "@minimal-tmux-fg" '#000000')

use_arrow=$(get_tmux_option "@minimal-tmux-use-arrow" false)
larrow="$("$use_arrow" && get_tmux_option "@minimal-tmux-left-arrow" "")"
rarrow="$("$use_arrow" && get_tmux_option "@minimal-tmux-right-arrow" "")"

status=$(get_tmux_option "@minimal-tmux-status" "bottom")
justify=$(get_tmux_option "@minimal-tmux-justify" "centre")

indicator_state=$(get_tmux_option "@minimal-tmux-indicator" true)
indicator_str=$(get_tmux_option "@minimal-tmux-indicator-str" " tmux ")
indicator=$("$indicator_state" && echo " $indicator_str ")

right_state=$(get_tmux_option "@minimal-tmux-right" true)
left_state=$(get_tmux_option "@minimal-tmux-left" true)

status_right=$("$right_state" && get_tmux_option "@minimal-tmux-status-right" "#S")
status_left=$("$left_state" && get_tmux_option "@minimal-tmux-status-left" "${default_color}#{?client_prefix,,${indicator}}#[bg=${bg},fg=${fg},bold]#{?client_prefix,${indicator},}${default_color}")
status_right_extra="$status_right$(get_tmux_option "@minimal-tmux-status-right-extra" "")"
status_left_extra="$status_left$(get_tmux_option "@minimal-tmux-status-left-extra" "")"

# --- window name toggle aware ---

# @win_names == 1  → show names
# @win_names == 0  → hide names
win_names=$(get_tmux_option "@win_names" "1")
if [ "$win_names" = "1" ]; then
    default_window_format=' #I:#W '
else
    default_window_format=' #I '
fi

window_status_format=$(get_tmux_option "@minimal-tmux-window-status-format" "$default_window_format")

expanded_icon=$(get_tmux_option "@minimal-tmux-expanded-icon" '󰊓 ')
show_expanded_icon_for_all_tabs=$(get_tmux_option "@minimal-tmux-show-expanded-icon-for-all-tabs" false)

# --- apply to tmux ---

tmux set-option -g status-position "$status"
tmux set-option -g status-style bg=default,fg=default
tmux set-option -g status-justify "$justify"

tmux set-option -g status-left "$status_left_extra"
tmux set-option -g status-right "$status_right_extra"

tmux set-option -g window-status-style bg=default
tmux set-option -g window-status-current-style bg=default
tmux set-option -g window-status-activity-style bg=default

inactive_bg=$(get_tmux_option "@minimal-tmux-inactive-bg" "#1a1b26")
inactive_fg=$(get_tmux_option "@minimal-tmux-inactive-fg" "#565f89")

tmux set-option -g window-status-format "#[fg=${inactive_bg}]$larrow#[bg=default,fg=${inactive_fg}]${window_status_format}#[fg=${inactive_bg},bg=default]$rarrow"
"$show_expanded_icon_for_all_tabs" &&
    tmux set-option -g window-status-format "#[fg=${inactive_bg}]$larrow#[bg=default,fg=${inactive_fg}]${window_status_format}#{?window_zoomed_flag,${expanded_icon},}#[fg=${inactive_bg},bg=default]$rarrow"

tmux set-option -g window-status-current-format "#[fg=${bg}]$larrow#[bg=default,fg=${bg},bold]${window_status_format}#{?window_zoomed_flag,${expanded_icon},}#[fg=${bg},bg=default]$rarrow"
