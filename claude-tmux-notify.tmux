#!/usr/bin/env bash
#
# tmux-claude-notify - TPM entry point
# Notifies when Claude Code is waiting for input in tmux sessions
#

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$CURRENT_DIR/scripts"

# Get tmux option with default value
get_tmux_option() {
	local option="$1"
	local default_value="$2"
	local option_value
	option_value=$(tmux show-option -gqv "$option")
	if [[ -z "$option_value" ]]; then
		echo "$default_value"
	else
		echo "$option_value"
	fi
}

# Set default options if not already set
set_default_options() {
	# Only set if not already defined
	[[ -z "$(tmux show-option -gqv @claude-notify-cycle-key)" ]] &&
		tmux set-option -g @claude-notify-cycle-key 'C-c'

	[[ -z "$(tmux show-option -gqv @claude-notify-icon)" ]] &&
		tmux set-option -g @claude-notify-icon '🤖'

	[[ -z "$(tmux show-option -gqv @claude-notify-clear-on-focus)" ]] &&
		tmux set-option -g @claude-notify-clear-on-focus 'on'

	[[ -z "$(tmux show-option -gqv @claude-notify-picker-key)" ]] &&
		tmux set-option -g @claude-notify-picker-key 'C-y'

	[[ -z "$(tmux show-option -gqv @claude-notify-picker-size)" ]] &&
		tmux set-option -g @claude-notify-picker-size '60%,50%'
}

# Set up keybindings
setup_keybindings() {
	local cycle_key
	cycle_key=$(get_tmux_option @claude-notify-cycle-key 'C-c')
	tmux bind-key "$cycle_key" run-shell "$SCRIPTS_DIR/cycle.sh"

	local picker_key
	picker_key=$(get_tmux_option @claude-notify-picker-key 'C-n')
	tmux bind-key "$picker_key" run-shell "$SCRIPTS_DIR/fzf-picker.sh"
}

# Set up tmux hooks for auto-clear on focus
setup_hooks() {
	local clear_on_focus
	clear_on_focus=$(get_tmux_option @claude-notify-clear-on-focus 'on')

	if [[ "$clear_on_focus" == "on" ]]; then
		tmux set-hook -g pane-focus-in "run-shell '$SCRIPTS_DIR/clear.sh current'"
	fi
}

# Initialize state directory
init_state_dir() {
	local state_dir="${TMPDIR:-/tmp}/claude-tmux-notify"
	mkdir -p "$state_dir"

	# Create empty notifications file if it doesn't exist
	touch "$state_dir/notifications"
}

# Main initialization
main() {
	set_default_options
	setup_keybindings
	setup_hooks
	init_state_dir
}

main
