#!/usr/bin/env bash
#
# cycle.sh - Cycle through Claude notifications
#
# Behavior:
# - First press: jump to oldest notification
# - Next press: cycle to next notification
# - Wraps around when reaching the end
# - Clears notification after jumping to it
#

set -euo pipefail

STATE_DIR="${TMPDIR:-/tmp}/claude-tmux-notify"
NOTIFICATIONS_FILE="$STATE_DIR/notifications"
CYCLE_INDEX_FILE="$STATE_DIR/cycle_index"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get list of valid notifications
get_valid_notifications() {
	local notifications=()

	if [[ ! -f "$NOTIFICATIONS_FILE" ]]; then
		return
	fi

	while IFS='|' read -r timestamp session window pane type message; do
		# Skip empty lines
		[[ -z "$timestamp" ]] && continue

		# Check if session still exists
		if tmux has-session -t "$session" 2>/dev/null; then
			# Check if window still exists
			if tmux list-windows -t "$session" -F '#{window_index}' 2>/dev/null | grep -q "^${window}$"; then
				notifications+=("${timestamp}|${session}|${window}|${pane}|${type}|${message}")
			fi
		fi
	done <"$NOTIFICATIONS_FILE"

	# Sort by timestamp (oldest first)
	printf '%s\n' "${notifications[@]}" | sort -t'|' -k1 -n
}

# Get current cycle index
get_cycle_index() {
	if [[ -f "$CYCLE_INDEX_FILE" ]]; then
		cat "$CYCLE_INDEX_FILE"
	else
		echo 0
	fi
}

# Save cycle index
save_cycle_index() {
	echo "$1" >"$CYCLE_INDEX_FILE"
}

# Jump to a notification
jump_to_notification() {
	local session="$1"
	local window="$2"
	local pane="$3"

	# Switch to session and window
	tmux switch-client -t "$session"
	tmux select-window -t "$session:$window"
	tmux select-pane -t "$session:$window.$pane"
}

# Main
main() {
	# Get valid notifications as array
	local notifications_str
	notifications_str=$(get_valid_notifications)

	if [[ -z "$notifications_str" ]]; then
		tmux display-message "No Claude notifications"
		rm -f "$CYCLE_INDEX_FILE"
		return
	fi

	# Convert to array
	local -a notifications
	mapfile -t notifications <<<"$notifications_str"
	local count=${#notifications[@]}

	# Get current index
	local index
	index=$(get_cycle_index)

	# Wrap around if needed
	if [[ "$index" -ge "$count" ]]; then
		index=0
	fi

	# Get notification at current index
	local notification="${notifications[$index]}"
	IFS='|' read -r timestamp session window pane type message <<<"$notification"

	# Jump to it
	jump_to_notification "$session" "$window" "$pane"

	# Display message
	tmux display-message "Claude: $message ($session:$window)"

	# Clear this notification
	"$CURRENT_DIR/clear.sh" "$session" "$window" "$pane"

	# Increment index for next cycle
	local next_index=$(((index + 1) % count))

	# If we've cycled through all, reset
	if [[ "$next_index" -eq 0 ]] && [[ "$count" -gt 1 ]]; then
		tmux display-message "Claude: $message ($session:$window) [last notification]"
	fi

	save_cycle_index "$next_index"
}

main
