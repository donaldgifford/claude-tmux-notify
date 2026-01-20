#!/usr/bin/env bash
#
# notify.sh - Called by Claude Code hook to register a notification
#
# Usage:
#   notify.sh [options]
#
# Options:
#   -s, --session SESSION   tmux session name (auto-detected if not provided)
#   -w, --window WINDOW     tmux window index (auto-detected if not provided)
#   -p, --pane PANE         tmux pane index (auto-detected if not provided)
#   -t, --type TYPE         notification type: input, permission, error (default: input)
#   -m, --message MESSAGE   notification message
#

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${TMPDIR:-/tmp}/claude-tmux-notify"
NOTIFICATIONS_FILE="$STATE_DIR/notifications"
HANDLERS_DIR="$CURRENT_DIR/handlers"

# Ensure state directory exists
mkdir -p "$STATE_DIR"

# Default values
SESSION=""
WINDOW=""
PANE=""
TYPE="input"
MESSAGE="Waiting for user input"

# Parse arguments
while [[ $# -gt 0 ]]; do
	case $1 in
	-s | --session)
		SESSION="$2"
		shift 2
		;;
	-w | --window)
		WINDOW="$2"
		shift 2
		;;
	-p | --pane)
		PANE="$2"
		shift 2
		;;
	-t | --type)
		TYPE="$2"
		shift 2
		;;
	-m | --message)
		MESSAGE="$2"
		shift 2
		;;
	*)
		shift
		;;
	esac
done

# Auto-detect tmux context if not provided
detect_tmux_context() {
	# Check if we're in tmux
	if [[ -z "${TMUX:-}" ]]; then
		echo "Error: Not running inside tmux" >&2
		exit 1
	fi

	# Get current session, window, and pane if not provided
	if [[ -z "$SESSION" ]]; then
		SESSION=$(tmux display-message -p '#{session_name}')
	fi

	if [[ -z "$WINDOW" ]]; then
		WINDOW=$(tmux display-message -p '#{window_index}')
	fi

	if [[ -z "$PANE" ]]; then
		PANE=$(tmux display-message -p '#{pane_index}')
	fi
}

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

# Write notification to state file
write_notification() {
	local timestamp
	timestamp=$(date +%s)

	# Remove any existing notification for this session/window/pane
	if [[ -f "$NOTIFICATIONS_FILE" ]]; then
		local temp_file="$STATE_DIR/notifications.tmp"
		grep -v "^[0-9]*|${SESSION}|${WINDOW}|${PANE}|" "$NOTIFICATIONS_FILE" >"$temp_file" 2>/dev/null || true
		mv "$temp_file" "$NOTIFICATIONS_FILE"
	fi

	# Append new notification
	echo "${timestamp}|${SESSION}|${WINDOW}|${PANE}|${TYPE}|${MESSAGE}" >>"$NOTIFICATIONS_FILE"
}

# Trigger notification handlers
trigger_handlers() {
	local methods
	methods=$(get_tmux_option @claude-tmux-notify-methods 'tmux')

	# Split methods by comma and trigger each
	IFS=',' read -ra METHOD_ARRAY <<<"$methods"
	for method in "${METHOD_ARRAY[@]}"; do
		method=$(echo "$method" | xargs) # trim whitespace
		local handler="$HANDLERS_DIR/${method}.sh"
		if [[ -x "$handler" ]]; then
			"$handler" "$SESSION" "$WINDOW" "$PANE" "$TYPE" "$MESSAGE" &
		fi
	done
}

# Main
main() {
	detect_tmux_context
	write_notification
	trigger_handlers
}

main
