#!/bin/bash
set -uo pipefail

label=io.github.gh-review-notify

launchctl bootout "gui/$(id -u)/$label" 2> /dev/null
rm -f "$HOME/Library/LaunchAgents/$label.plist"
rm -f "$HOME/.local/bin/gh-review-notify"
rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/gh-review-notify"
rm -f "$HOME/Library/Logs/gh-review-notify.log"

echo "Removed. terminal-notifier and jq are still installed: brew uninstall them if you want."
