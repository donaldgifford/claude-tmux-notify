#!/usr/bin/env bash
#
# fzf-picker.sh - fzf popup to select and jump to Claude notifications
#
# Shows a fuzzy finder with all pending notifications, allowing quick
# navigation to any session/window with a waiting Claude instance.
#

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${TMPDIR:-/tmp}/claude-tmux-notify"
NOTIFICATIONS_FILE="$STATE_DIR/notifications"

# Get tmux option with default
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

# Format timestamp as relative time
relative_time() {
	local timestamp="$1"
	local now
	now=$(date +%s)
	local diff=$((now - timestamp))

	if [[ $diff -lt 60 ]]; then
		echo "${diff}s ago"
	elif [[ $diff -lt 3600 ]]; then
		echo "$((diff / 60))m ago"
	elif [[ $diff -lt 86400 ]]; then
		echo "$((diff / 3600))h ago"
	else
		echo "$((diff / 86400))d ago"
	fi
}

# Get icon based on notification type
get_type_icon() {
	local type="$1"
	case "$type" in
	permission) echo "" ;;
	error) echo "" ;;
	*) echo "" ;;
	esac
}

# Build formatted list for fzf
build_notification_list() {
	if [[ ! -f "$NOTIFICATIONS_FILE" ]]; then
		return
	fi

	while IFS='|' read -r timestamp session window pane type message; do
		# Skip empty lines
		[[ -z "$timestamp" ]] && continue

		# Check if session still exists
		if ! tmux has-session -t "$session" 2>/dev/null; then
			continue
		fi

		# Check if window still exists
		if ! tmux list-windows -t "$session" -F '#{window_index}' 2>/dev/null | grep -q "^${window}$"; then
			continue
		fi

		# Get window name
		local window_name
		window_name=$(tmux list-windows -t "$session" -F '#{window_index}:#{window_name}' 2>/dev/null | grep "^${window}:" | cut -d: -f2)

		# Format time
		local time_ago
		time_ago=$(relative_time "$timestamp")

		# Get icon
		local icon
		icon=$(get_type_icon "$type")

		# Truncate message if too long
		local short_message="${message:0:40}"
		[[ ${#message} -gt 40 ]] && short_message="${short_message}..."

		# Output format: display_string|session|window|pane
		# The part after the last | is hidden metadata for selection
		printf "%s %s:%s (%s)  %s  %s|%s|%s|%s\n" \
			"$icon" "$session" "$window_name" "$window" "$short_message" "$time_ago" \
			"$session" "$window" "$pane"

	done <"$NOTIFICATIONS_FILE"
}

# Preview function - shows more details about the notification
generate_preview_script() {
	cat <<'PREVIEW_EOF'
#!/usr/bin/env bash
# Extract metadata from selection (last 3 pipe-separated fields)
selection="$1"
session=$(echo "$selection" | awk -F'|' '{print $(NF-2)}')
window=$(echo "$selection" | awk -F'|' '{print $(NF-1)}')
pane=$(echo "$selection" | awk -F'|' '{print $NF}')

echo "Session: $session"
echo "Window:  $window"
echo "Pane:    $pane"
echo ""
echo "─────────────────────────────────"
echo ""

# Try to capture some of the pane content
tmux capture-pane -t "$session:$window.$pane" -p -S -20 2>/dev/null || echo "Unable to capture pane content"
PREVIEW_EOF
}

# Main
main() {
	local notifications
	notifications=$(build_notification_list)

	if [[ -z "$notifications" ]]; then
		tmux display-message "No Claude notifications"
		exit 0
	fi

	# Get picker size from config
	local picker_size
	picker_size=$(get_tmux_option @claude-tmux-notify-picker-size '60%,50%')

	# Get icon
	local icon
	icon=$(get_tmux_option @claude-tmux-notify-icon '🤖')

	# Create temporary preview script
	local preview_script="$STATE_DIR/preview.sh"
	generate_preview_script >"$preview_script"
	chmod +x "$preview_script"

	# Run fzf-tmux popup
	local selection
	selection=$(echo "$notifications" | fzf-tmux -p "$picker_size" \
		--ansi \
		--border-label " $icon Claude Notifications " \
		--prompt "$icon  " \
		--header '  Enter: jump to session  Ctrl-D: dismiss  Ctrl-A: dismiss all' \
		--bind 'ctrl-d:execute-silent(echo {-1} | cut -d"|" -f1-3 >> '"$STATE_DIR"'/to_clear)+reload(cat '"$NOTIFICATIONS_FILE"' 2>/dev/null | grep -v "^$" || true)' \
		--bind 'ctrl-a:execute-silent(: > '"$NOTIFICATIONS_FILE"')+abort' \
		--preview "$preview_script {}" \
		--preview-window 'right:50%:wrap' \
		--with-nth '1..-4' \
		--delimiter '\|' \
		2>/dev/null) || true

	# Clean up
	rm -f "$preview_script"

	# Handle selection
	if [[ -n "$selection" ]]; then
		# Extract session, window, pane from the hidden metadata (last 3 pipe-separated fields)
		local session window pane
		session=$(echo "$selection" | awk -F'|' '{print $(NF-2)}')
		window=$(echo "$selection" | awk -F'|' '{print $(NF-1)}')
		pane=$(echo "$selection" | awk -F'|' '{print $NF}')

		# Debug: show what we parsed
		# tmux display-message "Jumping to: $session:$window.$pane"

		# Jump to the session/window/pane
		tmux switch-client -t "$session" 2>/dev/null || true
		tmux select-window -t "$session:$window" 2>/dev/null || true
		tmux select-pane -t "$session:$window.$pane" 2>/dev/null || true

		# Clear the notification
		"$CURRENT_DIR/clear.sh" "$session" "$window" "$pane"
	fi
}

main
