#!/usr/bin/env bash
#
# clear.sh - Clear Claude notifications
#
# Usage:
#   clear.sh current              - Clear notification for current session/window/pane
#   clear.sh all                  - Clear all notifications
#   clear.sh SESSION WINDOW PANE  - Clear specific notification
#

set -euo pipefail

STATE_DIR="${TMPDIR:-/tmp}/claude-tmux-notify"
NOTIFICATIONS_FILE="$STATE_DIR/notifications"

# Ensure state directory exists
mkdir -p "$STATE_DIR"

# Clear all notifications
clear_all() {
	: >"$NOTIFICATIONS_FILE"
	rm -f "$STATE_DIR/cycle_index"
}

# Clear specific notification
clear_specific() {
	local session="$1"
	local window="$2"
	local pane="$3"

	if [[ ! -f "$NOTIFICATIONS_FILE" ]]; then
		return
	fi

	local temp_file="$STATE_DIR/notifications.tmp"
	grep -v "^[0-9]*|${session}|${window}|${pane}|" "$NOTIFICATIONS_FILE" >"$temp_file" 2>/dev/null || true
	mv "$temp_file" "$NOTIFICATIONS_FILE"
}

# Clear notification for current pane
clear_current() {
	# Check if we're in tmux
	if [[ -z "${TMUX:-}" ]]; then
		return
	fi

	local session window pane
	session=$(tmux display-message -p '#{session_name}')
	window=$(tmux display-message -p '#{window_index}')
	pane=$(tmux display-message -p '#{pane_index}')

	clear_specific "$session" "$window" "$pane"
}

# Main
main() {
	local mode="${1:-current}"

	case "$mode" in
	all)
		clear_all
		;;
	current)
		clear_current
		;;
	*)
		# Assume it's session window pane
		if [[ $# -ge 3 ]]; then
			clear_specific "$1" "$2" "$3"
		else
			echo "Usage: clear.sh [current|all|SESSION WINDOW PANE]" >&2
			exit 1
		fi
		;;
	esac
}

main "$@"
