#!/usr/bin/env bash
#
# prepend-status.sh - Prepend Claude notification widget to status-right
#
# This script captures the current status-right value and prepends the
# Claude notification widget to it. Run this AFTER your theme loads.
#

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATUS_SCRIPT="$CURRENT_DIR/status.sh"

# Get current status-right
current_status_right=$(tmux show-option -gv status-right)

# Prepend our widget
new_status_right="#($STATUS_SCRIPT)$current_status_right"

# Set the new status-right
tmux set-option -g status-right "$new_status_right"
