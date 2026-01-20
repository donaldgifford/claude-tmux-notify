#!/usr/bin/env bash
#
# tmux.sh - tmux status bar notification handler
#
# Arguments:
#   $1 - session name
#   $2 - window index
#   $3 - pane index
#   $4 - notification type
#   $5 - message
#
# Behavior:
# - Refreshes tmux status bar to show updated notification count
#

set -euo pipefail

# Refresh the tmux status bar
# This causes status.sh to be re-evaluated and show the updated count
tmux refresh-client -S 2>/dev/null || true
