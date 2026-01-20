#!/usr/bin/env bash
#
# status.sh - Status bar widget showing notification count
#
# Output: Formatted string for tmux status bar
# - No notifications: empty string
# - Has notifications: "🤖 3" (icon + count)
#

set -euo pipefail

STATE_DIR="${TMPDIR:-/tmp}/claude-tmux-notify"
NOTIFICATIONS_FILE="$STATE_DIR/notifications"

# Get tmux option
get_tmux_option() {
	local option="$1"
	local default_value="$2"
	local option_value
	option_value=$(tmux show-option -gqv "$option" 2>/dev/null || echo "")
	if [[ -z "$option_value" ]]; then
		echo "$default_value"
	else
		echo "$option_value"
	fi
}

# Count valid notifications (filter out stale ones for closed sessions/windows)
count_notifications() {
	local count=0

	if [[ ! -f "$NOTIFICATIONS_FILE" ]]; then
		echo 0
		return
	fi

	while IFS='|' read -r timestamp session window _pane _type _message; do
		# Skip empty lines
		[[ -z "$timestamp" ]] && continue

		# Check if session still exists
		if tmux has-session -t "$session" 2>/dev/null; then
			# Check if window still exists
			if tmux list-windows -t "$session" -F '#{window_index}' 2>/dev/null | grep -q "^${window}$"; then
				((count++))
			fi
		fi
	done <"$NOTIFICATIONS_FILE"

	echo "$count"
}

# Main
main() {
	local count
	count=$(count_notifications)

	if [[ "$count" -eq 0 ]]; then
		echo ""
	else
		local icon
		icon=$(get_tmux_option @claude-notify-icon '🤖')
		echo "${icon} ${count} "
	fi
}

main
