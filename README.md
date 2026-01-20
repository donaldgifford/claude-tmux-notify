# claude-tmux-notify

[![CI](https://github.com/donaldgifford/claude-tmux-notify/actions/workflows/ci.yml/badge.svg)](https://github.com/donaldgifford/claude-tmux-notify/actions/workflows/ci.yml)
[![Release](https://github.com/donaldgifford/claude-tmux-notify/actions/workflows/release.yml/badge.svg)](https://github.com/donaldgifford/claude-tmux-notify/releases)

A tmux plugin that notifies you when Claude Code is waiting for input in any tmux session or window.

## Features

- **Status bar indicator** - Shows notification count when Claude needs attention
- **Cycle navigation** - Keybind to jump through sessions/windows with pending notifications
- **fzf picker** - Fuzzy finder popup to select and jump to any notification
- **Auto-clear** - Notifications clear automatically when you focus the pane
- **Multi-session support** - Track notifications across all tmux sessions

## Requirements

- tmux 3.0+
- [TPM](https://github.com/tmux-plugins/tpm) (recommended) or manual installation
- [fzf](https://github.com/junegunn/fzf) (optional, for picker feature)
- [Claude Code](https://claude.ai/claude-code) CLI

## Installation

### With TPM (recommended)

Add to your `~/.tmux.conf`:

```bash
set -g @plugin 'donaldgifford/claude-tmux-notify'
```

Then press `prefix + I` to install.

### With TPM (specific version)

Pin to a specific version:

```bash
set -g @plugin 'donaldgifford/claude-tmux-notify#v1.0.0'
```

### Manual Installation

```bash
git clone https://github.com/donaldgifford/claude-tmux-notify ~/.tmux/plugins/claude-tmux-notify
```

Add to your `~/.tmux.conf`:

```bash
run-shell ~/.tmux/plugins/claude-tmux-notify/claude-tmux-notify.tmux
```

Reload tmux:

```bash
tmux source ~/.tmux.conf
```

## Configuration

Add these to your `~/.tmux.conf` before the plugin is loaded:

```bash
# Keybinding to cycle through notifications (without prefix)
set -g @claude-tmux-notify-cycle-key 'C-c'

# Keybinding for fzf picker popup (without prefix)
set -g @claude-tmux-notify-picker-key 'C-y'

# fzf picker popup size (width,height)
set -g @claude-tmux-notify-picker-size '60%,50%'

# Status bar icon
set -g @claude-tmux-notify-icon '🤖'

# Auto-clear notification when pane receives focus
set -g @claude-tmux-notify-clear-on-focus 'on'
```

## Status Bar Integration

Add the status widget to your tmux status bar.

### For Tokyo Night theme

```bash
# Add before the TPM initialization line
set -g status-right '#{E:@tokyo-night-tmux_prepend_status_right}#(~/.tmux/plugins/claude-tmux-notify/scripts/status.sh)'
```

Or manually prepend to your existing status-right:

```bash
set -g status-right '#(~/.tmux/plugins/claude-tmux-notify/scripts/status.sh)#[default] ... your existing status'
```

### Generic setup

```bash
set -g status-right '#(~/.tmux/plugins/claude-tmux-notify/scripts/status.sh) | %H:%M'
```

## Claude Code Hook Setup

Configure Claude Code to trigger notifications. Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.tmux/plugins/claude-tmux-notify/scripts/notify.sh"
          }
        ]
      }
    ]
  }
}
```

See [claude-hook-config.md](claude-hook-config.md) for advanced configuration.

## Usage

### Status Bar

When Claude needs attention, the status bar shows:

```
🤖 3
```

This indicates 3 sessions/windows have pending Claude notifications.

### Cycling Through Notifications

Press `prefix + C-c` (or your configured key) to:
- Jump to the oldest notification
- Press again to cycle to the next
- Notifications auto-clear as you visit them

### fzf Picker

Press `prefix + C-y` (or your configured key) to open an interactive picker:
- Fuzzy search through all pending notifications
- Preview pane shows recent terminal output
- `Enter` to jump to selected notification
- `Ctrl-D` to dismiss a notification without jumping
- `Ctrl-A` to dismiss all notifications

### Manual Commands

```bash
# Send a test notification
~/.tmux/plugins/claude-tmux-notify/scripts/notify.sh --message "Test"

# Clear all notifications
~/.tmux/plugins/claude-tmux-notify/scripts/clear.sh all

# Check notification count
~/.tmux/plugins/claude-tmux-notify/scripts/status.sh
```

## Notification Methods

### tmux (default)

Updates the tmux status bar. No additional setup required.

### macOS (planned)

> Coming in a future release

Native macOS Notification Center integration.

### Webhook (planned)

> Coming in a future release

Webhook integration for Slack, Discord, or custom services.

## Troubleshooting

### Notifications not appearing

1. Verify scripts are executable:
   ```bash
   ls -la ~/.tmux/plugins/claude-tmux-notify/scripts/
   ```

2. Test notification manually:
   ```bash
   ~/.tmux/plugins/claude-tmux-notify/scripts/notify.sh --message "Test"
   ~/.tmux/plugins/claude-tmux-notify/scripts/status.sh
   ```

3. Check state file:
   ```bash
   cat ${TMPDIR:-/tmp}/claude-tmux-notify/notifications
   ```

### Status bar not showing widget

Make sure you've added the status widget call to your `status-right` or `status-left` configuration.

### Keybinding not working

Check for conflicts with existing keybindings:
```bash
tmux list-keys | grep C-c
```

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](.github/CONTRIBUTING.md) for guidelines.

This project uses [Conventional Commits](https://www.conventionalcommits.org/) for automated versioning.

## License

MIT License - see [LICENSE](LICENSE) for details.
