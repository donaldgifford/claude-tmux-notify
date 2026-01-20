# Contributing to tmux-claude-notify

Thank you for your interest in contributing!

## Commit Convention

This project uses [Conventional Commits](https://www.conventionalcommits.org/) for automated versioning and changelog generation.

### Commit Message Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types

| Type | Description | Version Bump |
|------|-------------|--------------|
| `feat` | New feature | Minor (0.X.0) |
| `fix` | Bug fix | Patch (0.0.X) |
| `docs` | Documentation only | No release |
| `style` | Code style (formatting, whitespace) | No release |
| `refactor` | Code change that neither fixes a bug nor adds a feature | No release |
| `perf` | Performance improvement | Patch (0.0.X) |
| `test` | Adding or updating tests | No release |
| `chore` | Maintenance tasks | No release |

### Breaking Changes

For breaking changes, add `!` after the type or include `BREAKING CHANGE:` in the footer:

```
feat!: remove support for tmux < 3.0

BREAKING CHANGE: Minimum tmux version is now 3.0
```

Breaking changes trigger a major version bump (X.0.0).

### Examples

```bash
# New feature
feat: add customizable status bar format

# Bug fix
fix: handle missing TMUX_PANE environment variable

# Documentation
docs: add troubleshooting section to README

# Chore (no release)
chore: update GitHub Actions versions
```

## Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/tmux-claude-notify.git
   cd tmux-claude-notify
   ```

2. Make scripts executable (if needed):
   ```bash
   chmod +x claude-notify.tmux scripts/*.sh scripts/handlers/*.sh
   ```

3. Test locally by adding to your `~/.tmux.conf`:
   ```bash
   run-shell /path/to/tmux-claude-notify/claude-notify.tmux
   ```

4. Reload tmux:
   ```bash
   tmux source ~/.tmux.conf
   ```

## Code Style

- Use `#!/usr/bin/env bash` shebang
- Follow [ShellCheck](https://www.shellcheck.net/) recommendations
- Use meaningful variable names
- Add comments for non-obvious logic

## Pull Request Process

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Make your changes with conventional commits
4. Ensure ShellCheck passes: `shellcheck scripts/*.sh`
5. Submit a pull request

## Testing

Test your changes manually:

```bash
# Send a test notification
./scripts/notify.sh --message "Test notification"

# Check status
./scripts/status.sh

# Test cycling
./scripts/cycle.sh

# Clear notifications
./scripts/clear.sh all
```

## Questions?

Open an issue if you have questions or need help.
